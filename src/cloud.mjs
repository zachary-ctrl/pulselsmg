import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.57.4/+esm";

export const SUPABASE_URL="https://ziqqpnstclqfnxsbxddf.supabase.co";
export const SUPABASE_PUBLISHABLE_KEY="sb_publishable_d8KLEShgXO9SCRebjePTgw_7xta6bzj";

export const supabase=createClient(SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY,{
  auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true,flowType:"pkce"},
  realtime:{params:{eventsPerSecond:10}}
});

const uuid=()=>crypto.randomUUID();
const cleanName=s=>String(s||"file").replace(/[^a-zA-Z0-9._-]+/g,"-").replace(/-+/g,"-").slice(0,120)||"file";
const isUuid=v=>/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(String(v||""));

function profileFromRow(row){
  const c=row?.capabilities||{};
  return {
    ...c,id:row.id,demo:false,cloud:true,name:row.name||c.name||"SWARM User",bio:row.bio||c.bio||"",
    location:{city:row.location_city||c.location?.city||"",state:row.location_region||c.location?.state||"",country:row.location_country||c.location?.country||"US"},
    remoteAllowed:row.remote_allowed ?? c.remoteAllowed ?? true,travelRadius:row.travel_radius ?? c.travelRadius ?? 0,
    timezone:row.timezone||c.timezone||"UTC",hourlyRate:Number(row.hourly_rate ?? c.hourlyRate ?? 0),
    projectRate:Number(row.project_rate ?? c.projectRate ?? 0),minimumBudget:Number(row.minimum_budget ?? c.minimumBudget ?? 0),
    preferredProjectTypes:row.preferred_project_types||c.preferredProjectTypes||[],languages:row.languages||c.languages||[],
    workingStyle:row.working_style||c.workingStyle||[],communicationPreferences:row.communication_preferences||c.communicationPreferences||[],
    portfolio:row.portfolio||c.portfolio||[],socialLinks:row.social_links||c.socialLinks||[],
    verificationStatus:row.verification_status||c.verificationStatus||{},reliabilityScore:row.reliability_score ?? c.reliabilityScore ?? null,
    completionRate:row.completion_rate ?? c.completionRate ?? null,responseRate:row.response_rate ?? c.responseRate ?? null,
    averageResponseTime:row.average_response_time ?? c.averageResponseTime ?? null,projectsCompleted:row.projects_completed ?? c.projectsCompleted ?? 0,
    peerRatings:row.peer_ratings ?? c.peerRatings ?? null,visibility:row.visibility||c.visibility||"private",
    rateVisibility:row.rate_visibility||c.rateVisibility||"private",availabilityVisibility:row.availability_visibility||c.availabilityVisibility||"project",
    createdAt:row.created_at||c.createdAt,updatedAt:row.updated_at||c.updatedAt
  };
}
function profileToRow(p,userId){
  const capabilities={
    skills:p.skills||[],experience:p.experience||[],verifiedExperience:p.verifiedExperience||[],industries:p.industries||[],
    interests:p.interests||[],goals:p.goals||[],desiredRoles:p.desiredRoles||[],availability:p.availability||null,
    previousCollaborators:p.previousCollaborators||[],blockedUsers:p.blockedUsers||[],teamHistory:p.teamHistory||[]
  };
  return {
    id:userId,name:p.name||"SWARM User",bio:p.bio||"",location_city:p.location?.city||null,location_region:p.location?.state||null,
    location_country:p.location?.country||"US",remote_allowed:p.remoteAllowed!==false,travel_radius:Number(p.travelRadius||0),
    timezone:p.timezone||Intl.DateTimeFormat().resolvedOptions().timeZone||"UTC",hourly_rate:Number(p.hourlyRate||0)||null,
    project_rate:Number(p.projectRate||0)||null,minimum_budget:Number(p.minimumBudget||0)||null,
    preferred_project_types:p.preferredProjectTypes||[],languages:p.languages||[],working_style:p.workingStyle||[],
    communication_preferences:p.communicationPreferences||[],portfolio:p.portfolio||[],social_links:p.socialLinks||[],
    visibility:p.visibility||"private",rate_visibility:p.rateVisibility||"private",availability_visibility:p.availabilityVisibility||"project",
    capabilities,updated_at:new Date().toISOString()
  };
}
function projectFromRow(row){
  const b=row?.blueprint||{};
  return {
    ...b,id:row.id,creatorId:row.creator_id,rawGoal:row.raw_goal,title:row.title,objective:row.objective,category:row.category,
    location:row.location_text,remoteAllowed:row.remote_allowed,budgetMin:row.budget_min,budgetMax:row.budget_max,
    startDate:row.start_date,deadline:row.deadline,preferredExperience:row.preferred_experience||b.preferredExperience||[],
    preferredWorkingStyle:row.preferred_working_style||b.preferredWorkingStyle||[],constraints:row.constraints||b.constraints||[],
    teamSizeMin:row.team_size_min,teamSizeMax:row.team_size_max,status:row.status,visibility:row.visibility,
    createdAt:row.created_at,updatedAt:row.updated_at,cloud:true
  };
}
function projectToRow(p,userId){
  if(!isUuid(p.id))p.id=uuid();
  p.creatorId=userId;
  return {
    id:p.id,creator_id:userId,raw_goal:p.rawGoal||p.objective||p.title||"",title:p.title||"Untitled Project",objective:p.objective||p.title||"",
    category:p.category||null,location_text:p.location||null,remote_allowed:p.remoteAllowed!==false,budget_min:p.budgetMin??null,
    budget_max:p.budgetMax??null,start_date:p.startDate||null,deadline:p.deadline||null,preferred_experience:p.preferredExperience||[],
    preferred_working_style:p.preferredWorkingStyle||[],constraints:p.constraints||[],team_size_min:p.teamSizeMin??null,
    team_size_max:p.teamSizeMax??null,visibility:p.visibility||"private",status:p.status||"blueprint",blueprint:p,updated_at:new Date().toISOString()
  };
}
function swarmFromRow(row){
  const s=row?.state||{};
  return {...s,id:row.id,projectId:row.project_id,status:row.status,projectedCost:row.projected_cost,createdAt:row.created_at,updatedAt:row.updated_at,cloud:true,demoSimulation:false};
}
async function requireUser(){
  const {data:{user},error}=await supabase.auth.getUser();
  if(error||!user)throw new Error("Sign in required");
  return user;
}

export const Cloud={
  async session(){const {data:{session}}=await supabase.auth.getSession();return session},
  async ensureAnonymousSession(){
    const current=await this.session();if(current)return current;
    const {data,error}=await supabase.auth.signInAnonymously({options:{data:{name:"SWARM User"}}});
    if(error)return null;
    return data?.session||null;
  },
  onAuth(callback){return supabase.auth.onAuthStateChange(callback)},
  async signUp(name,email,password){
    const {data,error}=await supabase.auth.signUp({email,password,options:{data:{name}}});
    if(error)throw error;return data;
  },
  async signIn(email,password){const {data,error}=await supabase.auth.signInWithPassword({email,password});if(error)throw error;return data},
  async signOut(){const {error}=await supabase.auth.signOut();if(error)throw error},
  async currentUser(){return await requireUser()},
  async loadProfile(){
    const user=await requireUser();
    let {data,error}=await supabase.from("profiles").select("*").eq("id",user.id).maybeSingle();
    if(error)throw error;
    if(!data){
      const fallback={id:user.id,name:user.user_metadata?.name||String(user.email||"").split("@")[0]||"SWARM User",bio:"",location:{city:"",state:"",country:"US"},remoteAllowed:true,travelRadius:25,timezone:Intl.DateTimeFormat().resolvedOptions().timeZone||"UTC",hourlyRate:0,projectRate:0,minimumBudget:0,preferredProjectTypes:[],languages:["English"],workingStyle:["collaborative"],communicationPreferences:["Email"],portfolio:[],socialLinks:[],verificationStatus:{identity:false,email:!!user.email_confirmed_at,phone:false,skills:false},skills:[],experience:[],verifiedExperience:[],industries:[],interests:[],goals:[],desiredRoles:[],availability:{start:new Date().toISOString().slice(0,10),end:"2027-12-31",hoursPerWeek:10},previousCollaborators:[],blockedUsers:[],teamHistory:[],visibility:"private"};
      return await this.saveProfile(fallback);
    }
    return profileFromRow(data);
  },
  async saveProfile(profile){
    const user=await requireUser();const row=profileToRow(profile,user.id);
    const {data,error}=await supabase.from("profiles").upsert(row,{onConflict:"id"}).select("*").single();
    if(error)throw error;return profileFromRow(data);
  },
  async loadPublicProfiles(){
    const {data,error}=await supabase.from("profiles").select("*").eq("visibility","public").order("updated_at",{ascending:false}).limit(500);
    if(error)throw error;return (data||[]).map(profileFromRow);
  },
  async loadProjects(){
    const {data,error}=await supabase.from("projects").select("*").order("updated_at",{ascending:false});
    if(error)throw error;return (data||[]).map(projectFromRow);
  },
  async saveProject(project){
    const user=await requireUser();const row=projectToRow(project,user.id);
    const {data,error}=await supabase.from("projects").upsert(row,{onConflict:"id"}).select("*").single();
    if(error)throw error;return projectFromRow(data);
  },
  async importLegacyProjects(projects=[]){
    const existing=await this.loadProjects();if(existing.length||!projects.length)return existing;
    const imported=[];
    for(const old of projects){
      try{
        const clone=structuredClone(old);clone.id=uuid();clone.creatorId=null;
        clone.status=["active","forming","completed","abandoned"].includes(clone.status)?"blueprint":clone.status||"blueprint";
        imported.push(await this.saveProject(clone));
      }catch{}
    }
    return imported;
  },
  async loadSwarms(){
    const {data,error}=await supabase.from("swarms").select("*").order("updated_at",{ascending:false});
    if(error)throw error;return (data||[]).map(swarmFromRow);
  },
  async loadInvitations(projectId=null){
    let q=supabase.from("invitations")
      .select("*,project:projects(id,title,objective,status),role:project_roles(id,title),profile:profiles!invitations_profile_id_fkey(id,name),swarm:swarms(id,status)")
      .order("created_at",{ascending:false});
    if(projectId)q=q.eq("project_id",projectId);
    const {data,error}=await q;if(error)throw error;
    return (data||[]).map(i=>({
      id:i.id,projectId:i.project_id,project:i.project,roleId:i.role_id,roleTitle:i.role?.title||"Role",profileId:i.profile_id,
      profileName:i.profile?.name||"SWARM Member",swarmId:i.swarm_id,status:i.status,estimatedCompensation:i.estimated_compensation,
      whyMatched:i.why_matched||[],replacementFor:i.replacement_for,matchPercent:i.match_score==null?null:Math.round(Number(i.match_score)*100),
      createdAt:i.created_at,respondedAt:i.responded_at,cloud:true
    }));
  },
  async loadNotifications(){
    const {data,error}=await supabase.from("notifications").select("*").order("created_at",{ascending:false}).limit(100);
    if(error)throw error;return data||[];
  },
  async markNotificationRead(id){const {error}=await supabase.from("notifications").update({read_at:new Date().toISOString()}).eq("id",id);if(error)throw error},
  async loadMatchState(projectId){
    const [matchesRes,teamsRes]=await Promise.all([
      supabase.from("matches").select("*,profile:profiles!matches_profile_id_fkey(*)").eq("project_id",projectId).eq("eligible",true).order("score",{ascending:false}),
      supabase.from("team_candidates").select("*").eq("project_id",projectId).order("score",{ascending:false})
    ]);
    if(matchesRes.error)throw matchesRes.error;if(teamsRes.error)throw teamsRes.error;
    const ids=(matchesRes.data||[]).map(m=>m.id);
    let components=[];
    if(ids.length){
      const r=await supabase.from("match_score_components").select("*").in("match_id",ids);
      if(r.error)throw r.error;components=r.data||[];
    }
    const byMatch=new Map();
    for(const c of components){
      if(!byMatch.has(c.match_id))byMatch.set(c.match_id,{});
      byMatch.get(c.match_id)[c.component]=Number(c.normalized_value);
    }
    const candidates={};
    for(const m of matchesRes.data||[]){
      if(!candidates[m.role_id])candidates[m.role_id]=[];
      candidates[m.role_id].push({
        profile:profileFromRow(m.profile),
        match:{profileId:m.profile_id,roleId:m.role_id,eligible:m.eligible,score:Number(m.score),percent:Math.round(Number(m.score)*100),breakdown:byMatch.get(m.id)||{},estimatedCost:Number(m.estimated_cost||0),hardConstraints:m.hard_constraints||[],reasons:m.reasons||[],concerns:m.concerns||[]}
      });
    }
    const teams=(teamsRes.data||[]).map(t=>({id:t.id,label:t.label,score:Number(t.score),metrics:t.metrics||{},assignments:t.assignments||[],projected_cost:Number(t.projected_cost||0)}));
    return {candidates,teams};
  },
  async runMatching(projectId){
    const {data,error}=await supabase.functions.invoke("swarm-match",{body:{action:"match_team",projectId}});
    if(error)throw error;if(data?.error)throw new Error(data.error);return data;
  },
  async formSwarm(teamCandidateId){
    const {data,error}=await supabase.functions.invoke("swarm-match",{body:{action:"form_swarm",teamCandidateId}});
    if(error)throw error;if(data?.error)throw new Error(data.error);return data;
  },
  async respondInvitation(invitationId,status){
    const {data,error}=await supabase.functions.invoke("swarm-match",{body:{action:"respond_invitation",invitationId,status}});
    if(error)throw error;if(data?.error)throw new Error(data.error);return data;
  },
  async loadInvitationMessages(invitationId){
    const {data,error}=await supabase.from("invitation_messages").select("*,sender:profiles!invitation_messages_sender_id_fkey(id,name)").eq("invitation_id",invitationId).order("created_at");
    if(error)throw error;return data||[];
  },
  async addInvitationMessage(invitationId,body){
    const user=await requireUser();
    const {data,error}=await supabase.from("invitation_messages").insert({invitation_id:invitationId,sender_id:user.id,body:String(body||"").trim()}).select("*").single();
    if(error)throw error;return data;
  },
  async loadRoom(swarmId,projectId){
    const [tasks,messages,decisions,files,members]=await Promise.all([
      supabase.from("tasks").select("*").eq("swarm_id",swarmId).order("created_at"),
      supabase.from("messages").select("*,sender:profiles!messages_sender_id_fkey(id,name)").eq("swarm_id",swarmId).order("created_at"),
      supabase.from("swarm_decisions").select("*,author:profiles!swarm_decisions_author_id_fkey(id,name)").eq("swarm_id",swarmId).order("created_at"),
      supabase.from("project_files").select("*").eq("project_id",projectId).order("created_at",{ascending:false}),
      supabase.from("swarm_members").select("*,profile:profiles!swarm_members_profile_id_fkey(id,name)").eq("swarm_id",swarmId)
    ]);
    for(const r of [tasks,messages,decisions,files,members])if(r.error)throw r.error;
    return {tasks:tasks.data||[],messages:messages.data||[],decisions:decisions.data||[],files:files.data||[],members:members.data||[]};
  },
  async addTask(swarmId,title,dueDate=null,ownerProfileId=null){
    const user=await requireUser();
    const {data,error}=await supabase.from("tasks").insert({swarm_id:swarmId,title,status:"todo",owner_profile_id:ownerProfileId,due_at:dueDate||null,created_by:user.id}).select("*").single();
    if(error)throw error;return data;
  },
  async updateTask(id,status){const {data,error}=await supabase.from("tasks").update({status}).eq("id",id).select("*").single();if(error)throw error;return data},
  async addMessage(swarmId,body){const user=await requireUser();const {data,error}=await supabase.from("messages").insert({swarm_id:swarmId,sender_id:user.id,body}).select("*").single();if(error)throw error;return data},
  async addDecision(swarmId,body){const user=await requireUser();const {data,error}=await supabase.from("swarm_decisions").insert({swarm_id:swarmId,author_id:user.id,body}).select("*").single();if(error)throw error;return data},
  async uploadProjectFile(projectId,swarmId,file){
    const user=await requireUser();const path=`${user.id}/${projectId}/${uuid()}-${cleanName(file.name)}`;
    const {error:uploadError}=await supabase.storage.from("swarm-files").upload(path,file,{cacheControl:"3600",upsert:false});
    if(uploadError)throw uploadError;
    const {data,error}=await supabase.from("project_files").insert({project_id:projectId,swarm_id:swarmId||null,uploaded_by:user.id,storage_path:path,display_name:file.name,mime_type:file.type||null,size_bytes:file.size}).select("*").single();
    if(error){await supabase.storage.from("swarm-files").remove([path]);throw error}return data;
  },
  async signedFileUrl(path,seconds=900){const {data,error}=await supabase.storage.from("swarm-files").createSignedUrl(path,seconds);if(error)throw error;return data.signedUrl},
  async saveOutcome(project,swarm,outcome){
    const user=await requireUser();
    const payload={project_id:project.id,swarm_id:swarm?.id||null,finished:outcome.finished,on_time:outcome.onTime,on_budget:outcome.onBudget,creator_satisfied:outcome.creatorSatisfied,milestones_completed:(project.milestones||[]).filter(m=>m.status==="done").length,produced:outcome.produced||"",metadata:{recordedBy:user.id}};
    const {data,error}=await supabase.from("outcomes").upsert(payload,{onConflict:"project_id"}).select("*").single();if(error)throw error;
    await supabase.from("projects").update({status:outcome.finished===false?"abandoned":"completed"}).eq("id",project.id);
    if(swarm)await supabase.from("swarms").update({status:outcome.finished===false?"cancelled":"completed"}).eq("id",swarm.id);
    return data;
  },
  subscribe(onChange){
    const channel=supabase.channel("swarm-live-"+uuid())
      .on("postgres_changes",{event:"*",schema:"public",table:"projects"},onChange)
      .on("postgres_changes",{event:"*",schema:"public",table:"swarms"},onChange)
      .on("postgres_changes",{event:"*",schema:"public",table:"invitations"},onChange)
      .on("postgres_changes",{event:"*",schema:"public",table:"notifications"},onChange)
      .on("postgres_changes",{event:"*",schema:"public",table:"invitation_messages"},onChange)
      .on("postgres_changes",{event:"*",schema:"public",table:"tasks"},onChange)
      .on("postgres_changes",{event:"*",schema:"public",table:"messages"},onChange)
      .on("postgres_changes",{event:"*",schema:"public",table:"swarm_decisions"},onChange)
      .on("postgres_changes",{event:"*",schema:"public",table:"swarm_members"},onChange)
      .on("postgres_changes",{event:"*",schema:"public",table:"project_files"},onChange)
      .subscribe();
    return ()=>supabase.removeChannel(channel);
  }
};