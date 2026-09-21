import {Store,makeId} from "./store.mjs";
import {parseGoalFallback,normalizeBlueprint} from "./goal-engine.mjs";
import {rankCandidates,optimizeTeams,replacementForRole,DEFAULT_MATCH_WEIGHTS,DEFAULT_TEAM_WEIGHTS} from "./match-engine.mjs";

const now=()=>new Date().toISOString();
const safeJson=async r=>{try{return await r.json()}catch{return null}};

export const AnalyticsService={track(name,props={}){Store.analytics(name,props)}};

export const AIService={
  async parseGoal(rawGoal){
    const controller=new AbortController();const timer=setTimeout(()=>controller.abort(),10000);
    try{
      const r=await fetch("/api/ai",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({action:"parse_goal",rawGoal}),signal:controller.signal});
      const d=await safeJson(r);if(r.ok&&d?.blueprint)return normalizeBlueprint({...d.blueprint,source:"ai"},rawGoal);
    }catch{}finally{clearTimeout(timer)}
    return normalizeBlueprint(parseGoalFallback(rawGoal),rawGoal);
  },
  async coordinate(project,swarm){
    const controller=new AbortController();const timer=setTimeout(()=>controller.abort(),9000);
    try{
      const r=await fetch("/api/ai",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({action:"coordinate",project,swarm}),signal:controller.signal});
      const d=await safeJson(r);if(r.ok&&d?.text)return {text:d.text,source:"live-llm"};
    }catch{}finally{clearTimeout(timer)}
    const open=(swarm?.tasks||[]).filter(t=>t.status!=="done"),late=open.filter(t=>t.dueDate&&new Date(t.dueDate)<new Date());
    const undone=(project?.milestones||[]).filter(m=>m.status!=="done");
    let text=late.length?late.length+" task"+(late.length===1?" is":"s are")+" past due. ":"No overdue tasks detected. ";
    text+=undone.length?undone.length+" milestone"+(undone.length===1?" remains":"s remain")+" open. ":"All milestones are marked complete. ";
    if(project?.budgetMax&&swarm?.projectedCost>project.budgetMax)text+="Projected team cost is over the current budget ceiling.";
    else if(project?.budgetMax)text+="Projected team cost is within the current budget ceiling.";
    return {text,source:"local-analysis"};
  }
};

export const ProfileService={
  get(){return Store.getProfile()},
  ensure(session){
    let p=Store.getProfile();if(p)return p;
    p={id:"user_"+makeId("profile").slice(-12),demo:false,name:session?.name||"SWARM User",bio:"",skills:[],experience:[],verifiedExperience:[],industries:[],interests:[],goals:[],desiredRoles:[],location:{city:"",state:"",country:"US"},remoteAllowed:true,travelRadius:25,availability:{start:new Date().toISOString().slice(0,10),end:"2027-12-31",hoursPerWeek:10},timezone:Intl.DateTimeFormat().resolvedOptions().timeZone||"UTC",hourlyRate:0,projectRate:0,minimumBudget:0,preferredProjectTypes:[],languages:["English"],workingStyle:["collaborative"],communicationPreferences:["Email"],portfolio:[],socialLinks:[],verificationStatus:{identity:false,email:false,phone:false,skills:false},reliabilityScore:null,completionRate:null,responseRate:null,averageResponseTime:null,projectsCompleted:0,peerRatings:null,previousCollaborators:[],blockedUsers:[],teamHistory:[],visibility:"private",createdAt:now(),updatedAt:now()};
    Store.setProfile(p);return p;
  },
  save(profile){profile.updatedAt=now();Store.setProfile(profile);Store.activity("profile_updated",{profileId:profile.id});return profile}
};

export const GoalService={
  async create(rawGoal,creatorId){
    AnalyticsService.track("goal_created",{rawGoalLength:String(rawGoal||"").length});
    const blueprint=await AIService.parseGoal(rawGoal);
    blueprint.creatorId=creatorId;blueprint.status="blueprint";Store.upsertProject(blueprint);
    Store.activity("blueprint_generated",{projectId:blueprint.id,source:blueprint.source});
    return blueprint;
  }
};

export const BlueprintService={
  update(project,patch){
    const next=normalizeBlueprint({...project,...patch,id:project.id,creatorId:project.creatorId,createdAt:project.createdAt},project.rawGoal);
    next.status=project.status||"blueprint";Store.upsertProject(next);Store.activity("blueprint_modified",{projectId:next.id});return next;
  },
  addRole(project,role,required=true){
    const key=required?"requiredRoles":"optionalRoles";const list=[...(project[key]||[])];
    list.push({id:makeId("role"),title:role.title||"Specialist",required,skills:(role.skills||[]).map(s=>typeof s==="string"?{name:s,required:true,weight:1}:s),budgetCap:role.budgetCap||null,estimatedHours:role.estimatedHours||24,requiredLanguages:role.requiredLanguages||["English"],certifications:[],notes:""});
    return this.update(project,{[key]:list});
  }
};

export const ProjectService={
  list(){return Store.getProjects()},
  get(id){return Store.getProjects().find(x=>x.id===id)||null},
  save(project){return Store.upsertProject({...project,updatedAt:now()})},
  setMilestone(projectId,milestoneId,status){
    const p=this.get(projectId);if(!p)return null;p.milestones=(p.milestones||[]).map(m=>m.id===milestoneId?{...m,status}:m);this.save(p);Store.activity(status==="done"?"milestone_completed":"milestone_updated",{projectId,milestoneId});return p
  }
};

export const MatchingService={
  weights:{...DEFAULT_MATCH_WEIGHTS},
  candidates(project,profiles){
    const out={};for(const role of project.requiredRoles||[])out[role.id]=rankCandidates(project,role,profiles,this.weights);return out;
  },
  start(project){AnalyticsService.track("matching_started",{projectId:project.id})},
  complete(project,roles){AnalyticsService.track("matching_completed",{projectId:project.id,roles:Object.keys(roles).length})}
};

export const TeamOptimizer={
  weights:{...DEFAULT_TEAM_WEIGHTS},
  options(project,profiles){const out=optimizeTeams(project,profiles,{matchWeights:MatchingService.weights,teamWeights:this.weights});AnalyticsService.track("team_viewed",{projectId:project.id,count:out.length});return out}
};

export const NotificationService={
  list(){return Store.getNotifications()},
  add(title,body,kind="system"){Store.pushNotification({title,body,kind})}
};

export const InvitationService={
  create(project,team){
    const existing=Store.getInvitations().filter(i=>i.projectId!==project.id);
    const invitations=team.assignments.map(a=>({id:makeId("invite"),projectId:project.id,roleId:a.roleId,roleTitle:a.roleTitle,profileId:a.profileId,profileName:a.profileName,status:"pending",demoSimulation:true,matchPercent:a.match.percent,whyMatched:a.match.reasons,estimatedCompensation:a.incrementalCost,createdAt:now(),updatedAt:now()}));
    Store.setInvitations([...invitations,...existing]);invitations.forEach(i=>Store.activity("invitation_sent",{projectId:project.id,invitationId:i.id,profileId:i.profileId,roleId:i.roleId,demo:true}));
    NotificationService.add("Swarm invitations prepared",invitations.length+" development-network invitations are ready for simulation.","invite");
    return invitations;
  },
  list(projectId){return Store.getInvitations().filter(i=>i.projectId===projectId)},
  respond(id,status,project,profiles,team){
    let list=Store.getInvitations();const invite=list.find(i=>i.id===id);if(!invite)return {invitations:list,replacement:null};
    invite.status=status;invite.updatedAt=now();Store.setInvitations(list);Store.activity(status==="accepted"?"invitation_accepted":"invitation_declined",{projectId:invite.projectId,invitationId:id,profileId:invite.profileId,demo:true});
    let replacement=null;
    if(status==="declined"){
      const current=(team?.assignments||[]).filter(a=>a.profileId!==invite.profileId||a.roleId!==invite.roleId);
      const next=replacementForRole(project,invite.roleId,current,profiles);
      if(next){
        replacement={id:makeId("invite"),projectId:project.id,roleId:invite.roleId,roleTitle:(project.requiredRoles||[]).find(r=>r.id===invite.roleId)?.title||invite.roleTitle,profileId:next.profile.id,profileName:next.profile.name,status:"pending",demoSimulation:true,matchPercent:next.match.percent,whyMatched:next.match.reasons,estimatedCompensation:next.match.estimatedCost,createdAt:now(),updatedAt:now(),replacementFor:id};
        Store.setInvitations([replacement,...Store.getInvitations()]);Store.activity("replacement_requested",{projectId:project.id,roleId:invite.roleId,replacementProfileId:replacement.profileId,demo:true});
      }
    }
    return {invitations:Store.getInvitations(),replacement};
  }
};

export const SwarmService={
  create(project,team){
    AnalyticsService.track("team_selected",{projectId:project.id,label:team.label});
    const swarm={id:makeId("swarm"),projectId:project.id,title:project.title,status:"forming",teamLabel:team.label,teamScore:team.metrics.percent,projectedCost:team.metrics.totalBudget,assignments:team.assignments,members:[],tasks:[],messages:[],decisions:[],createdAt:now(),updatedAt:now(),demoSimulation:true};
    Store.upsertSwarm(swarm);InvitationService.create(project,team);project.status="forming";Store.upsertProject(project);return swarm
  },
  getForProject(projectId){return Store.getSwarms().find(s=>s.projectId===projectId)||null},
  syncMembers(swarm){
    const accepted=InvitationService.list(swarm.projectId).filter(i=>i.status==="accepted");
    swarm.members=accepted.map(i=>({profileId:i.profileId,name:i.profileName,roleId:i.roleId,roleTitle:i.roleTitle,joinedAt:i.updatedAt,demo:true}));
    const required=(swarm.assignments||[]).length;swarm.status=accepted.length>=required&&required>0?"active":"forming";swarm.updatedAt=now();Store.upsertSwarm(swarm);
    if(swarm.status==="active"){Store.activity("swarm_formed",{projectId:swarm.projectId,swarmId:swarm.id,demo:true});NotificationService.add("Your Swarm is ready",swarm.title+" has enough accepted development-network members.","swarm")}
    return swarm
  },
  addTask(swarm,title,ownerProfileId=null,dueDate=null){swarm.tasks=[...(swarm.tasks||[]),{id:makeId("task"),title,status:"todo",ownerProfileId,dueDate,createdAt:now()}];Store.upsertSwarm(swarm);Store.activity("task_created",{swarmId:swarm.id});return swarm},
  setTask(swarm,taskId,status){swarm.tasks=(swarm.tasks||[]).map(t=>t.id===taskId?{...t,status}:t);Store.upsertSwarm(swarm);return swarm},
  addMessage(swarm,text,sender="YOU"){swarm.messages=[...(swarm.messages||[]),{id:makeId("msg"),sender,text,createdAt:now()}];Store.upsertSwarm(swarm);return swarm},
  addDecision(swarm,text){swarm.decisions=[...(swarm.decisions||[]),{id:makeId("decision"),text,createdAt:now()}];Store.upsertSwarm(swarm);return swarm}
};

export const TrustService={
  signals(profile){return [
    {label:"Identity verified",value:!!profile.verificationStatus?.identity,kind:"boolean"},
    {label:"Email verified",value:!!profile.verificationStatus?.email,kind:"boolean"},
    {label:"Skill evidence",value:!!profile.verificationStatus?.skills,kind:"boolean"},
    {label:"Projects completed",value:profile.projectsCompleted??0,kind:"number"},
    {label:"Completion",value:profile.completionRate==null?null:Math.round(profile.completionRate*100)+"%",kind:"metric"},
    {label:"Response",value:profile.responseRate==null?null:Math.round(profile.responseRate*100)+"%",kind:"metric"}
  ]}
};

export const OutcomeService={
  complete(project,swarm,outcome){const result=Store.addOutcome({projectId:project.id,swarmId:swarm?.id||null,...outcome});project.status="completed";Store.upsertProject(project);if(swarm){swarm.status="completed";Store.upsertSwarm(swarm)}Store.activity("project_completed",{projectId:project.id,swarmId:swarm?.id||null});return result}
};
