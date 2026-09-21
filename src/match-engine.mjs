export const DEFAULT_MATCH_WEIGHTS={skillFit:.30,experienceFit:.15,availabilityFit:.15,reliability:.15,goalAlignment:.10,locationFit:.05,budgetFit:.05,workingStyleFit:.05};
export const DEFAULT_TEAM_WEIGHTS={roleCoverage:.30,pairwiseCompatibility:.20,scheduleCompatibility:.15,reliability:.10,budgetCompatibility:.10,skillComplementarity:.10,priorTeamSuccess:.05};

const clamp=n=>Math.max(0,Math.min(1,Number(n)||0));
const lower=s=>String(s||"").trim().toLowerCase();
const average=a=>a.length?a.reduce((x,y)=>x+y,0)/a.length:0;
const dateValue=v=>v?new Date(v).getTime():null;
const profileSkillMap=p=>new Map((p.skills||[]).map(s=>Array.isArray(s)?[lower(s[0]),{level:clamp(s[1]),verified:!!s[2]}]:[lower(s.name),{level:clamp(s.level||s.proficiency||0),verified:!!s.verified}]));

export function estimateRoleCost(profile,role){
  const projectRate=Number(profile.projectRate||0);
  if(projectRate>0)return projectRate;
  return Math.round(Number(profile.hourlyRate||0)*Number(role.estimatedHours||24));
}
function availabilityOverlap(profile,project){
  const ps=dateValue(profile.availability?.start),pe=dateValue(profile.availability?.end);
  const rs=dateValue(project.startDate),re=dateValue(project.deadline);
  if(!ps||!pe||!rs||!re)return .75;
  if(pe<rs||ps>re)return 0;
  const start=Math.max(ps,rs),end=Math.min(pe,re);const need=Math.max(1,re-rs);return clamp((end-start)/need);
}
function locationFit(profile,project){
  if(project.remoteAllowed&&profile.remoteAllowed)return 1;
  const target=lower(project.location);if(!target||target==="remote")return profile.remoteAllowed?1:.6;
  const city=lower(profile.location?.city),state=lower(profile.location?.state);
  if(target.includes(city)&&city)return 1;
  if(state&&target.includes(state))return .72;
  return project.remoteAllowed&&profile.remoteAllowed?.85:0;
}
function budgetFit(profile,role){
  const cap=Number(role.budgetCap||0);if(!cap)return .8;
  const cost=estimateRoleCost(profile,role);if(cost<=cap)return 1;
  return clamp(1-(cost-cap)/Math.max(cap,1));
}
function skillFit(profile,role){
  const req=(role.skills||[]).filter(s=>s.required!==false);if(!req.length)return .75;
  const sm=profileSkillMap(profile);
  let weighted=0,total=0;
  for(const s of req){const w=Number(s.weight||1);const hit=sm.get(lower(s.name));weighted+=(hit?hit.level*(hit.verified?1:.92):0)*w;total+=w}
  return total?clamp(weighted/total):0;
}
function experienceFit(profile,project,role){
  const years=Math.max(0,...(profile.experience||[]).map(x=>Number(x.years||0)));
  const roleHit=(profile.desiredRoles||[]).some(r=>lower(r).includes(lower(role.title))||lower(role.title).includes(lower(r)))?1:.5;
  const cat=lower(project.category);const industryHit=(profile.industries||[]).some(x=>cat.includes(lower(x))||lower(x).includes(cat.split("/")[0].trim()))?1:.65;
  return clamp((Math.min(years/6,1)*.5)+(roleHit*.3)+(industryHit*.2));
}
function reliabilityFit(profile){return clamp(average([profile.reliabilityScore??.7,profile.completionRate??.7,profile.responseRate??.7]))}
function goalAlignment(profile,project){
  const text=lower([project.category,project.objective,project.rawGoal].join(" "));
  const terms=[...(profile.interests||[]),...(profile.goals||[]),...(profile.preferredProjectTypes||[])].map(lower);
  const hits=terms.filter(t=>t&&text.includes(t)).length;return clamp(.45+Math.min(.55,hits*.16));
}
function workingStyleFit(profile,project){
  const wanted=(project.preferredWorkingStyle||[]).map(lower);if(!wanted.length)return .75;
  const have=(profile.workingStyle||[]).map(lower);return clamp(have.filter(x=>wanted.includes(x)).length/wanted.length);
}
export function hardConstraintReasons(profile,role,project,teamIds=[]){
  const reasons=[];
  if((profile.blockedUsers||[]).some(id=>teamIds.includes(id)))reasons.push("blocked relationship");
  if(teamIds.some(id=>(profile.blockedUsers||[]).includes(id)))reasons.push("blocked relationship");
  const languages=(profile.languages||[]).map(lower);for(const l of role.requiredLanguages||[]){if(!languages.includes(lower(l)))reasons.push("required language unavailable")}
  if(availabilityOverlap(profile,project)===0)reasons.push("unavailable during required dates");
  if(locationFit(profile,project)===0)reasons.push("location incompatible");
  const desired=(profile.desiredRoles||[]).map(lower),title=lower(role.title),skillScore=skillFit(profile,role);
  const directRole=desired.some(r=>r===title||(title.length>10&&(r.includes(title)||title.includes(r))));
  const roleMatch=directRole||skillScore>=.62;
  if(!roleMatch)reasons.push("role mismatch");
  if((role.certifications||[]).length){const verified=(profile.verifiedExperience||[]).map(lower);for(const c of role.certifications){if(!verified.some(v=>v.includes(lower(c))))reasons.push("missing mandatory certification")}}
  if(role.budgetCap&&profile.minimumBudget&&Number(profile.minimumBudget)>Number(role.budgetCap))reasons.push("budget incompatible");
  return [...new Set(reasons)];
}
export function scoreRoleCandidate(profile,role,project,weights=DEFAULT_MATCH_WEIGHTS,teamIds=[]){
  const hard=hardConstraintReasons(profile,role,project,teamIds);
  const breakdown={
    skillFit:skillFit(profile,role),experienceFit:experienceFit(profile,project,role),availabilityFit:availabilityOverlap(profile,project),
    reliability:reliabilityFit(profile),goalAlignment:goalAlignment(profile,project),locationFit:locationFit(profile,project),
    budgetFit:budgetFit(profile,role),workingStyleFit:workingStyleFit(profile,project)
  };
  const weightTotal=Object.values(weights).reduce((a,b)=>a+Number(b||0),0)||1;
  const score=hard.length?0:Object.entries(weights).reduce((sum,[k,w])=>sum+(breakdown[k]||0)*Number(w||0),0)/weightTotal;
  const sm=profileSkillMap(profile);
  const coverage=(role.skills||[]).filter(s=>sm.has(lower(s.name))).length/Math.max(1,(role.skills||[]).length);
  const reasons=[];
  if(breakdown.skillFit>=.8)reasons.push(Math.round(coverage*100)+"% required skill coverage");
  if(breakdown.availabilityFit>=.85)reasons.push("Available across the project window");
  if((profile.projectsCompleted||0)>=8)reasons.push("Completed "+profile.projectsCompleted+" prior projects");
  if(breakdown.budgetFit>=.9)reasons.push("Fits the role budget");
  if((profile.completionRate||0)>=.9)reasons.push(Math.round(profile.completionRate*100)+"% project completion rate");
  const concerns=[];
  if(breakdown.locationFit<.8)concerns.push("Location requires remote/travel coordination");
  if(breakdown.budgetFit<.7)concerns.push("Rate is above the target role budget");
  if(breakdown.availabilityFit<.75)concerns.push("Partial schedule overlap");
  return {profileId:profile.id,roleId:role.id,eligible:hard.length===0,hardConstraints:hard,score:clamp(score),percent:Math.round(clamp(score)*100),breakdown,estimatedCost:estimateRoleCost(profile,role),reasons,concerns};
}
export function rankCandidates(project,role,profiles,weights=DEFAULT_MATCH_WEIGHTS,teamIds=[]){
  return profiles.map(p=>({profile:p,match:scoreRoleCandidate(p,role,project,weights,teamIds)})).filter(x=>x.match.eligible).sort((a,b)=>b.match.score-a.match.score||String(a.profile.id).localeCompare(String(b.profile.id)));
}
export function pairwiseCompatibility(a,b){
  if(!a||!b)return 0;if((a.blockedUsers||[]).includes(b.id)||(b.blockedUsers||[]).includes(a.id))return 0;
  const stylesA=(a.workingStyle||[]).map(lower),stylesB=(b.workingStyle||[]).map(lower);
  const commA=(a.communicationPreferences||[]).map(lower),commB=(b.communicationPreferences||[]).map(lower);
  const style=stylesA.length&&stylesB.length?stylesA.filter(x=>stylesB.includes(x)).length/Math.min(stylesA.length,stylesB.length):.6;
  const comm=commA.length&&commB.length?commA.filter(x=>commB.includes(x)).length/Math.min(commA.length,commB.length):.6;
  const prior=(a.previousCollaborators||[]).includes(b.id)||(b.previousCollaborators||[]).includes(a.id)?1:.55;
  return clamp(style*.45+comm*.25+prior*.3);
}
function teamMetrics(project,assignments,profilesById,teamWeights){
  const roles=[...(project.requiredRoles||[])];const covered=new Set(assignments.map(a=>a.roleId));const members=[...new Set(assignments.map(a=>a.profileId))].map(id=>profilesById.get(id)).filter(Boolean);
  const pair=[];for(let i=0;i<members.length;i++)for(let j=i+1;j<members.length;j++)pair.push(pairwiseCompatibility(members[i],members[j]));
  const assignmentMatches=assignments.map(a=>a.match);
  const totalBudget=assignments.reduce((sum,a)=>sum+Number((a.incrementalCost??a.match.estimatedCost)||0),0);
  const max=Number(project.budgetMax||0);
  const budgetCompatibility=!max?1:totalBudget<=max?1:clamp(1-(totalBudget-max)/max);
  const allSkills=new Set(assignments.flatMap(a=>(profilesById.get(a.profileId)?.skills||[]).map(s=>lower(Array.isArray(s)?s[0]:s.name))));
  const needed=new Set(roles.flatMap(r=>(r.skills||[]).map(s=>lower(s.name))));
  const skillComplementarity=needed.size?clamp([...needed].filter(s=>allSkills.has(s)).length/needed.size):1;
  const priorPairs=pair.length?members.flatMap((a,i)=>members.slice(i+1).map(b=>(a.previousCollaborators||[]).includes(b.id)||(b.previousCollaborators||[]).includes(a.id)?1:0)):[];
  const values={
    roleCoverage:roles.length?covered.size/roles.length:1,
    pairwiseCompatibility:pair.length?average(pair):1,
    scheduleCompatibility:assignmentMatches.length?average(assignmentMatches.map(m=>m.breakdown.availabilityFit)):0,
    reliability:assignmentMatches.length?average(assignmentMatches.map(m=>m.breakdown.reliability)):0,
    budgetCompatibility,skillComplementarity,
    priorTeamSuccess:priorPairs.length?average(priorPairs):.5
  };
  const wt=Object.values(teamWeights).reduce((a,b)=>a+Number(b||0),0)||1;
  let score=Object.entries(teamWeights).reduce((sum,[k,w])=>sum+values[k]*Number(w||0),0)/wt;
  const memberCount=members.length;
  if(project.teamSizeMin&&memberCount<project.teamSizeMin)score*=.88;
  if(project.teamSizeMax&&memberCount>project.teamSizeMax)score*=.9;
  return {score:clamp(score),percent:Math.round(clamp(score)*100),totalBudget:Math.round(totalBudget),memberCount,roleCoverage:values.roleCoverage,pairwiseCompatibility:values.pairwiseCompatibility,scheduleCompatibility:values.scheduleCompatibility,reliability:values.reliability,budgetCompatibility,skillComplementarity,priorTeamSuccess:values.priorTeamSuccess};
}
export function scoreTeam(project,assignments,profiles,teamWeights=DEFAULT_TEAM_WEIGHTS){
  return teamMetrics(project,assignments,new Map(profiles.map(p=>[p.id,p])),teamWeights);
}
export function optimizeTeams(project,profiles,{matchWeights=DEFAULT_MATCH_WEIGHTS,teamWeights=DEFAULT_TEAM_WEIGHTS,topPerRole=5,beamSize=80}={}){
  const roles=[...(project.requiredRoles||[])];if(!roles.length)return [];
  const profilesById=new Map(profiles.map(p=>[p.id,p]));
  const roleRanks=new Map(roles.map(r=>[r.id,rankCandidates(project,r,profiles,matchWeights).slice(0,topPerRole)]));
  const ordered=[...roles].sort((a,b)=>(roleRanks.get(a.id)?.length||0)-(roleRanks.get(b.id)?.length||0)||a.title.localeCompare(b.title));
  let beam=[{assignments:[],memberRoleCounts:new Map(),cost:0}];
  for(const role of ordered){
    const candidates=roleRanks.get(role.id)||[];const next=[];
    for(const state of beam){
      for(const item of candidates){
        const count=state.memberRoleCounts.get(item.profile.id)||0;if(count>=2)continue;
        const teamIds=[...state.memberRoleCounts.keys()];
        const rematch=scoreRoleCandidate(item.profile,role,project,matchWeights,teamIds.filter(id=>id!==item.profile.id));if(!rematch.eligible)continue;
        const incremental=Math.round(rematch.estimatedCost*(count?0.6:1));
        if(project.budgetMax&&state.cost+incremental>Number(project.budgetMax)*1.35)continue;
        const counts=new Map(state.memberRoleCounts);counts.set(item.profile.id,count+1);
        next.push({assignments:[...state.assignments,{roleId:role.id,roleTitle:role.title,profileId:item.profile.id,profileName:item.profile.name,match:rematch,incrementalCost:incremental}],memberRoleCounts:counts,cost:state.cost+incremental});
      }
    }
    if(!next.length)break;
    next.sort((a,b)=>{
      const ma=average(a.assignments.map(x=>x.match.score)),mb=average(b.assignments.map(x=>x.match.score));
      const budgetA=project.budgetMax?Math.max(0,1-a.cost/project.budgetMax):.5,budgetB=project.budgetMax?Math.max(0,1-b.cost/project.budgetMax):.5;
      return (mb+budgetB*.08)-(ma+budgetA*.08);
    });
    beam=next.slice(0,beamSize);
  }
  const scored=beam.filter(x=>x.assignments.length===roles.length).map(x=>({...x,metrics:teamMetrics(project,x.assignments,profilesById,teamWeights)}));
  scored.sort((a,b)=>b.metrics.score-a.metrics.score||a.metrics.totalBudget-b.metrics.totalBudget);
  if(!scored.length)return [];
  const unique=[];const seen=new Set();
  const memberKey=x=>[...new Set(x.assignments.map(a=>a.profileId))].sort().join("|");
  const add=(x,label)=>{if(!x)return;const key=memberKey(x);if(seen.has(key))return;seen.add(key);unique.push({...x,label})};
  const optimal=scored[0];add(optimal,"OPTIMAL SWARM");
  const optimalKey=memberKey(optimal);
  const balanced=scored.find(x=>memberKey(x)!==optimalKey&&x.metrics.memberCount>=Math.min(project.teamSizeMax||99,roles.length-1)&&x.metrics.pairwiseCompatibility>=.62&&x.metrics.score>=optimal.metrics.score-.12);
  add(balanced,"BALANCED SWARM");
  const affordable=[...scored].filter(x=>memberKey(x)!==optimalKey&&x.metrics.totalBudget<optimal.metrics.totalBudget*.98&&(!project.budgetMax||x.metrics.totalBudget<=project.budgetMax)).sort((a,b)=>a.metrics.totalBudget-b.metrics.totalBudget||b.metrics.score-a.metrics.score)[0];
  add(affordable,"BUDGET-FRIENDLY SWARM");
  return unique;
}
export function replacementForRole(project,roleId,currentAssignments,profiles,weights=DEFAULT_MATCH_WEIGHTS){
  const role=(project.requiredRoles||[]).find(r=>r.id===roleId);if(!role)return null;
  const used=new Set(currentAssignments.map(a=>a.profileId));const teamIds=[...used];
  return rankCandidates(project,role,profiles.filter(p=>!used.has(p.id)),weights,teamIds)[0]||null;
}
