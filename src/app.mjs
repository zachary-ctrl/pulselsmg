import {Store,makeId} from "./store.mjs";
import {AIService,TrustService} from "./services.mjs";
import {normalizeBlueprint} from "./goal-engine.mjs";
import {Cloud} from "./cloud.mjs";

const $=(s,r=document)=>r.querySelector(s);
const $$=(s,r=document)=>[...r.querySelectorAll(s)];
const esc=v=>String(v??"").replace(/[&<>'"]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"}[c]));
const money=v=>v==null||v===""?"—":new Intl.NumberFormat("en-US",{style:"currency",currency:"USD",maximumFractionDigits:0}).format(Number(v)||0);
const fmtDate=v=>{if(!v)return"—";const d=new Date(String(v).slice(0,10)+"T12:00:00");return Number.isFinite(d.getTime())?d.toLocaleDateString(undefined,{month:"short",day:"numeric",year:"numeric"}):v};
const score=v=>Math.round(Number(v||0)*100);
const initials=name=>String(name||"S").trim().split(/\s+/).slice(0,2).map(x=>x[0]||"").join("").toUpperCase()||"S";
const haptic=()=>{try{navigator.vibrate?.(7)}catch{}};
const tempId=(p="tmp")=>p+"_"+makeId(p).slice(-12);

const state={
  session:null,profile:null,projects:[],swarms:[],invitations:[],notifications:[],publicProfiles:[],room:null,
  tab:"home",projectId:null,stage:"blueprint",candidates:null,teams:null,networkSize:0,
  toastTimer:null,deferredInstall:null,unsubscribeRealtime:null,hydrateTimer:null,loading:false
};

function toast(message){
  let el=$("#toast");if(!el){el=document.createElement("div");el.id="toast";el.className="toast";document.body.appendChild(el)}
  el.textContent=message;el.classList.add("show");clearTimeout(state.toastTimer);state.toastTimer=setTimeout(()=>el.classList.remove("show"),2600);
}
function isCreator(p){return !!p&&p.creatorId===state.profile?.id}
function currentProject(){return state.projectId?state.projects.find(p=>p.id===state.projectId)||null:null}
function currentSwarm(){return state.projectId?state.swarms.find(s=>s.projectId===state.projectId)||null:null}
function appInstalled(){return matchMedia("(display-mode: standalone)").matches||navigator.standalone===true}
function setTab(tab){state.tab=tab;render();window.scrollTo({top:0,behavior:"smooth"});haptic()}
async function openProject(id,stage="blueprint"){
  state.projectId=id;state.stage=stage;state.tab="projects";state.candidates=null;state.teams=null;state.room=null;
  if(stage==="room")await loadCurrentRoom();render();window.scrollTo({top:0,behavior:"smooth"});
}
function upsert(list,item){const i=list.findIndex(x=>x.id===item.id);if(i>=0)list[i]=item;else list.unshift(item);return list}
function sessionName(){return state.profile?.name||state.session?.user?.user_metadata?.name||String(state.session?.user?.email||"").split("@")[0]||"SWARM User"}

const sessionPromise=Cloud.session().then(s=>{state.session=s;return s}).catch(()=>null);

function showSplash(){
  const splash=$("#splash");if(!splash)return;
  setTimeout(()=>splash.classList.add("ready"),120);
  $("#enterSwarm")?.addEventListener("click",async()=>{
    splash.classList.add("leaving");haptic();await sessionPromise;
    setTimeout(async()=>{splash.remove();state.session?await start():showAuth("create")},420);
  });
}
function showAuth(mode="create",message=""){
  $("#authLayer")?.remove();
  const create=mode==="create",wrap=document.createElement("div");wrap.id="authLayer";wrap.className="auth-layer";
  wrap.innerHTML=`<section class="auth-card">
    <div class="brand-kicker">AN LSMG SYSTEM</div><div class="auth-mark">SWARM<span>///</span></div>
    <p>Real accounts. Cloud projects. Real invitations. Shared Swarm Rooms.</p>
    ${message?`<div class="cloud-auth-message">${esc(message)}</div>`:""}
    <div class="auth-tabs"><button data-auth="create" class="${create?"active":""}">CREATE</button><button data-auth="signin" class="${!create?"active":""}">SIGN IN</button></div>
    <form id="authForm">${create?'<label>NAME<input id="authName" required autocomplete="name" placeholder="Your name"></label>':""}
      <label>EMAIL<input id="authEmail" required type="email" autocomplete="email" placeholder="you@example.com"></label>
      <label>PASSWORD<input id="authPass" required type="password" minlength="8" autocomplete="${create?"new-password":"current-password"}" placeholder="8+ characters"></label>
      <button class="primary-btn">${create?"CREATE SWARM ACCOUNT":"SIGN IN"}</button>
    </form>
    <p class="auth-note">Authentication is handled by SWARM's dedicated Supabase backend. Your password is not stored in this app's JavaScript or local project storage.</p>
  </section>`;
  document.body.appendChild(wrap);
  $$("[data-auth]",wrap).forEach(b=>b.onclick=()=>showAuth(b.dataset.auth));
  $("#authForm",wrap).onsubmit=async e=>{
    e.preventDefault();const email=$("#authEmail",wrap).value.trim().toLowerCase(),pass=$("#authPass",wrap).value;
    const btn=$("button[type='submit']",wrap);btn.disabled=true;btn.textContent=create?"CREATING ACCOUNT…":"SIGNING IN…";
    try{
      if(create){
        const name=$("#authName",wrap).value.trim();const data=await Cloud.signUp(name,email,pass);
        if(!data.session){showAuth("signin","Account created. Check your email for the confirmation link, then sign in.");return}
        state.session=data.session;
      }else{
        const data=await Cloud.signIn(email,pass);state.session=data.session;
      }
      wrap.remove();await start();
    }catch(err){toast(err?.message||"Authentication failed");btn.disabled=false;btn.textContent=create?"CREATE SWARM ACCOUNT":"SIGN IN"}
  };
}
async function start(){
  $("#view").innerHTML=`<div class="cloud-loader"><i></i><b>CONNECTING TO SWARM CLOUD</b><span>Loading your profile, projects and invitations…</span></div>`;
  try{
    state.profile=await Cloud.loadProfile();
    const user=state.session?.user||await Cloud.currentUser();
    if(user?.email_confirmed_at&&!state.profile.verificationStatus?.email){
      state.profile=await Cloud.saveProfile({...state.profile,verificationStatus:{...state.profile.verificationStatus,email:true}});
    }
    const legacy=Store.getProfile();
    if(legacy&&!(state.profile.skills||[]).length&&(legacy.skills||[]).length){
      state.profile=await Cloud.saveProfile({...state.profile,...legacy,id:state.profile.id,cloud:true,verificationStatus:{...legacy.verificationStatus,email:!!user?.email_confirmed_at,identity:false}});
    }
    const legacyProjects=Store.getProjects();
    if(legacyProjects.length)await Cloud.importLegacyProjects(legacyProjects);
    await hydrateCloud();
    $(".avatar").textContent=initials(sessionName());
    state.unsubscribeRealtime?.();
    state.unsubscribeRealtime=Cloud.subscribe(()=>scheduleHydrate());
    render();
  }catch(err){console.error(err);showAuth("signin","SWARM Cloud could not load your account. Sign in again to reconnect.")}
}
function scheduleHydrate(){
  clearTimeout(state.hydrateTimer);
  state.hydrateTimer=setTimeout(async()=>{try{await hydrateCloud({keepRoom:true});render()}catch{}},350);
}
async function hydrateCloud({keepRoom=false}={}){
  const [projects,swarms,invitations,notifications,publicProfiles]=await Promise.all([
    Cloud.loadProjects(),Cloud.loadSwarms(),Cloud.loadInvitations(),Cloud.loadNotifications(),Cloud.loadPublicProfiles()
  ]);
  state.projects=projects;state.swarms=swarms;state.invitations=invitations;state.notifications=notifications;state.publicProfiles=publicProfiles;
  if(state.projectId&&!state.projects.some(p=>p.id===state.projectId))state.projectId=null;
  if(keepRoom&&state.stage==="room")await loadCurrentRoom();
}
async function loadCurrentRoom(){
  const p=currentProject(),s=currentSwarm();if(!p||!s){state.room=null;return}
  try{state.room=await Cloud.loadRoom(s.id,p.id)}catch{state.room=null}
}

function graphMoment(project,team,done){
  const overlay=document.createElement("div");overlay.className="formation-overlay";
  const members=[...new Set(team.assignments.map(a=>a.profileName))];
  overlay.innerHTML=`<div class="formation-scene"><div class="formation-label">SWARM MATCH ENGINE / FORMATION</div><div class="formation-nodes">
    ${members.slice(0,7).map((m,i)=>`<i style="--i:${i};--n:${members.length}" title="${esc(m)}"></i>`).join("")}<b></b></div>
    <h2>FORMING YOUR SWARM</h2><p>${esc(project.title)}</p></div>`;
  document.body.appendChild(overlay);setTimeout(()=>overlay.classList.add("converge"),350);
  setTimeout(()=>{$(".formation-scene h2",overlay).textContent="YOUR SWARM IS READY";overlay.classList.add("ready")},1800);
  setTimeout(()=>{overlay.classList.add("leave");setTimeout(()=>{overlay.remove();done?.()},320)},3000);
}

function incomingInvites(){return state.invitations.filter(i=>i.profileId===state.profile?.id&&i.status==="pending")}
function home(){
  const projects=state.projects.filter(p=>p.creatorId===state.profile?.id).slice(0,4),active=state.swarms.filter(s=>s.status==="active").length,invites=incomingInvites();
  return `<section class="hero">
    <div class="hero-ambient"><i></i><i></i><i></i><i></i><i></i></div>
    <div class="eyebrow">SWARM / LIVE GOAL-TO-ORGANIZATION ENGINE</div>
    <h1>WHAT ARE YOU TRYING TO <em>MAKE HAPPEN?</em></h1>
    <p>Describe the outcome. SWARM structures the work, searches the live capability network, scores constraints server-side, and assembles viable human teams.</p>
    <form class="goal-composer" id="goalForm">
      <textarea id="goalInput" required minlength="8" placeholder="I want to launch a streetwear brand in Dallas within 45 days with a $5,000 budget."></textarea>
      <div><span>SWARM AI → editable blueprint → deterministic matching</span><button class="primary-btn">BUILD BLUEPRINT <b>↗</b></button></div>
    </form>
    <div class="goal-examples">${["Build an iOS fitness app","Launch a clothing brand","Shoot a short film","Start a podcast","Organize a 300-person event","Launch a food truck"].map(x=>`<button data-example="${esc(x)}">${esc(x)}</button>`).join("")}</div>
  </section>
  <section class="system-strip"><div><b>${projects.length}</b><span>YOUR PROJECTS</span></div><div><b>${active}</b><span>ACTIVE SWARMS</span></div><div><b>${state.publicProfiles.filter(p=>p.id!==state.profile?.id).length}</b><span>LIVE PROFILES</span></div><div><b>${invites.length}</b><span>INVITES</span></div></section>
  ${invites.length?`<div class="section-head"><div><small>INCOMING</small><h2>YOU'VE BEEN MATCHED</h2></div></div><div class="invite-stack">${invites.map(incomingInviteCard).join("")}</div>`:""}
  <div class="section-head"><div><small>YOUR WORK</small><h2>PROJECTS IN MOTION</h2></div><button data-tab-jump="projects">VIEW ALL</button></div>
  ${projects.length?`<div class="project-grid">${projects.map(projectCard).join("")}</div>`:`<div class="empty-state"><div class="network-mini"></div><b>NO PROJECTS YET</b><p>Your first goal becomes a cloud-backed Project Blueprint.</p></div>`}
  <section class="principle-card"><span>THE CORE LOOP</span><div>GOAL <b>→</b> UNDERSTAND <b>→</b> ROLES <b>→</b> MATCH <b>→</b> TEAM <b>→</b> EXECUTE <b>→</b> LEARN</div></section>`;
}
function incomingInviteCard(i){
  return `<article class="invite-card live"><div><span class="member-avatar">↗</span><div><b>${esc(i.project?.title||"SWARM Project")}</b><small>${esc(i.roleTitle)} · ${money(i.estimatedCompensation)} EST.</small></div></div><em class="invite-status pending">PENDING</em>
    <p>${esc((i.whyMatched||[]).slice(0,2).join(" · ")||"Your capability profile matched this project's role requirements.")}</p>
    <div class="invite-actions"><button data-live-invite="${i.id}" data-response="accepted">ACCEPT</button><button data-live-invite="${i.id}" data-response="declined">DECLINE</button><button data-open-invite-project="${i.projectId}">VIEW PROJECT</button></div></article>`;
}
function projectCard(p){
  const swarm=state.swarms.find(s=>s.projectId===p.id),mine=isCreator(p);
  return `<button class="project-card" data-project="${p.id}">
    <div class="project-card-top"><span>${esc(p.category||"PROJECT")}</span><i class="status ${swarm?.status||p.status}">${mine?"OWNER · ":""}${esc(swarm?.status||p.status)}</i></div>
    <h3>${esc(p.title)}</h3><p>${esc(p.objective)}</p>
    <div class="project-card-meta"><span>${fmtDate(p.deadline)}</span><span>${p.budgetMax?money(p.budgetMax):"BUDGET OPEN"}</span><span>${(p.requiredRoles||[]).length} CORE ROLES</span></div>
  </button>`;
}
function projectsPage(){
  const p=currentProject();
  if(!p){
    return `<div class="page-title"><small>SWARM CLOUD</small><h1>PROJECTS.</h1><p>Projects you created plus projects where you have an active invitation or Swarm membership.</p></div>
      ${state.projects.length?`<div class="project-grid">${state.projects.map(projectCard).join("")}</div>`:`<div class="empty-state"><b>NOTHING TO ASSEMBLE YET</b><p>Start with a goal on Home.</p><button class="primary-btn" data-tab-jump="home">CREATE A GOAL</button></div>`}`;
  }
  return `<div class="project-shell">
    <header class="project-header"><button class="back-link" id="backProjects">← ALL PROJECTS</button><div><small>${esc(p.category||"PROJECT")} · ${isCreator(p)?"OWNER":"MEMBER / INVITEE"}</small><h1>${esc(p.title)}</h1></div><span class="status ${esc(p.status)}">${esc(p.status)}</span></header>
    <nav class="project-nav">${[["blueprint","BLUEPRINT"],["roles","ROLE MAP"],["matches","MATCH LAB"],["teams","ASSEMBLY"],["invites","INVITES"],["room","SWARM ROOM"]].map(([k,l])=>`<button data-stage="${k}" class="${state.stage===k?"active":""}">${l}</button>`).join("")}</nav>
    <main class="project-stage">${projectStage(p)}</main>
  </div>`;
}
function projectStage(p){
  if(state.stage==="roles")return roleMap(p);
  if(state.stage==="matches")return matchLab(p);
  if(state.stage==="teams")return teamAssembly(p);
  if(state.stage==="invites")return invitationsView(p);
  if(state.stage==="room")return roomView(p);
  return blueprintView(p);
}
function blueprintView(p){
  if(!isCreator(p)){
    return `<div class="stage-heading"><div><small>PROJECT BLUEPRINT</small><h2>WHAT THIS SWARM IS BUILDING</h2></div></div>
    <div class="blueprint-readonly">
      <div><small>OBJECTIVE</small><p>${esc(p.objective)}</p></div><div><small>LOCATION</small><b>${esc(p.location||"Remote / unspecified")}</b></div>
      <div><small>DEADLINE</small><b>${fmtDate(p.deadline)}</b></div><div><small>BUDGET</small><b>${p.budgetMax?money(p.budgetMax):"OPEN"}</b></div>
      <div class="span-2"><small>REQUIRED ROLES</small><div class="chips">${(p.requiredRoles||[]).map(r=>`<span>${esc(r.title)}</span>`).join("")}</div></div>
      <div class="span-2"><small>RESOURCES</small><div class="chips">${(p.resourcesNeeded||[]).map(x=>`<span>${esc(x)}</span>`).join("")}</div></div>
    </div>`;
  }
  const all=[...(p.requiredRoles||[]).map(r=>({...r,_type:"required"})),...(p.optionalRoles||[]).map(r=>({...r,_type:"optional"}))];
  return `<div class="stage-heading"><div><small>AI PROPOSES · YOU CONTROL</small><h2>PROJECT BLUEPRINT</h2></div><button class="outline-btn" id="saveBlueprint">SAVE TO CLOUD</button></div>
  <form class="blueprint-form" id="blueprintForm">
    <div class="field-grid">
      <label>TITLE<input name="title" value="${esc(p.title)}"></label><label>CATEGORY<input name="category" value="${esc(p.category||"")}"></label>
      <label class="span-2">OBJECTIVE<textarea name="objective">${esc(p.objective)}</textarea></label>
      <label>LOCATION<input name="location" value="${esc(p.location||"")}"></label>
      <label>REMOTE ALLOWED<select name="remoteAllowed"><option value="true" ${p.remoteAllowed?"selected":""}>YES</option><option value="false" ${!p.remoteAllowed?"selected":""}>NO</option></select></label>
      <label>BUDGET MIN<input name="budgetMin" type="number" value="${p.budgetMin??""}"></label><label>BUDGET MAX<input name="budgetMax" type="number" value="${p.budgetMax??""}"></label>
      <label>START DATE<input name="startDate" type="date" value="${esc(p.startDate||"")}"></label><label>DEADLINE<input name="deadline" type="date" value="${esc(p.deadline||"")}"></label>
      <label>TEAM SIZE MIN<input name="teamSizeMin" type="number" value="${p.teamSizeMin??""}"></label><label>TEAM SIZE MAX<input name="teamSizeMax" type="number" value="${p.teamSizeMax??""}"></label>
      <label>PROJECT VISIBILITY<select name="visibility"><option value="private" ${p.visibility!=="public"?"selected":""}>PRIVATE</option><option value="public" ${p.visibility==="public"?"selected":""}>PUBLIC</option></select></label>
    </div>
    <div class="blueprint-section"><div class="subhead"><b>ROLE REQUIREMENTS</b><button type="button" id="addRole">+ ADD ROLE</button></div>
      <div class="role-editor-list">${all.map(r=>`<article class="role-editor" data-role-editor data-type="${r._type}" data-id="${r.id}">
        <div class="role-editor-head"><select data-role-type><option value="required" ${r._type==="required"?"selected":""}>REQUIRED</option><option value="optional" ${r._type==="optional"?"selected":""}>OPTIONAL</option></select><button type="button" data-remove-role>REMOVE</button></div>
        <label>ROLE<input data-role-title value="${esc(r.title)}"></label><label>SKILLS<input data-role-skills value="${esc((r.skills||[]).map(s=>s.name).join(", "))}"></label>
        <div class="two-col"><label>BUDGET CAP<input data-role-budget type="number" value="${r.budgetCap??""}"></label><label>HOURS<input data-role-hours type="number" value="${r.estimatedHours??24}"></label></div>
        <label>LANGUAGES<input data-role-languages value="${esc((r.requiredLanguages||[]).join(", "))}"></label>
      </article>`).join("")}</div>
    </div>
    <div class="field-grid">
      <label class="span-2">RESOURCES NEEDED<textarea name="resourcesNeeded">${esc((p.resourcesNeeded||[]).join("\n"))}</textarea></label>
      <label class="span-2">CONSTRAINTS<textarea name="constraints">${esc((p.constraints||[]).join("\n"))}</textarea></label>
      <label class="span-2">PREFERRED WORKING STYLE<input name="preferredWorkingStyle" value="${esc((p.preferredWorkingStyle||[]).join(", "))}"></label>
      <label class="span-2">PREFERRED EXPERIENCE<input name="preferredExperience" value="${esc((p.preferredExperience||[]).join(", "))}"></label>
    </div>
    <div class="blueprint-section"><div class="subhead"><b>MILESTONES</b><button type="button" id="addMilestone">+ ADD</button></div><div id="milestoneEditors">
      ${(p.milestones||[]).map(m=>`<div class="milestone-edit" data-ms-id="${m.id}"><input value="${esc(m.title)}"><button type="button" data-remove-ms>×</button></div>`).join("")}
    </div></div>
  </form><div class="stage-actions"><button class="primary-btn" data-stage-go="roles">VIEW ROLE MAP →</button></div>`;
}
function roleMap(p){
  const roles=[...(p.requiredRoles||[]),...(p.optionalRoles||[])],n=Math.max(roles.length,1),cx=300,cy=230,r=165;
  const nodes=roles.map((role,i)=>{const a=(-Math.PI/2)+(i/n)*Math.PI*2;return{role,x:cx+Math.cos(a)*r,y:cy+Math.sin(a)*r}});
  const svg=`<svg viewBox="0 0 600 460" class="role-graph" aria-label="Project role graph"><defs><filter id="glow"><feGaussianBlur stdDeviation="4" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
    ${nodes.map(n=>`<line x1="${cx}" y1="${cy}" x2="${n.x}" y2="${n.y}"/>`).join("")}
    <g class="center-node"><circle cx="${cx}" cy="${cy}" r="65"/><text x="${cx}" y="${cy-6}" text-anchor="middle">PROJECT</text><text x="${cx}" y="${cy+13}" text-anchor="middle" class="small">${esc((p.category||"PROJECT").slice(0,18))}</text></g>
    ${nodes.map(n=>`<g class="role-node ${n.role.required?"required":"optional"}" data-role-node="${n.role.id}"><circle cx="${n.x}" cy="${n.y}" r="47"/><text x="${n.x}" y="${n.y-3}" text-anchor="middle">${esc(n.role.title.split(" ").slice(0,2).join(" "))}</text><text x="${n.x}" y="${n.y+13}" text-anchor="middle" class="small">${n.role.required?"CORE":"OPTIONAL"}</text></g>`).join("")}</svg>`;
  return `<div class="stage-heading"><div><small>ORGANIZATION MODEL</small><h2>ROLE MAP</h2></div><span>${roles.length} NODES</span></div>
    <div class="graph-card">${svg}</div><div class="role-map-list">${roles.map(r=>`<button data-role-detail="${r.id}"><span class="role-dot ${r.required?"":"optional"}"></span><div><b>${esc(r.title)}</b><small>${esc((r.skills||[]).map(s=>s.name).join(" · "))}</small></div><em>${r.required?"REQUIRED":"OPTIONAL"}</em></button>`).join("")}</div>
    ${isCreator(p)?`<div class="stage-actions"><button class="outline-btn" data-stage-go="blueprint">EDIT BLUEPRINT</button><button class="primary-btn" id="runMatching">RUN LIVE MATCH ENGINE →</button></div>`:""}`;
}
function matchLab(p){
  if(!state.candidates){
    return `<div class="stage-heading"><div><small>SWARM MATCH ENGINE</small><h2>MATCH LAB</h2></div></div><div class="empty-state"><b>${isCreator(p)?"READY TO SEARCH THE LIVE NETWORK":"MATCH RESULTS NOT LOADED"}</b><p>${isCreator(p)?"Matching runs server-side against public SWARM capability profiles. No demo people are used.":"Only the project creator can initiate matching."}</p>${isCreator(p)?'<button class="primary-btn" id="runMatching">RUN LIVE MATCH ENGINE</button>':""}</div>`;
  }
  return `<div class="live-banner"><b>LIVE NETWORK</b><span>${state.networkSize} eligible public profiles were considered. Match scores come from structured server-side components.</span></div>
  <div class="stage-heading"><div><small>SWARM MATCH ENGINE</small><h2>MATCH LAB</h2></div><span>DETERMINISTIC / EXPLAINABLE</span></div>
  <div class="match-role-stack">${(p.requiredRoles||[]).map(role=>{const list=(state.candidates[role.id]||[]).slice(0,5);return`<section class="match-role"><header><div><small>ROLE</small><h3>${esc(role.title)}</h3></div><span>${list.length} ELIGIBLE</span></header>
    ${list.length?list.map((item,i)=>candidateCard(item,role,i)).join(""):`<div class="no-match"><b>NO ELIGIBLE PEOPLE YET</b><p>No real public SWARM profile currently satisfies this role's hard constraints. Invite more people to join SWARM or edit the blueprint.</p></div>`}</section>`}).join("")}</div>
  <div class="stage-actions"><button class="outline-btn" data-stage-go="roles">BACK TO ROLE MAP</button><button class="primary-btn" data-stage-go="teams">VIEW OPTIMIZED TEAMS →</button></div>`;
}
function candidateCard(item,role,i){
  const p=item.profile,m=item.match;
  return `<article class="candidate-card"><div class="candidate-rank">${String(i+1).padStart(2,"0")}</div><div class="candidate-main">
    <div class="candidate-title"><div><h4>${esc(p.name)}</h4><span>${esc([p.location?.city,p.location?.state].filter(Boolean).join(", ")||"LOCATION PRIVATE")} · ${money(m.estimatedCost)} EST.</span></div><strong>${m.percent}%</strong></div>
    <div class="score-bars">${Object.entries(m.breakdown||{}).map(([k,v])=>`<div><span>${esc(k.replace(/([A-Z])/g," $1").toUpperCase())}</span><i><b style="width:${score(v)}%"></b></i><em>${score(v)}</em></div>`).join("")}</div>
    <div class="match-reasons"><div><small>STRONGEST REASONS</small>${(m.reasons||[]).slice(0,3).map(x=>`<span>✓ ${esc(x)}</span>`).join("")||"<span>Structured fit across the required signals.</span>"}</div>
    ${(m.concerns||[]).length?`<div class="concerns"><small>POSSIBLE CONCERNS</small>${m.concerns.map(x=>`<span>△ ${esc(x)}</span>`).join("")}</div>`:""}</div>
    <button class="text-action" data-profile-live="${p.id}">VIEW CAPABILITY + TRUST SIGNALS →</button></div></article>`;
}
function teamAssembly(p){
  const teams=state.teams||[];
  if(!teams.length)return `<div class="stage-heading"><div><small>TEAM OPTIMIZER</small><h2>NO COMPLETE LIVE TEAM YET</h2></div></div><div class="no-match"><p>The current real network cannot satisfy every required role and constraint yet. SWARM will not fabricate a team.</p>${isCreator(p)?'<button class="primary-btn" data-stage-go="blueprint">EDIT CONSTRAINTS</button>':""}</div>`;
  return `<div class="live-banner"><b>LIVE TEAM OPTIMIZATION</b><span>Options below are composed from real public SWARM profiles and persisted server-side.</span></div>
  <div class="stage-heading"><div><small>WHOLE-TEAM OPTIMIZATION</small><h2>TEAM ASSEMBLY</h2></div><span>${teams.length} DISTINCT OPTIONS</span></div><div class="team-options">${teams.map((team,i)=>teamCard(team,i,p)).join("")}</div>`;
}
function teamCard(team,i,p){
  const m=team.metrics||{};
  return `<article class="team-card ${i===0?"featured":""}"><header><div><small>${esc(team.label||"SWARM")}</small><h3>${m.percent??Math.round(Number(team.score||0)*100)}% TEAM FIT</h3></div>${isCreator(p)?`<button class="primary-btn" data-build-team="${i}">BUILD THIS SWARM</button>`:""}</header>
    <div class="team-metrics"><div><b>${m.memberCount??new Set((team.assignments||[]).map(a=>a.profileId)).size}</b><span>MEMBERS</span></div><div><b>${money(m.totalBudget??team.projected_cost)}</b><span>PROJECTED COST</span></div><div><b>${Math.round(Number(m.roleCoverage||0)*100)}%</b><span>ROLE COVERAGE</span></div><div><b>${Math.round(Number(m.scheduleCompatibility||0)*100)}%</b><span>SCHEDULE</span></div></div>
    <div class="team-members">${(team.assignments||[]).map(a=>`<div><span class="member-avatar">${initials(a.profileName)}</span><div><b>${esc(a.profileName)}</b><small>${esc(a.roleTitle)} · ${a.percent??a.match?.percent??0}% role fit</small></div><em>${money(a.incrementalCost??a.estimatedCost)}</em></div>`).join("")}</div>
    <div class="team-score-grid">${[["PAIRWISE",m.pairwiseCompatibility],["RELIABILITY",m.reliability],["BUDGET",m.budgetCompatibility],["SKILL COMPLEMENT",m.skillComplementarity],["PRIOR TEAM SIGNAL",m.priorTeamSuccess]].map(([l,v])=>`<span><b>${Math.round(Number(v||0)*100)}%</b><small>${l}</small></span>`).join("")}</div></article>`;
}
function invitationsView(p){
  const invites=state.invitations.filter(i=>i.projectId===p.id),swarm=currentSwarm(),mine=isCreator(p);
  if(!invites.length)return `<div class="empty-state"><b>NO INVITATIONS YET</b><p>${mine?"Choose a complete team configuration to create real invitations.":"No invitation is currently attached to this project for your account."}</p>${mine?'<button class="primary-btn" data-stage-go="teams">OPEN ASSEMBLY</button>':""}</div>`;
  return `<div class="live-banner"><b>REAL INVITATIONS</b><span>These records are stored in SWARM Cloud and recipients see them on their own accounts.</span></div><div class="stage-heading"><div><small>FORMATION STATUS</small><h2>INVITATIONS</h2></div><span>${esc(swarm?.status||p.status)}</span></div>
  <div class="invite-stack">${invites.map(i=>`<article class="invite-card"><div><span class="member-avatar">${initials(i.profileName)}</span><div><b>${esc(i.profileName)}</b><small>${esc(i.roleTitle)} · ${money(i.estimatedCompensation)}</small></div></div><em class="invite-status ${i.status}">${i.status}</em>
    <p>${esc((i.whyMatched||[]).slice(0,2).join(" · "))}</p>
    ${!mine&&i.profileId===state.profile.id&&i.status==="pending"?`<div class="invite-actions"><button data-live-invite="${i.id}" data-response="accepted">ACCEPT</button><button data-live-invite="${i.id}" data-response="declined">DECLINE</button></div>`:""}</article>`).join("")}</div>
  <div class="stage-actions"><button class="primary-btn" data-stage-go="room">OPEN SWARM ROOM →</button></div>`;
}
function roomView(p){
  const swarm=currentSwarm();if(!swarm)return `<div class="empty-state"><b>SWARM ROOM NOT ACTIVE FOR YOU</b><p>Creators must build a team. Invitees gain room access after accepting.</p>${isCreator(p)?'<button class="primary-btn" data-stage-go="teams">ASSEMBLE TEAM</button>':""}</div>`;
  const room=state.room;if(!room)return `<div class="cloud-loader"><i></i><b>LOADING SWARM ROOM</b><span>Syncing people, tasks, chat and files…</span></div>`;
  const assignments=swarm.assignments||[],accepted=(room.members||[]).filter(m=>["accepted","active"].includes(m.member_status));
  const resources=p.resourcesNeeded||[],creator=isCreator(p);
  const nameFor=id=>(room.members||[]).find(m=>m.profile_id===id)?.profile?.name||state.publicProfiles.find(x=>x.id===id)?.name||(id===state.profile.id?state.profile.name:"MEMBER");
  return `<div class="room-head"><div><small>SWARM ROOM / ${esc(swarm.status)} · REALTIME</small><h2>${esc(p.title)}</h2></div><button class="coordinator-btn" id="runCoordinator">ASK COORDINATOR ✦</button></div>
  <div class="room-grid">
    <section class="room-card span-2"><header><b>TEAM</b><span>${accepted.length}/${assignments.length} ACCEPTED</span></header><div class="room-members">${assignments.map(a=>{const mem=(room.members||[]).find(m=>m.profile_id===a.profileId&&m.role_id===a.roleId);const joined=mem&&["accepted","active"].includes(mem.member_status);return`<div><span class="member-avatar">${initials(a.profileName)}</span><div><b>${esc(a.profileName)}</b><small>${esc(a.roleTitle)}</small></div><em class="${joined?"on":""}">${joined?"IN":esc(mem?.member_status||"PENDING")}</em></div>`}).join("")}</div></section>
    <section class="room-card"><header><b>MILESTONES</b><span>${(p.milestones||[]).filter(m=>m.status==="done").length}/${(p.milestones||[]).length}</span></header><div class="check-list">${(p.milestones||[]).map(m=>`<label><input type="checkbox" data-ms-check="${m.id}" ${m.status==="done"?"checked":""} ${creator?"":"disabled"}><span>${esc(m.title)}</span></label>`).join("")}</div></section>
    <section class="room-card"><header><b>RESOURCES</b><span>${resources.length}</span></header><div class="resource-list">${resources.map(x=>`<span>${esc(x)}</span>`).join("")}</div></section>
    <section class="room-card"><header><b>TASK BOARD</b><button id="addTask">+ TASK</button></header><div class="task-list">${(room.tasks||[]).map(t=>`<label><input type="checkbox" data-task-check="${t.id}" ${t.status==="done"?"checked":""}><span>${esc(t.title)}</span><small>${t.due_at?fmtDate(t.due_at):""}</small></label>`).join("")||"<p>No tasks yet.</p>"}</div></section>
    <section class="room-card"><header><b>DECISION LOG</b><button id="addDecision">+ DECISION</button></header><div class="decision-list">${(room.decisions||[]).slice().reverse().map(d=>`<div><span>${esc(d.author?.name||nameFor(d.author_id))} · ${new Date(d.created_at).toLocaleDateString()}</span><p>${esc(d.body)}</p></div>`).join("")||"<p>No decisions logged.</p>"}</div></section>
    <section class="room-card span-2"><header><b>PROJECT CHAT</b><span>REALTIME</span></header><div class="chat-log">${(room.messages||[]).map(m=>`<div><b>${esc(m.sender?.name||nameFor(m.sender_id))}</b><p>${esc(m.body)}</p></div>`).join("")||"<p>No messages yet.</p>"}</div><form id="messageForm" class="room-composer"><input id="messageInput" placeholder="Post an update to the room…" required><button>POST</button></form></section>
    <section class="room-card span-2"><header><b>FILES</b><label class="upload-btn">UPLOAD<input id="fileUpload" type="file" hidden></label></header><div class="file-list">${(room.files||[]).map(f=>`<button data-file-path="${esc(f.storage_path)}"><b>${esc(f.display_name)}</b><small>${f.size_bytes?Math.round(f.size_bytes/1024)+" KB":""}</small></button>`).join("")||"<p>No files yet.</p>"}</div></section>
  </div>${creator?`<div class="stage-actions"><button class="outline-btn" id="projectOutcome">COMPLETE / RECORD OUTCOME</button></div>`:""}`;
}
function discovery(){
  const profiles=state.publicProfiles.filter(p=>p.id!==state.profile?.id);
  return `<div class="page-title"><small>LIVE CAPABILITY NETWORK</small><h1>DISCOVERY.</h1><p>Discovery is secondary. SWARM's primary workflow remains Goal → Swarm.</p></div>
    <div class="live-banner"><b>${profiles.length} PUBLIC PROFILES</b><span>Only people who explicitly made their SWARM profile public appear here.</span></div>
    <div class="discovery-tools"><input id="discoverySearch" placeholder="Search skills, roles, industries…"><select id="discoveryFilter"><option value="">ALL CAPABILITIES</option><option>Technology</option><option>Fashion</option><option>Film</option><option>Events</option><option>Music</option><option>Food</option></select></div>
    <div class="people-grid" id="peopleGrid">${profiles.length?profiles.map(discoveryCard).join(""):`<div class="empty-state"><b>THE LIVE NETWORK IS EMPTY</b><p>No other user has made a capability profile public yet. Share SWARM with collaborators and have them complete onboarding.</p><button class="primary-btn" id="shareSwarm">SHARE SWARM</button></div>`}</div>`;
}
function discoveryCard(p){
  const skills=(p.skills||[]).map(s=>Array.isArray(s)?s[0]:s.name),text=[p.name,p.bio,...(p.industries||[]),...(p.desiredRoles||[]),...skills].join(" ").toLowerCase();
  return `<button class="person-card" data-profile-live="${p.id}" data-search="${esc(text)}"><div><span class="member-avatar">${initials(p.name)}</span><em>LIVE</em></div><h3>${esc(p.name)}</h3><p>${esc(p.bio||"Capability profile")}</p><div class="chips">${skills.slice(0,4).map(s=>`<span>${esc(s)}</span>`).join("")}</div><small>${esc([p.location?.city,p.location?.state].filter(Boolean).join(", ")||"LOCATION PRIVATE")} · ${p.remoteAllowed?"REMOTE OK":"LOCAL"}</small></button>`;
}
function profilePage(){
  const p=state.profile,trust=TrustService.signals(p);
  return `<div class="page-title profile-title"><div><small>LIVE CLOUD CAPABILITY PROFILE</small><h1>YOU.</h1></div><button class="outline-btn" id="editProfile">EDIT PROFILE</button></div>
  <div class="cloud-status"><i></i><b>SWARM CLOUD CONNECTED</b><span>${esc(state.session?.user?.email||"")}</span></div>
  <section class="profile-hero"><div class="profile-big-avatar">${initials(p.name)}</div><div><h2>${esc(p.name)}</h2><p>${esc(p.bio||"Add what you can help with and what you are building.")}</p><span>${esc([p.location?.city,p.location?.state].filter(Boolean).join(", ")||"LOCATION PRIVATE")}</span></div></section>
  <div class="capability-grid"><section><small>I CAN HELP WITH</small><div class="chips">${(p.skills||[]).length?p.skills.map(s=>`<span>${esc(Array.isArray(s)?s[0]:s.name)}</span>`).join(""):"<span>ADD SKILLS</span>"}</div></section><section><small>WHAT I'M BUILDING</small><div class="chips">${(p.goals||[]).length?p.goals.map(x=>`<span>${esc(x)}</span>`).join(""):"<span>ADD GOALS</span>"}</div></section></div>
  <div class="section-head"><div><small>TRUST</small><h2>VISIBLE SIGNALS, NOT A SOCIAL SCORE</h2></div></div><div class="trust-grid">${trust.map(s=>`<div><b>${s.value===true?"VERIFIED":s.value===false?"NOT VERIFIED":s.value??"NO DATA"}</b><span>${esc(s.label)}</span></div>`).join("")}</div>
  <div class="section-head"><div><small>PRIVACY</small><h2>YOU CONTROL WHAT IS SHARED</h2></div></div>
  <div class="privacy-card"><span>Profile visibility <b>${esc(p.visibility||"private")}</b></span><span>Exact location <b>NEVER EXPOSED</b></span><span>Rate visibility <b>${esc(p.rateVisibility||"private")}</b></span><span>Contact information <b>PRIVATE</b></span></div>
  <div class="account-actions">${!appInstalled()?'<button id="installBtn">INSTALL SWARM</button>':""}<button id="signOut">SIGN OUT</button></div>`;
}
async function notificationsModal(){
  const notes=state.notifications;
  openModal(`<div class="modal-head"><div><small>SWARM CLOUD</small><h2>NOTIFICATIONS</h2></div><button data-close>×</button></div><div class="notification-list">${notes.length?notes.map(n=>`<div><b>${esc(n.title)}</b><p>${esc(n.body)}</p><small>${new Date(n.created_at).toLocaleString()}</small></div>`).join(""):"<p>No notifications yet.</p>"}</div>`);
  for(const n of notes.filter(x=>!x.read_at).slice(0,25))Cloud.markNotificationRead(n.id).catch(()=>{});
}
function profileModal(id){
  const p=state.publicProfiles.find(x=>x.id===id);if(!p)return;const trust=TrustService.signals(p),skills=(p.skills||[]).map(s=>Array.isArray(s)?s:[s.name,s.level||s.proficiency||0,s.verified]);
  openModal(`<div class="modal-head"><div><small>LIVE CAPABILITY PROFILE</small><h2>${esc(p.name)}</h2></div><button data-close>×</button></div><p class="modal-lead">${esc(p.bio||"No bio yet.")}</p>
    <div class="chips">${skills.map(s=>`<span>${esc(s[0])} · ${Math.round(Number(s[1]||0)*100)}%</span>`).join("")}</div>
    <div class="proof-grid"><div><b>${p.projectsCompleted??0}</b><span>PROJECTS</span></div><div><b>${p.completionRate==null?"—":Math.round(p.completionRate*100)+"%"}</b><span>COMPLETION</span></div><div><b>${p.responseRate==null?"—":Math.round(p.responseRate*100)+"%"}</b><span>RESPONSE</span></div><div><b>${p.peerRatings??"—"}</b><span>PEER RATING</span></div></div>
    <div class="trust-list">${trust.map(s=>`<span><b>${esc(s.label)}</b><em>${s.value===true?"YES":s.value===false?"NO":esc(s.value??"NO DATA")}</em></span>`).join("")}</div>`);
}
function roleModal(p,id){
  const r=[...(p.requiredRoles||[]),...(p.optionalRoles||[])].find(x=>x.id===id);if(!r)return;
  openModal(`<div class="modal-head"><div><small>${r.required?"REQUIRED ROLE":"OPTIONAL ROLE"}</small><h2>${esc(r.title)}</h2></div><button data-close>×</button></div><div class="modal-section"><small>SKILLS</small><div class="chips">${(r.skills||[]).map(s=>`<span>${esc(s.name)}</span>`).join("")}</div></div><div class="proof-grid"><div><b>${money(r.budgetCap)}</b><span>BUDGET CAP</span></div><div><b>${r.estimatedHours||24}</b><span>EST. HOURS</span></div></div>`);
}
function openModal(html){const dlg=$("#modal");$("#modalCard").innerHTML=html;dlg.showModal();$$("[data-close]",dlg).forEach(b=>b.onclick=()=>dlg.close())}
function editProfileModal(){
  const p=state.profile;
  openModal(`<div class="modal-head"><div><small>LIVE CAPABILITY PROFILE</small><h2>EDIT PROFILE</h2></div><button data-close>×</button></div>
  <form id="profileForm" class="modal-form"><label>NAME<input name="name" value="${esc(p.name)}" required></label><label>BIO<textarea name="bio">${esc(p.bio||"")}</textarea></label>
  <label>SKILLS <small>comma separated; self-reported skills start at 80% proficiency until verified</small><input name="skills" value="${esc((p.skills||[]).map(s=>Array.isArray(s)?s[0]:s.name).join(", "))}"></label>
  <label>DESIRED ROLES<input name="desiredRoles" value="${esc((p.desiredRoles||[]).join(", "))}"></label><label>INDUSTRIES<input name="industries" value="${esc((p.industries||[]).join(", "))}"></label>
  <div class="two-col"><label>CITY<input name="city" value="${esc(p.location?.city||"")}"></label><label>STATE<input name="state" value="${esc(p.location?.state||"")}"></label></div>
  <div class="two-col"><label>HOURLY RATE<input name="hourlyRate" type="number" value="${p.hourlyRate||""}"></label><label>PROJECT RATE<input name="projectRate" type="number" value="${p.projectRate||""}"></label></div>
  <div class="two-col"><label>AVAILABLE FROM<input name="availableStart" type="date" value="${esc(p.availability?.start||"")}"></label><label>AVAILABLE UNTIL<input name="availableEnd" type="date" value="${esc(p.availability?.end||"")}"></label></div>
  <label>HOURS / WEEK<input name="hoursPerWeek" type="number" value="${p.availability?.hoursPerWeek||10}"></label>
  <label>GOALS<input name="goals" value="${esc((p.goals||[]).join(", "))}"></label><label>PROJECT TYPES<input name="projectTypes" value="${esc((p.preferredProjectTypes||[]).join(", "))}"></label>
  <label>WORKING STYLE<input name="workingStyle" value="${esc((p.workingStyle||[]).join(", "))}"></label><label>COMMUNICATION<input name="communication" value="${esc((p.communicationPreferences||[]).join(", "))}"></label>
  <label>LANGUAGES<input name="languages" value="${esc((p.languages||[]).join(", "))}"></label>
  <label>VISIBILITY<select name="visibility"><option value="private" ${p.visibility==="private"?"selected":""}>PRIVATE — NOT MATCHABLE</option><option value="public" ${p.visibility==="public"?"selected":""}>PUBLIC — ELIGIBLE FOR MATCHING</option></select></label>
  <button class="primary-btn">SAVE TO SWARM CLOUD</button></form>`);
  $("#profileForm").onsubmit=async e=>{
    e.preventDefault();const f=new FormData(e.currentTarget),split=k=>String(f.get(k)||"").split(",").map(x=>x.trim()).filter(Boolean),btn=$("button[type='submit']",e.currentTarget);btn.disabled=true;btn.textContent="SAVING…";
    try{
      const next={...p,name:String(f.get("name")),bio:String(f.get("bio")||""),skills:split("skills").map(x=>[x,.8,false]),desiredRoles:split("desiredRoles"),industries:split("industries"),
        location:{...p.location,city:String(f.get("city")||""),state:String(f.get("state")||"")},hourlyRate:Number(f.get("hourlyRate")||0),projectRate:Number(f.get("projectRate")||0),
        availability:{start:String(f.get("availableStart")||""),end:String(f.get("availableEnd")||""),hoursPerWeek:Number(f.get("hoursPerWeek")||10)},
        goals:split("goals"),preferredProjectTypes:split("projectTypes"),workingStyle:split("workingStyle"),communicationPreferences:split("communication"),languages:split("languages"),
        visibility:String(f.get("visibility")||"private"),verificationStatus:{...p.verificationStatus,skills:false}};
      state.profile=await Cloud.saveProfile(next);await hydrateCloud();$(".avatar").textContent=initials(next.name);$("#modal").close();render();toast(next.visibility==="public"?"Profile live in SWARM matching network":"Profile saved privately");
    }catch(err){toast(err?.message||"Could not save profile");btn.disabled=false;btn.textContent="SAVE TO SWARM CLOUD"}
  };
}
function taskModal(){
  openModal(`<div class="modal-head"><div><small>SWARM ROOM</small><h2>NEW TASK</h2></div><button data-close>×</button></div><form id="taskForm" class="modal-form"><label>TASK<input name="title" required></label><label>DUE DATE<input name="due" type="date"></label><button class="primary-btn">CREATE TASK</button></form>`);
  $("#taskForm").onsubmit=async e=>{e.preventDefault();const f=new FormData(e.currentTarget);try{await Cloud.addTask(currentSwarm().id,String(f.get("title")),String(f.get("due")||"")||null);$("#modal").close();await loadCurrentRoom();render();toast("Task created")}catch(err){toast(err?.message||"Could not create task")}};
}
function decisionModal(){
  openModal(`<div class="modal-head"><div><small>SWARM ROOM</small><h2>LOG DECISION</h2></div><button data-close>×</button></div><form id="decisionForm" class="modal-form"><label>DECISION<textarea name="text" required></textarea></label><button class="primary-btn">LOG DECISION</button></form>`);
  $("#decisionForm").onsubmit=async e=>{e.preventDefault();try{await Cloud.addDecision(currentSwarm().id,String(new FormData(e.currentTarget).get("text")));$("#modal").close();await loadCurrentRoom();render();toast("Decision logged")}catch(err){toast(err?.message||"Could not log decision")}};
}
function outcomeModal(p){
  openModal(`<div class="modal-head"><div><small>OUTCOME LEARNING</small><h2>PROJECT OUTCOME</h2></div><button data-close>×</button></div><form id="outcomeForm" class="modal-form">
    <label>PROJECT FINISHED?<select name="finished"><option value="true">YES</option><option value="false">NO</option></select></label><label>ON TIME?<select name="onTime"><option value="true">YES</option><option value="false">NO</option></select></label>
    <label>ON BUDGET?<select name="onBudget"><option value="true">YES</option><option value="false">NO</option></select></label><label>SATISFACTION 1–5<input name="satisfaction" type="number" min="1" max="5" value="5"></label>
    <label>WHAT WAS PRODUCED?<textarea name="produced"></textarea></label><button class="primary-btn">RECORD OUTCOME</button></form>`);
  $("#outcomeForm").onsubmit=async e=>{e.preventDefault();const f=new FormData(e.currentTarget),b=k=>f.get(k)==="true";try{await Cloud.saveOutcome(p,currentSwarm(),{finished:b("finished"),onTime:b("onTime"),onBudget:b("onBudget"),creatorSatisfied:Number(f.get("satisfaction")),produced:String(f.get("produced")||"")});$("#modal").close();await hydrateCloud();render();toast("Outcome recorded in SWARM Cloud")}catch(err){toast(err?.message||"Could not record outcome")}};
}
async function coordinatorModal(p){
  openModal(`<div class="modal-head"><div><small>AI COORDINATOR</small><h2>PROJECT CHECK</h2></div><button data-close>×</button></div><div class="ai-wait"><i></i><p>Analyzing live blueprint, room state, tasks and budget…</p></div>`);
  const result=await AIService.coordinate(p,{...currentSwarm(),room:state.room});$("#modalCard").innerHTML=`<div class="modal-head"><div><small>AI COORDINATOR · ${esc(result.source)}</small><h2>PROJECT CHECK</h2></div><button data-close>×</button></div><div class="coordinator-report"><p>${esc(result.text)}</p><small>SWARM AI identifies risks and options. It cannot send invitations, spend money, remove people, or make irreversible decisions without user action.</small></div>`;$$("[data-close]",$("#modal")).forEach(b=>b.onclick=()=>$("#modal").close());
}
function collectBlueprint(p){
  const form=$("#blueprintForm"),f=new FormData(form),req=[],opt=[];
  $$("[data-role-editor]",form).forEach(el=>{const required=$("[data-role-type]",el)?.value==="required";const role={id:el.dataset.id||tempId("role"),title:$("[data-role-title]",el).value.trim()||"Specialist",skills:$("[data-role-skills]",el).value.split(",").map(x=>x.trim()).filter(Boolean).map(name=>({name,required:true,weight:1})),budgetCap:Number($("[data-role-budget]",el).value||0)||null,estimatedHours:Number($("[data-role-hours]",el).value||24),requiredLanguages:$("[data-role-languages]",el).value.split(",").map(x=>x.trim()).filter(Boolean),certifications:[],notes:"",required};(required?req:opt).push(role)});
  const milestones=$$("[data-ms-id]",form).map((el,i)=>({id:el.dataset.msId||tempId("ms"),title:$("input",el).value.trim()||"Milestone",status:(p.milestones||[]).find(m=>m.id===el.dataset.msId)?.status||"todo",order:i+1,dueDate:null}));
  return {...p,title:String(f.get("title")),category:String(f.get("category")),objective:String(f.get("objective")),location:String(f.get("location")),remoteAllowed:f.get("remoteAllowed")==="true",
    budgetMin:Number(f.get("budgetMin")||0)||null,budgetMax:Number(f.get("budgetMax")||0)||null,startDate:String(f.get("startDate")||"")||null,deadline:String(f.get("deadline")||"")||null,
    teamSizeMin:Number(f.get("teamSizeMin")||0)||null,teamSizeMax:Number(f.get("teamSizeMax")||0)||null,visibility:String(f.get("visibility")||"private"),requiredRoles:req,optionalRoles:opt,
    resourcesNeeded:String(f.get("resourcesNeeded")||"").split("\n").map(x=>x.trim()).filter(Boolean),constraints:String(f.get("constraints")||"").split("\n").map(x=>x.trim()).filter(Boolean),
    preferredWorkingStyle:String(f.get("preferredWorkingStyle")||"").split(",").map(x=>x.trim()).filter(Boolean),preferredExperience:String(f.get("preferredExperience")||"").split(",").map(x=>x.trim()).filter(Boolean),milestones,updatedAt:new Date().toISOString()};
}
async function runMatchingLive(){
  const p=currentProject();if(!p||!isCreator(p))return;
  state.loading=true;openModal(`<div class="ai-wait"><i></i><p>Filtering the live SWARM network, scoring candidates and optimizing complete teams…</p></div>`);
  try{
    const data=await Cloud.runMatching(p.id);state.networkSize=data.networkSize||0;state.candidates=data.candidates||{};state.teams=data.teams||[];
    if(data.project)upsert(state.projects,data.project);$("#modal").close();state.stage="matches";render();
    toast(state.networkSize?state.networkSize+" live profiles considered":"No other public profiles are eligible yet");
  }catch(err){$("#modal").close();toast(err?.message||"Live matching failed")}finally{state.loading=false}
}
async function respondInvite(id,status){
  try{
    const data=await Cloud.respondInvitation(id,status);toast(status==="accepted"?"Invitation accepted":data.replacement?"Declined — SWARM found a replacement":"Invitation declined");
    await hydrateCloud();if(status==="accepted"){const invite=state.invitations.find(i=>i.id===id);if(invite){state.projectId=invite.projectId;state.tab="projects";state.stage="room";await loadCurrentRoom()}}render();
  }catch(err){toast(err?.message||"Could not respond to invitation")}
}

function render(){
  const view=$("#view");if(!view||!state.profile)return;
  const map={home,projects:projectsPage,discover:discovery,profile:profilePage};view.innerHTML=(map[state.tab]||home)();
  $$(".nav-item").forEach(b=>b.classList.toggle("active",b.dataset.tab===state.tab));bind();
  const unread=state.notifications.filter(n=>!n.read_at).length;$("#notifyBtn")?.classList.toggle("has-unread",unread>0);$("#notifyBtn")?.setAttribute("data-count",String(unread));
}
function bind(){
  $$("[data-tab]").forEach(b=>b.onclick=()=>setTab(b.dataset.tab));$$("[data-tab-jump]").forEach(b=>b.onclick=()=>setTab(b.dataset.tabJump));$(".avatar")?.addEventListener("click",()=>setTab("profile"));$("#notifyBtn")?.addEventListener("click",notificationsModal);
  $("#goalForm")?.addEventListener("submit",async e=>{e.preventDefault();const goal=$("#goalInput").value.trim();if(!goal)return;const btn=$("button",e.currentTarget);btn.disabled=true;btn.textContent="UNDERSTANDING GOAL…";
    try{let p=await AIService.parseGoal(goal);p=normalizeBlueprint(p,goal);p.creatorId=state.profile.id;p.status="blueprint";p.visibility="private";p=await Cloud.saveProject(p);upsert(state.projects,p);state.projectId=p.id;state.stage="blueprint";state.tab="projects";state.candidates=null;state.teams=null;render();toast(p.source==="ai"?"Blueprint generated with SWARM AI":"Blueprint generated with deterministic fallback")}catch(err){toast(err?.message||"Could not create project");btn.disabled=false;btn.textContent="BUILD BLUEPRINT ↗"}});
  $$("[data-example]").forEach(b=>b.onclick=()=>{const i=$("#goalInput");i.value=b.dataset.example;i.focus()});$$("[data-project]").forEach(b=>b.onclick=()=>openProject(b.dataset.project));$$("[data-open-invite-project]").forEach(b=>b.onclick=()=>openProject(b.dataset.openInviteProject));
  $("#backProjects")?.addEventListener("click",()=>{state.projectId=null;state.room=null;render()});
  $$("[data-stage]").forEach(b=>b.onclick=async()=>{state.stage=b.dataset.stage;if(state.stage==="room")await loadCurrentRoom();render()});$$("[data-stage-go]").forEach(b=>b.onclick=async()=>{state.stage=b.dataset.stageGo;if(state.stage==="room")await loadCurrentRoom();render()});
  $("#saveBlueprint")?.addEventListener("click",async()=>{const p=currentProject();try{const saved=await Cloud.saveProject(collectBlueprint(p));upsert(state.projects,saved);state.candidates=null;state.teams=null;render();toast("Blueprint synced to SWARM Cloud")}catch(err){toast(err?.message||"Could not save blueprint")}});
  $("#addRole")?.addEventListener("click",()=>{const list=$(".role-editor-list");list.insertAdjacentHTML("beforeend",`<article class="role-editor" data-role-editor data-type="optional" data-id="${tempId("role")}"><div class="role-editor-head"><select data-role-type><option value="required">REQUIRED</option><option value="optional" selected>OPTIONAL</option></select><button type="button" data-remove-role>REMOVE</button></div><label>ROLE<input data-role-title value="New Specialist"></label><label>SKILLS<input data-role-skills value=""></label><div class="two-col"><label>BUDGET CAP<input data-role-budget type="number"></label><label>HOURS<input data-role-hours type="number" value="24"></label></div><label>LANGUAGES<input data-role-languages value="English"></label></article>`);bindDynamicBlueprint()});
  $("#addMilestone")?.addEventListener("click",()=>{$("#milestoneEditors").insertAdjacentHTML("beforeend",`<div class="milestone-edit" data-ms-id="${tempId("ms")}"><input value="New milestone"><button type="button" data-remove-ms>×</button></div>`);bindDynamicBlueprint()});bindDynamicBlueprint();
  $("#runMatching")?.addEventListener("click",runMatchingLive);$$("[data-role-detail],[data-role-node]").forEach(b=>b.onclick=()=>roleModal(currentProject(),b.dataset.roleDetail||b.dataset.roleNode));$$("[data-profile-live]").forEach(b=>b.onclick=()=>profileModal(b.dataset.profileLive));
  $$("[data-build-team]").forEach(b=>b.onclick=async()=>{const p=currentProject(),team=(state.teams||[])[Number(b.dataset.buildTeam)];if(!team?.id)return toast("Team configuration is not persisted yet");try{await Cloud.formSwarm(team.id);graphMoment(p,team,async()=>{await hydrateCloud();state.stage="invites";render();toast("Real invitations created")})}catch(err){toast(err?.message||"Could not form Swarm")}});
  $$("[data-live-invite]").forEach(b=>b.onclick=()=>respondInvite(b.dataset.liveInvite,b.dataset.response));
  $$("[data-ms-check]").forEach(c=>c.onchange=async()=>{const p=currentProject();p.milestones=(p.milestones||[]).map(m=>m.id===c.dataset.msCheck?{...m,status:c.checked?"done":"todo"}:m);try{const saved=await Cloud.saveProject(p);upsert(state.projects,saved);render()}catch(err){toast(err?.message||"Could not update milestone")}});
  $("#addTask")?.addEventListener("click",taskModal);$$("[data-task-check]").forEach(c=>c.onchange=async()=>{try{await Cloud.updateTask(c.dataset.taskCheck,c.checked?"done":"todo");await loadCurrentRoom();render()}catch(err){toast(err?.message||"Could not update task")}});
  $("#addDecision")?.addEventListener("click",decisionModal);$("#messageForm")?.addEventListener("submit",async e=>{e.preventDefault();const text=$("#messageInput").value.trim();if(!text)return;try{await Cloud.addMessage(currentSwarm().id,text);$("#messageInput").value="";await loadCurrentRoom();render()}catch(err){toast(err?.message||"Could not post message")}});
  $("#fileUpload")?.addEventListener("change",async e=>{const file=e.target.files?.[0];if(!file)return;if(file.size>26214400)return toast("Files are limited to 25 MB");try{toast("Uploading "+file.name+"…");await Cloud.uploadProjectFile(currentProject().id,currentSwarm()?.id||null,file);await loadCurrentRoom();render();toast("File uploaded")}catch(err){toast(err?.message||"Upload failed")}});
  $$("[data-file-path]").forEach(b=>b.onclick=async()=>{try{const url=await Cloud.signedFileUrl(b.dataset.filePath);window.open(url,"_blank","noopener")}catch(err){toast(err?.message||"Could not open file")}});
  $("#runCoordinator")?.addEventListener("click",()=>coordinatorModal(currentProject()));$("#projectOutcome")?.addEventListener("click",()=>outcomeModal(currentProject()));
  $("#discoverySearch")?.addEventListener("input",filterDiscovery);$("#discoveryFilter")?.addEventListener("change",filterDiscovery);$("#shareSwarm")?.addEventListener("click",shareSwarm);
  $("#editProfile")?.addEventListener("click",editProfileModal);$("#installBtn")?.addEventListener("click",installApp);
  $("#signOut")?.addEventListener("click",async()=>{state.unsubscribeRealtime?.();await Cloud.signOut();state.session=null;state.profile=null;showAuth("signin","Signed out of SWARM Cloud.")});
}
function bindDynamicBlueprint(){$$("[data-remove-role]").forEach(b=>b.onclick=()=>b.closest("[data-role-editor]")?.remove());$$("[data-remove-ms]").forEach(b=>b.onclick=()=>b.closest("[data-ms-id]")?.remove())}
function filterDiscovery(){const q=($("#discoverySearch")?.value||"").toLowerCase(),f=($("#discoveryFilter")?.value||"").toLowerCase();$$(".person-card").forEach(card=>{const text=card.dataset.search||"";card.hidden=!!((q&&!text.includes(q))||(f&&!text.includes(f)))})}
async function shareSwarm(){const url=location.origin,title="Join SWARM — An LSMG System";try{if(navigator.share)await navigator.share({title,text:"Build a capability profile so SWARM can assemble real project teams.",url});else{await navigator.clipboard.writeText(url);toast("SWARM link copied")}}catch{}}
async function installApp(){if(state.deferredInstall){state.deferredInstall.prompt();await state.deferredInstall.userChoice;state.deferredInstall=null}else toast("Use your browser's Add to Home Screen option.")}
window.addEventListener("beforeinstallprompt",e=>{e.preventDefault();state.deferredInstall=e});window.addEventListener("appinstalled",()=>toast("SWARM installed"));
Cloud.onAuth((_event,session)=>{state.session=session;if(!session&&state.profile){state.profile=null;showAuth("signin")}});
showSplash();
if("serviceWorker" in navigator)navigator.serviceWorker.register("/sw.js",{updateViaCache:"none"}).then(r=>r.update()).catch(()=>{});