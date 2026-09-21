
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const CORS={
  "Access-Control-Allow-Origin":"*",
  "Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods":"POST, OPTIONS",
  "Content-Type":"application/json"
};
const json=(body,status=200)=>new Response(JSON.stringify(body),{status,headers:CORS});
const clamp=(n:number)=>Math.max(0,Math.min(1,Number(n)||0));
const lower=(s:any)=>String(s||"").trim().toLowerCase();
const avg=(a:number[])=>a.length?a.reduce((x,y)=>x+y,0)/a.length:0;
const dateValue=(v:any)=>v?new Date(v).getTime():null;
const uuid=()=>crypto.randomUUID();

const MATCH_WEIGHTS={skillFit:.30,experienceFit:.15,availabilityFit:.15,reliability:.15,goalAlignment:.10,locationFit:.05,budgetFit:.05,workingStyleFit:.05};
const TEAM_WEIGHTS={roleCoverage:.30,pairwiseCompatibility:.20,scheduleCompatibility:.15,reliability:.10,budgetCompatibility:.10,skillComplementarity:.10,priorTeamSuccess:.05};

function toProfile(row:any){
  const c=row.capabilities||{};
  return {
    ...c,
    id:row.id,
    name:row.name,
    bio:row.bio,
    location:{city:row.location_city||c.location?.city||"",state:row.location_region||c.location?.state||"",country:row.location_country||c.location?.country||"US"},
    remoteAllowed:row.remote_allowed ?? c.remoteAllowed ?? true,
    travelRadius:row.travel_radius ?? c.travelRadius ?? 0,
    timezone:row.timezone||c.timezone||"UTC",
    hourlyRate:Number(row.hourly_rate ?? c.hourlyRate ?? 0),
    projectRate:Number(row.project_rate ?? c.projectRate ?? 0),
    minimumBudget:Number(row.minimum_budget ?? c.minimumBudget ?? 0),
    preferredProjectTypes:row.preferred_project_types||c.preferredProjectTypes||[],
    languages:row.languages||c.languages||[],
    workingStyle:row.working_style||c.workingStyle||[],
    communicationPreferences:row.communication_preferences||c.communicationPreferences||[],
    portfolio:row.portfolio||c.portfolio||[],
    socialLinks:row.social_links||c.socialLinks||[],
    verificationStatus:row.verification_status||c.verificationStatus||{},
    reliabilityScore:row.reliability_score ?? c.reliabilityScore ?? .65,
    completionRate:row.completion_rate ?? c.completionRate ?? .65,
    responseRate:row.response_rate ?? c.responseRate ?? .65,
    averageResponseTime:row.average_response_time ?? c.averageResponseTime ?? null,
    projectsCompleted:row.projects_completed ?? c.projectsCompleted ?? 0,
    peerRatings:row.peer_ratings ?? c.peerRatings ?? null,
    skills:c.skills||[],
    experience:c.experience||[],
    verifiedExperience:c.verifiedExperience||[],
    industries:c.industries||[],
    interests:c.interests||[],
    goals:c.goals||[],
    desiredRoles:c.desiredRoles||[],
    previousCollaborators:c.previousCollaborators||[],
    blockedUsers:c.blockedUsers||[],
    teamHistory:c.teamHistory||[],
    visibility:row.visibility
  };
}
function skillMap(p:any){
  // Capability proficiency is user supplied. Verification is intentionally ignored here
  // until it is backed by a server-controlled evidence workflow.
  return new Map((p.skills||[]).map((s:any)=>Array.isArray(s)?[lower(s[0]),{level:clamp(s[1]),verified:false}]:[lower(s.name),{level:clamp(s.level||s.proficiency||0),verified:false}]));
}
function skillFit(p:any,r:any){
  const req=(r.skills||[]).filter((s:any)=>s.required!==false); if(!req.length)return .75;
  const sm=skillMap(p);let w=0,t=0;
  for(const s of req){const ww=Number(s.weight||1),hit=sm.get(lower(s.name)) as any;w+=(hit?hit.level*(hit.verified?1:.92):0)*ww;t+=ww}
  return t?clamp(w/t):0;
}
function availabilityFit(p:any,project:any){
  const ps=dateValue(p.availability?.start),pe=dateValue(p.availability?.end),rs=dateValue(project.startDate),re=dateValue(project.deadline);
  if(!ps||!pe||!rs||!re)return .75;if(pe<rs||ps>re)return 0;
  return clamp((Math.min(pe,re)-Math.max(ps,rs))/Math.max(1,re-rs));
}
function locFit(p:any,project:any){
  if(project.remoteAllowed&&p.remoteAllowed)return 1;
  const target=lower(project.location);if(!target||target==="remote")return p.remoteAllowed?1:.6;
  const city=lower(p.location?.city),state=lower(p.location?.state);
  if(city&&target.includes(city))return 1;if(state&&target.includes(state))return .72;
  return project.remoteAllowed&&p.remoteAllowed?.85:0;
}
function estimateCost(p:any,r:any){
  if(Number(p.projectRate||0)>0)return Number(p.projectRate);
  return Math.round(Number(p.hourlyRate||0)*Number(r.estimatedHours||24));
}
function budgetFit(p:any,r:any){
  const cap=Number(r.budgetCap||0);if(!cap)return .8;const cost=estimateCost(p,r);if(cost<=cap)return 1;
  return clamp(1-(cost-cap)/Math.max(cap,1));
}
function expFit(p:any,project:any,r:any){
  const years=Math.max(0,...(p.experience||[]).map((x:any)=>Number(x.years||0)));
  const role=lower(r.title),roleHit=(p.desiredRoles||[]).some((x:any)=>{const y=lower(x);return y===role||(role.length>10&&(y.includes(role)||role.includes(y)))})?1:.5;
  const cat=lower(project.category),ind=(p.industries||[]).some((x:any)=>cat.includes(lower(x))||lower(x).includes(cat.split("/")[0].trim()))?1:.65;
  return clamp(Math.min(years/6,1)*.5+roleHit*.3+ind*.2);
}
function relFit(p:any){return clamp(avg([Number(p.reliabilityScore??.65),Number(p.completionRate??.65),Number(p.responseRate??.65)]))}
function goalFit(p:any,project:any){
  const text=lower([project.category,project.objective,project.rawGoal].join(" "));
  const terms=[...(p.interests||[]),...(p.goals||[]),...(p.preferredProjectTypes||[])].map(lower);
  return clamp(.45+Math.min(.55,terms.filter((t:string)=>t&&text.includes(t)).length*.16));
}
function styleFit(p:any,project:any){
  const want=(project.preferredWorkingStyle||[]).map(lower);if(!want.length)return .75;
  const have=(p.workingStyle||[]).map(lower);return clamp(have.filter((x:string)=>want.includes(x)).length/want.length);
}
function hardReasons(p:any,r:any,project:any,teamIds:string[]=[]){
  const out:string[]=[];
  if((p.blockedUsers||[]).some((id:string)=>teamIds.includes(id)))out.push("blocked relationship");
  const langs=(p.languages||[]).map(lower);for(const l of r.requiredLanguages||[]){if(!langs.includes(lower(l)))out.push("required language unavailable")}
  if(availabilityFit(p,project)===0)out.push("unavailable during required dates");
  if(locFit(p,project)===0)out.push("location incompatible");
  const desired=(p.desiredRoles||[]).map(lower),title=lower(r.title),sf=skillFit(p,r);
  const direct=desired.some((x:string)=>x===title||(title.length>10&&(x.includes(title)||title.includes(x))));
  if(!direct&&sf<.62)out.push("role mismatch");
  if((r.certifications||[]).length){
    const verified=(p.verifiedExperience||[]).map(lower);
    for(const cert of r.certifications){if(!verified.some((v:string)=>v.includes(lower(cert))))out.push("missing mandatory certification")}
  }
  if(r.budgetCap&&p.minimumBudget&&Number(p.minimumBudget)>Number(r.budgetCap))out.push("budget incompatible");
  return [...new Set(out)];
}
function scoreCandidate(p:any,r:any,project:any,teamIds:string[]=[]){
  const hard=hardReasons(p,r,project,teamIds);
  const breakdown={skillFit:skillFit(p,r),experienceFit:expFit(p,project,r),availabilityFit:availabilityFit(p,project),reliability:relFit(p),goalAlignment:goalFit(p,project),locationFit:locFit(p,project),budgetFit:budgetFit(p,r),workingStyleFit:styleFit(p,project)};
  const score=hard.length?0:Object.entries(MATCH_WEIGHTS).reduce((s,[k,w])=>s+(breakdown as any)[k]*(w as number),0);
  const reasons:string[]=[];
  if(breakdown.skillFit>=.8)reasons.push("Strong required-skill coverage");
  if(breakdown.availabilityFit>=.85)reasons.push("Available across the project window");
  if(Number(p.projectsCompleted||0)>=8)reasons.push("Completed "+p.projectsCompleted+" prior projects");
  if(breakdown.budgetFit>=.9)reasons.push("Fits the role budget");
  if(Number(p.completionRate||0)>=.9)reasons.push(Math.round(Number(p.completionRate)*100)+"% project completion rate");
  const concerns:string[]=[];
  if(breakdown.locationFit<.8)concerns.push("Location requires remote/travel coordination");
  if(breakdown.budgetFit<.7)concerns.push("Rate is above the target role budget");
  if(breakdown.availabilityFit<.75)concerns.push("Partial schedule overlap");
  return {profileId:p.id,profileName:p.name,roleId:r.id,roleTitle:r.title,eligible:!hard.length,hardConstraints:hard,score:clamp(score),percent:Math.round(clamp(score)*100),breakdown,estimatedCost:estimateCost(p,r),reasons,concerns};
}
function rank(project:any,r:any,profiles:any[],teamIds:string[]=[]){
  return profiles.map(p=>({profile:p,match:scoreCandidate(p,r,project,teamIds)})).filter(x=>x.match.eligible).sort((a,b)=>b.match.score-a.match.score||String(a.profile.id).localeCompare(String(b.profile.id)));
}
function pair(a:any,b:any){
  if((a.blockedUsers||[]).includes(b.id)||(b.blockedUsers||[]).includes(a.id))return 0;
  const sa=(a.workingStyle||[]).map(lower),sb=(b.workingStyle||[]).map(lower),ca=(a.communicationPreferences||[]).map(lower),cb=(b.communicationPreferences||[]).map(lower);
  const style=sa.length&&sb.length?sa.filter((x:string)=>sb.includes(x)).length/Math.min(sa.length,sb.length):.6;
  const comm=ca.length&&cb.length?ca.filter((x:string)=>cb.includes(x)).length/Math.min(ca.length,cb.length):.6;
  const prior=(a.previousCollaborators||[]).includes(b.id)||(b.previousCollaborators||[]).includes(a.id)?1:.55;
  return clamp(style*.45+comm*.25+prior*.3);
}
function teamMetrics(project:any,assign:any[],profiles:any[]){
  const by=new Map(profiles.map(p=>[p.id,p])),roles=project.requiredRoles||[],covered=new Set(assign.map(a=>a.roleId));
  const members=[...new Set(assign.map(a=>a.profileId))].map(id=>by.get(id)).filter(Boolean);
  const pairs:number[]=[];for(let i=0;i<members.length;i++)for(let j=i+1;j<members.length;j++)pairs.push(pair(members[i],members[j]));
  const totalBudget=assign.reduce((s,a)=>s+Number((a.incrementalCost??a.estimatedCost)||0),0),max=Number(project.budgetMax||0);
  const budgetCompatibility=!max?1:totalBudget<=max?1:clamp(1-(totalBudget-max)/max);
  const allSkills=new Set(assign.flatMap(a=>(by.get(a.profileId)?.skills||[]).map((x:any)=>lower(Array.isArray(x)?x[0]:x.name))));
  const needed=new Set(roles.flatMap((r:any)=>(r.skills||[]).map((s:any)=>lower(s.name))));
  const skillComplementarity=needed.size?clamp([...needed].filter(s=>allSkills.has(s)).length/needed.size):1;
  const priorPairs=members.flatMap((a:any,i:number)=>members.slice(i+1).map((b:any)=>(a.previousCollaborators||[]).includes(b.id)||(b.previousCollaborators||[]).includes(a.id)?1:0));
  const vals={roleCoverage:roles.length?covered.size/roles.length:1,pairwiseCompatibility:pairs.length?avg(pairs):1,scheduleCompatibility:avg(assign.map(a=>a.breakdown.availabilityFit)),reliability:avg(assign.map(a=>a.breakdown.reliability)),budgetCompatibility,skillComplementarity,priorTeamSuccess:priorPairs.length?avg(priorPairs):.5};
  let score=Object.entries(TEAM_WEIGHTS).reduce((s,[k,w])=>s+(vals as any)[k]*(w as number),0);
  if(project.teamSizeMin&&members.length<project.teamSizeMin)score*=.88;if(project.teamSizeMax&&members.length>project.teamSizeMax)score*=.9;
  return {...vals,score:clamp(score),percent:Math.round(clamp(score)*100),totalBudget:Math.round(totalBudget),memberCount:members.length};
}
function optimize(project:any,profiles:any[],top=5,beamSize=80){
  const roles=project.requiredRoles||[];if(!roles.length)return [];
  const ranks=new Map(roles.map((r:any)=>[r.id,rank(project,r,profiles).slice(0,top)]));
  const ordered=[...roles].sort((a:any,b:any)=>(ranks.get(a.id)?.length||0)-(ranks.get(b.id)?.length||0)||a.title.localeCompare(b.title));
  let beam:any[]=[{assignments:[],counts:new Map(),cost:0}];
  for(const role of ordered){
    const next:any[]=[];
    for(const state of beam)for(const item of ranks.get(role.id)||[]){
      const count=state.counts.get(item.profile.id)||0;if(count>=2)continue;
      const teamIds=[...state.counts.keys()].filter(x=>x!==item.profile.id);
      const blockedPair=teamIds.some(id=>{
        const mate=profiles.find(p=>p.id===id);
        return (item.profile.blockedUsers||[]).includes(id)||(mate?.blockedUsers||[]).includes(item.profile.id);
      });
      if(blockedPair)continue;
      const rem=scoreCandidate(item.profile,role,project,teamIds);if(!rem.eligible)continue;
      const inc=Math.round(rem.estimatedCost*(count?.6:1));
      if(project.budgetMax&&state.cost+inc>Number(project.budgetMax)*1.35)continue;
      const counts=new Map(state.counts);counts.set(item.profile.id,count+1);
      next.push({assignments:[...state.assignments,{...rem,incrementalCost:inc}],counts,cost:state.cost+inc});
    }
    if(!next.length)return [];
    next.sort((a,b)=>avg(b.assignments.map((x:any)=>x.score))-avg(a.assignments.map((x:any)=>x.score))||a.cost-b.cost);
    beam=next.slice(0,beamSize);
  }
  const scored=beam.map(x=>({...x,metrics:teamMetrics(project,x.assignments,profiles)})).sort((a,b)=>b.metrics.score-a.metrics.score||a.metrics.totalBudget-b.metrics.totalBudget);
  const out:any[]=[],seen=new Set<string>(),key=(x:any)=>[...new Set(x.assignments.map((a:any)=>a.profileId))].sort().join("|");
  const add=(x:any,label:string)=>{if(!x||seen.has(key(x)))return;seen.add(key(x));out.push({...x,label})};
  const optimal=scored[0];add(optimal,"OPTIMAL SWARM");
  add(scored.find(x=>key(x)!==key(optimal)&&x.metrics.pairwiseCompatibility>=.62&&x.metrics.score>=optimal.metrics.score-.12),"BALANCED SWARM");
  add([...scored].filter(x=>key(x)!==key(optimal)&&x.metrics.totalBudget<optimal.metrics.totalBudget*.98&&(!project.budgetMax||x.metrics.totalBudget<=project.budgetMax)).sort((a,b)=>a.metrics.totalBudget-b.metrics.totalBudget)[0],"BUDGET-FRIENDLY SWARM");
  return out;
}
async function userFromReq(req:Request,userClient:any){
  const auth=req.headers.get("Authorization");if(!auth)return null;
  const token=auth.replace(/^Bearer\s+/i,"");
  const {data,error}=await userClient.auth.getUser(token);if(error)return null;return data.user;
}
function blueprintFrom(row:any){return {...(row.blueprint||{}),id:row.id,creatorId:row.creator_id,status:row.status,title:row.title,objective:row.objective,category:row.category,location:row.location_text,remoteAllowed:row.remote_allowed,budgetMin:row.budget_min,budgetMax:row.budget_max,startDate:row.start_date,deadline:row.deadline,teamSizeMin:row.team_size_min,teamSizeMax:row.team_size_max}}

Deno.serve(async(req)=>{
  if(req.method==="OPTIONS")return new Response("ok",{headers:CORS});
  if(req.method!=="POST")return json({error:"POST required"},405);
  const url=Deno.env.get("SUPABASE_URL")||"",anon=Deno.env.get("SUPABASE_ANON_KEY")||"",service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")||"";
  const auth=req.headers.get("Authorization")||"";
  const userClient=createClient(url,anon,{global:{headers:{Authorization:auth}},auth:{persistSession:false}});
  const admin=createClient(url,service,{auth:{persistSession:false}});
  const user=await userFromReq(req,userClient);if(!user)return json({error:"Unauthorized"},401);
  let body:any;try{body=await req.json()}catch{return json({error:"Invalid JSON"},400)}
  const action=String(body?.action||"match_team");

  if(action==="match_team"){
    const projectId=String(body?.projectId||"");
    const {data:row,error}=await admin.from("projects").select("*").eq("id",projectId).single();
    if(error||!row)return json({error:"Project not found"},404);
    if(row.creator_id!==user.id)return json({error:"Only the project creator can run matching"},403);
    if(["forming","active","completed","abandoned"].includes(row.status))return json({error:"Full rematching is locked after Swarm formation. Use replacement matching or create a new project."},409);
    let project=blueprintFrom(row);

    await admin.from("matches").delete().eq("project_id",projectId);
    await admin.from("team_candidates").delete().eq("project_id",projectId);
    await admin.from("project_roles").delete().eq("project_id",projectId);

    const rewritten:any[]=[];
    for(const role of project.requiredRoles||[]){
      const {data:created,error:re}=await admin.from("project_roles").insert({project_id:projectId,title:role.title,required:true,budget_cap:role.budgetCap||null,estimated_hours:role.estimatedHours||24,required_languages:role.requiredLanguages||["English"],certifications:role.certifications||[],notes:role.notes||""}).select("*").single();
      if(re)return json({error:"Could not materialize role",detail:re.message},500);
      rewritten.push({...role,id:created.id});
    }
    project={...project,requiredRoles:rewritten};
    await admin.from("projects").update({blueprint:{...(row.blueprint||{}),requiredRoles:rewritten},status:"matching"}).eq("id",projectId);

    const {data:rows,error:pe}=await admin.from("profiles").select("*").eq("visibility","public").neq("id",user.id);
    if(pe)return json({error:"Profile lookup failed",detail:pe.message},500);
    const profiles=(rows||[]).map(toProfile);
    const candidates:any={};
    for(const role of rewritten)candidates[role.id]=rank(project,role,profiles).slice(0,8).map(x=>({profile:x.profile,match:x.match}));
    const teams=optimize(project,profiles);

    for(const role of rewritten){
      const list=candidates[role.id]||[];
      if(!list.length)continue;
      const payload=list.map((x:any)=>({project_id:projectId,role_id:role.id,profile_id:x.profile.id,eligible:true,score:x.match.score,estimated_cost:x.match.estimatedCost,hard_constraints:x.match.hardConstraints,reasons:x.match.reasons,concerns:x.match.concerns,scoring_version:"v1"}));
      const {data:saved}=await admin.from("matches").insert(payload).select("id,profile_id");
      for(const sm of saved||[]){
        const source=list.find((x:any)=>x.profile.id===sm.profile_id)?.match;
        if(source){
          await admin.from("match_score_components").insert(Object.entries(source.breakdown).map(([component,value])=>({match_id:sm.id,component,normalized_value:value,weight:(MATCH_WEIGHTS as any)[component],contribution:Number(value)*(MATCH_WEIGHTS as any)[component]})));
        }
      }
    }
    const stored:any[]=[];
    for(const team of teams){
      const {data:t}=await admin.from("team_candidates").insert({project_id:projectId,label:team.label,score:team.metrics.score,projected_cost:team.metrics.totalBudget,member_count:team.metrics.memberCount,metrics:team.metrics,assignments:team.assignments,optimizer_version:"v1"}).select("*").single();
      if(t)stored.push({...team,id:t.id});
    }
    await admin.from("activity_events").insert({actor_id:user.id,project_id:projectId,event_name:"matching_completed",properties:{roles:rewritten.length,candidates:profiles.length,teams:stored.length}});
    return json({ok:true,project,candidates,teams:stored,networkSize:profiles.length});
  }

  if(action==="form_swarm"){
    const candidateId=String(body?.teamCandidateId||"");
    const {data:candidate,error:ce}=await admin.from("team_candidates").select("*,projects(*)").eq("id",candidateId).single();
    if(ce||!candidate)return json({error:"Team candidate not found"},404);
    const project=candidate.projects;if(project.creator_id!==user.id)return json({error:"Only the project creator can form this Swarm"},403);
    const {data:existing}=await admin.from("swarms").select("*").eq("project_id",project.id).maybeSingle();
    if(existing&&["forming","active"].includes(existing.status))return json({ok:true,swarm:existing,alreadyExists:true});
    const state={teamLabel:candidate.label,teamScore:Math.round(Number(candidate.score)*100),assignments:candidate.assignments,members:[],tasks:[],messages:[],decisions:[]};
    const {data:swarm,error:se}=await admin.from("swarms").upsert({id:existing?.id||uuid(),project_id:project.id,team_candidate_id:candidate.id,status:"forming",projected_cost:candidate.projected_cost,state,updated_at:new Date().toISOString()},{onConflict:"project_id"}).select("*").single();
    if(se)return json({error:"Could not create Swarm",detail:se.message},500);
    await admin.from("swarm_members").delete().eq("swarm_id",swarm.id);
    await admin.from("invitations").delete().eq("swarm_id",swarm.id).eq("status","pending");
    const assignments=candidate.assignments||[];
    const members=assignments.map((a:any)=>({swarm_id:swarm.id,profile_id:a.profileId,role_id:a.roleId,member_status:"invited"}));
    if(members.length){const {error:me}=await admin.from("swarm_members").insert(members);if(me)return json({error:"Could not create member slots",detail:me.message},500)}
    const invites=assignments.map((a:any)=>({swarm_id:swarm.id,project_id:project.id,profile_id:a.profileId,role_id:a.roleId,status:"pending",estimated_compensation:a.incrementalCost||a.estimatedCost||null,match_score:Number(a.score||0),why_matched:a.reasons||[]}));
    const {data:createdInvites,error:ie}=await admin.from("invitations").insert(invites).select("*");
    if(ie)return json({error:"Could not send invitations",detail:ie.message},500);
    await admin.from("projects").update({status:"forming"}).eq("id",project.id);
    await admin.from("activity_events").insert({actor_id:user.id,project_id:project.id,swarm_id:swarm.id,event_name:"team_selected",properties:{teamCandidateId:candidate.id,label:candidate.label}});
    return json({ok:true,swarm, invitations:createdInvites});
  }

  if(action==="respond_invitation"){
    const invitationId=String(body?.invitationId||""),status=String(body?.status||"");
    if(!["accepted","declined"].includes(status))return json({error:"Invalid response"},400);
    const {data:inv,error:ie}=await admin.from("invitations").select("*").eq("id",invitationId).single();
    if(ie||!inv)return json({error:"Invitation not found"},404);
    if(inv.profile_id!==user.id)return json({error:"This invitation belongs to another user"},403);
    if(inv.status!=="pending")return json({error:"Invitation already answered"},409);
    await admin.from("invitations").update({status,responded_at:new Date().toISOString()}).eq("id",inv.id);
    await admin.from("swarm_members").update({member_status:status}).eq("swarm_id",inv.swarm_id).eq("profile_id",user.id).eq("role_id",inv.role_id);
    const {data:projectRow}=await admin.from("projects").select("*").eq("id",inv.project_id).single();
    let replacement:any=null;

    if(status==="declined"&&projectRow){
      const project=blueprintFrom(projectRow);
      const {data:roleRow}=await admin.from("project_roles").select("*").eq("id",inv.role_id).single();
      const role=(project.requiredRoles||[]).find((r:any)=>r.id===inv.role_id)||{id:inv.role_id,title:roleRow?.title||"Specialist",skills:[],budgetCap:roleRow?.budget_cap,estimatedHours:roleRow?.estimated_hours||24,requiredLanguages:roleRow?.required_languages||["English"]};
      const {data:members}=await admin.from("swarm_members").select("profile_id").eq("swarm_id",inv.swarm_id).in("member_status",["invited","accepted","active"]);
      const used=new Set((members||[]).map((m:any)=>m.profile_id));
      const {data:declined}=await admin.from("invitations").select("profile_id").eq("project_id",inv.project_id).eq("role_id",inv.role_id).eq("status","declined");
      for(const d of declined||[])used.add(d.profile_id);
      const {data:rows}=await admin.from("profiles").select("*").eq("visibility","public");
      const pool=(rows||[]).map(toProfile).filter((p:any)=>!used.has(p.id)&&p.id!==projectRow.creator_id);
      const next=rank(project,role,pool,[...used])[0];
      if(next){
        const {data:newInv}=await admin.from("invitations").insert({swarm_id:inv.swarm_id,project_id:inv.project_id,profile_id:next.profile.id,role_id:inv.role_id,status:"pending",estimated_compensation:next.match.estimatedCost,match_score:Number(next.match.score||0),why_matched:next.match.reasons,replacement_for:inv.id}).select("*").single();
        await admin.from("swarm_members").insert({swarm_id:inv.swarm_id,profile_id:next.profile.id,role_id:inv.role_id,member_status:"invited"});
        const {data:sw}=await admin.from("swarms").select("*").eq("id",inv.swarm_id).single();
        const state=sw?.state||{},assignments=(state.assignments||[]).filter((a:any)=>!(a.roleId===inv.role_id&&a.profileId===inv.profile_id));
        assignments.push({...next.match,profileId:next.profile.id,profileName:next.profile.name,roleId:inv.role_id,roleTitle:role.title,incrementalCost:next.match.estimatedCost});
        await admin.from("swarms").update({state:{...state,assignments},updated_at:new Date().toISOString()}).eq("id",inv.swarm_id);
        replacement={invitation:newInv,profile:next.profile,match:next.match};
        await admin.from("activity_events").insert({actor_id:user.id,project_id:inv.project_id,swarm_id:inv.swarm_id,event_name:"replacement_requested",properties:{declinedInvitation:inv.id,replacementProfileId:next.profile.id,roleId:inv.role_id}});
      }else{
        await admin.from("notifications").insert({profile_id:projectRow.creator_id,kind:"replacement_needed",title:"SWARM needs a replacement",body:"No eligible replacement is currently available for "+(role.title||"this role")+". Adjust constraints or invite someone manually."});
      }
    }

    const {data:reqRoles}=await admin.from("project_roles").select("id").eq("project_id",inv.project_id).eq("required",true);
    const {data:accepted}=await admin.from("swarm_members").select("role_id").eq("swarm_id",inv.swarm_id).in("member_status",["accepted","active"]);
    const acceptedRoles=new Set((accepted||[]).map((x:any)=>x.role_id));
    const ready=(reqRoles||[]).length>0&&(reqRoles||[]).every((r:any)=>acceptedRoles.has(r.id));
    if(ready){
      await admin.from("swarms").update({status:"active",updated_at:new Date().toISOString()}).eq("id",inv.swarm_id);
      await admin.from("projects").update({status:"active"}).eq("id",inv.project_id);
      await admin.from("activity_events").insert({actor_id:user.id,project_id:inv.project_id,swarm_id:inv.swarm_id,event_name:"swarm_formed",properties:{}});
    }
    return json({ok:true,status,replacement,swarmReady:ready});
  }

  return json({error:"Unsupported action"},400);
});
