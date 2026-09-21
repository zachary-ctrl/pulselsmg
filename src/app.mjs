import {DEMO_PROFILES,DEMO_NOTICE} from "./demo-data.mjs";
import {Store,migratePulseSession,makeId} from "./store.mjs";
import {ProfileService,GoalService,BlueprintService,ProjectService,MatchingService,TeamOptimizer,InvitationService,SwarmService,TrustService,OutcomeService,AIService,NotificationService} from "./services.mjs";

const $=(s,r=document)=>r.querySelector(s);
const $$=(s,r=document)=>[...r.querySelectorAll(s)];
const esc=v=>String(v??"").replace(/[&<>'"]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"}[c]));
const money=v=>v==null||v===""?"—":new Intl.NumberFormat("en-US",{style:"currency",currency:"USD",maximumFractionDigits:0}).format(Number(v)||0);
const fmtDate=v=>{if(!v)return"—";const d=new Date(v+"T12:00:00");return Number.isFinite(d.getTime())?d.toLocaleDateString(undefined,{month:"short",day:"numeric",year:"numeric"}):v};
const score=v=>Math.round(Number(v||0)*100);
const initials=name=>String(name||"S").trim().split(/\s+/).slice(0,2).map(x=>x[0]||"").join("").toUpperCase()||"S";
const haptic=()=>{try{navigator.vibrate?.(7)}catch{}};

migratePulseSession();

const state={
  session:Store.getSession(),
  profile:null,
  tab:"home",
  projectId:null,
  stage:"blueprint",
  candidates:null,
  teams:null,
  teamIndex:0,
  toastTimer:null,
  deferredInstall:null
};

function toast(message){
  let el=$("#toast");if(!el){el=document.createElement("div");el.id="toast";el.className="toast";document.body.appendChild(el)}
  el.textContent=message;el.classList.add("show");clearTimeout(state.toastTimer);state.toastTimer=setTimeout(()=>el.classList.remove("show"),2400);
}
function currentProject(){return state.projectId?ProjectService.get(state.projectId):null}
function currentSwarm(){return state.projectId?SwarmService.getForProject(state.projectId):null}
function appInstalled(){return matchMedia("(display-mode: standalone)").matches||navigator.standalone===true}
function setTab(tab){state.tab=tab;render();window.scrollTo({top:0,behavior:"smooth"});haptic()}
function openProject(id,stage="blueprint"){state.projectId=id;state.stage=stage;state.tab="projects";state.candidates=null;state.teams=null;render();window.scrollTo({top:0,behavior:"smooth"})}

function showSplash(){
  const splash=$("#splash");
  if(!splash)return;
  setTimeout(()=>splash.classList.add("ready"),120);
  $("#enterSwarm")?.addEventListener("click",()=>{
    splash.classList.add("leaving");haptic();
    setTimeout(()=>{splash.remove();state.session?start():showAuth("create")},420);
  });
}
function bytesToB64(bytes){return btoa(String.fromCharCode(...bytes))}
function b64ToBytes(s){return Uint8Array.from(atob(s),c=>c.charCodeAt(0))}
async function passwordHash(password,salt){
  const base=await crypto.subtle.importKey("raw",new TextEncoder().encode(password),"PBKDF2",false,["deriveBits"]);
  const bits=await crypto.subtle.deriveBits({name:"PBKDF2",salt,iterations:120000,hash:"SHA-256"},base,256);
  return bytesToB64(new Uint8Array(bits));
}
function showAuth(mode="create"){
  $("#authLayer")?.remove();
  const create=mode==="create",wrap=document.createElement("div");wrap.id="authLayer";wrap.className="auth-layer";
  wrap.innerHTML=`<section class="auth-card">
    <div class="brand-kicker">AN LSMG SYSTEM</div><div class="auth-mark">SWARM<span>///</span></div>
    <p>Describe an outcome. SWARM calculates the human organization required to make it happen.</p>
    <div class="auth-tabs"><button data-auth="create" class="${create?"active":""}">CREATE</button><button data-auth="signin" class="${!create?"active":""}">SIGN IN</button></div>
    <form id="authForm">${create?'<label>NAME<input id="authName" required autocomplete="name" placeholder="Your name"></label>':""}
      <label>EMAIL<input id="authEmail" required type="email" autocomplete="email" placeholder="you@example.com"></label>
      <label>PASSWORD<input id="authPass" required type="password" minlength="6" placeholder="6+ characters"></label>
      <button class="primary-btn">${create?"CREATE DEVICE ACCOUNT":"SIGN IN"}</button>
    </form>
    <p class="auth-note">This MVP keeps accounts on this device. Cloud identity is intentionally not faked; the production database/auth migration is prepared separately.</p>
    <button class="text-action" id="guestBtn">CONTINUE AS GUEST</button>
  </section>`;
  document.body.appendChild(wrap);
  $$("[data-auth]",wrap).forEach(b=>b.onclick=()=>showAuth(b.dataset.auth));
  $("#guestBtn",wrap).onclick=()=>{state.session={name:"Guest",email:"guest@local",deviceOnly:true};Store.setSession(state.session);wrap.remove();start()};
  $("#authForm",wrap).onsubmit=async e=>{
    e.preventDefault();const email=$("#authEmail",wrap).value.trim().toLowerCase(),pass=$("#authPass",wrap).value,accounts=Store.getAccounts();
    if(create){
      if(accounts[email])return toast("Account already exists on this device");
      const salt=crypto.getRandomValues(new Uint8Array(16)),name=$("#authName",wrap).value.trim();
      accounts[email]={name,email,salt:bytesToB64(salt),hash:await passwordHash(pass,salt),createdAt:new Date().toISOString()};
      Store.setAccounts(accounts);state.session={name,email,deviceOnly:true};Store.setSession(state.session);
    }else{
      const acct=accounts[email];if(!acct)return toast("Account not found on this device");
      if(await passwordHash(pass,b64ToBytes(acct.salt))!==acct.hash)return toast("Password does not match");
      state.session={name:acct.name,email,deviceOnly:true};Store.setSession(state.session);
    }
    wrap.remove();start();
  };
}
function start(){
  state.profile=ProfileService.ensure(state.session);
  $(".avatar").textContent=initials(state.profile.name);
  render();
}

function graphMoment(project,team,done){
  const overlay=document.createElement("div");overlay.className="formation-overlay";
  const members=[...new Set(team.assignments.map(a=>a.profileName))];
  overlay.innerHTML=`<div class="formation-scene"><div class="formation-label">SWARM MATCH ENGINE / FORMATION</div><div class="formation-nodes">
    ${members.slice(0,7).map((m,i)=>`<i style="--i:${i};--n:${members.length}" title="${esc(m)}"></i>`).join("")}
    <b></b></div><h2>FORMING YOUR SWARM</h2><p>${esc(project.title)}</p></div>`;
  document.body.appendChild(overlay);
  setTimeout(()=>overlay.classList.add("converge"),350);
  setTimeout(()=>{$(".formation-scene h2",overlay).textContent="YOUR SWARM IS READY";overlay.classList.add("ready")},1800);
  setTimeout(()=>{overlay.classList.add("leave");setTimeout(()=>{overlay.remove();done?.()},320)},3000);
}

function home(){
  const projects=ProjectService.list().slice(0,4),active=Store.getSwarms().filter(s=>s.status==="active").length;
  return `<section class="hero">
    <div class="hero-ambient"><i></i><i></i><i></i><i></i><i></i></div>
    <div class="eyebrow">SWARM / GOAL-TO-ORGANIZATION ENGINE</div>
    <h1>WHAT ARE YOU TRYING TO <em>MAKE HAPPEN?</em></h1>
    <p>You describe the outcome. SWARM decomposes the work, identifies roles, scores real constraints, and assembles viable teams.</p>
    <form class="goal-composer" id="goalForm">
      <textarea id="goalInput" required minlength="8" placeholder="I want to launch a streetwear brand in Dallas within 45 days with a $5,000 budget."></textarea>
      <div><span>Natural language → structured blueprint</span><button class="primary-btn">BUILD BLUEPRINT <b>↗</b></button></div>
    </form>
    <div class="goal-examples">${["Build an iOS fitness app","Launch a clothing brand","Shoot a short film","Start a podcast","Organize a 300-person event","Launch a food truck"].map(x=>`<button data-example="${esc(x)}">${esc(x)}</button>`).join("")}</div>
  </section>
  <section class="system-strip"><div><b>${projects.length}</b><span>PROJECTS</span></div><div><b>${active}</b><span>ACTIVE SWARMS</span></div><div><b>8</b><span>MATCH SIGNALS</span></div><div><b>0</b><span>FAKE SCORES</span></div></section>
  <div class="section-head"><div><small>YOUR WORK</small><h2>PROJECTS IN MOTION</h2></div><button data-tab-jump="projects">VIEW ALL</button></div>
  ${projects.length?`<div class="project-grid">${projects.map(projectCard).join("")}</div>`:`<div class="empty-state"><div class="network-mini"></div><b>NO PROJECTS YET</b><p>Your first goal becomes the first Project Blueprint.</p></div>`}
  <section class="principle-card"><span>THE CORE LOOP</span><div>GOAL <b>→</b> UNDERSTAND <b>→</b> ROLES <b>→</b> MATCH <b>→</b> TEAM <b>→</b> EXECUTE <b>→</b> LEARN</div></section>`;
}
function projectCard(p){
  const swarm=SwarmService.getForProject(p.id);
  return `<button class="project-card" data-project="${p.id}">
    <div class="project-card-top"><span>${esc(p.category)}</span><i class="status ${swarm?.status||p.status}">${esc(swarm?.status||p.status)}</i></div>
    <h3>${esc(p.title)}</h3><p>${esc(p.objective)}</p>
    <div class="project-card-meta"><span>${fmtDate(p.deadline)}</span><span>${p.budgetMax?money(p.budgetMax):"BUDGET OPEN"}</span><span>${(p.requiredRoles||[]).length} CORE ROLES</span></div>
  </button>`;
}
function projectsPage(){
  const p=currentProject();
  if(!p){
    const list=ProjectService.list();
    return `<div class="page-title"><small>YOUR WORK</small><h1>PROJECTS.</h1><p>Every goal becomes a structured system of roles, resources, constraints, and outcomes.</p></div>
      ${list.length?`<div class="project-grid">${list.map(projectCard).join("")}</div>`:`<div class="empty-state"><b>NOTHING TO ASSEMBLE YET</b><p>Start with a goal on Home.</p><button class="primary-btn" data-tab-jump="home">CREATE A GOAL</button></div>`}`;
  }
  return `<div class="project-shell">
    <header class="project-header"><button class="back-link" id="backProjects">← ALL PROJECTS</button><div><small>${esc(p.category)}</small><h1>${esc(p.title)}</h1></div><span class="status ${esc(p.status)}">${esc(p.status)}</span></header>
    <nav class="project-nav">
      ${[["blueprint","BLUEPRINT"],["roles","ROLE MAP"],["matches","MATCH LAB"],["teams","ASSEMBLY"],["invites","INVITES"],["room","SWARM ROOM"]].map(([k,l])=>`<button data-stage="${k}" class="${state.stage===k?"active":""}">${l}</button>`).join("")}
    </nav>
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
  const all=[...(p.requiredRoles||[]).map(r=>({...r,_type:"required"})),...(p.optionalRoles||[]).map(r=>({...r,_type:"optional"}))];
  return `<div class="stage-heading"><div><small>AI PROPOSES · YOU CONTROL</small><h2>PROJECT BLUEPRINT</h2></div><button class="outline-btn" id="saveBlueprint">SAVE CHANGES</button></div>
  <form class="blueprint-form" id="blueprintForm">
    <div class="field-grid">
      <label>TITLE<input name="title" value="${esc(p.title)}"></label>
      <label>CATEGORY<input name="category" value="${esc(p.category)}"></label>
      <label class="span-2">OBJECTIVE<textarea name="objective">${esc(p.objective)}</textarea></label>
      <label>LOCATION<input name="location" value="${esc(p.location)}"></label>
      <label>REMOTE ALLOWED<select name="remoteAllowed"><option value="true" ${p.remoteAllowed?"selected":""}>YES</option><option value="false" ${!p.remoteAllowed?"selected":""}>NO</option></select></label>
      <label>BUDGET MIN<input name="budgetMin" type="number" value="${p.budgetMin??""}"></label>
      <label>BUDGET MAX<input name="budgetMax" type="number" value="${p.budgetMax??""}"></label>
      <label>START DATE<input name="startDate" type="date" value="${esc(p.startDate)}"></label>
      <label>DEADLINE<input name="deadline" type="date" value="${esc(p.deadline)}"></label>
      <label>TEAM SIZE MIN<input name="teamSizeMin" type="number" value="${p.teamSizeMin??""}"></label>
      <label>TEAM SIZE MAX<input name="teamSizeMax" type="number" value="${p.teamSizeMax??""}"></label>
    </div>
    <div class="blueprint-section"><div class="subhead"><b>ROLE REQUIREMENTS</b><button type="button" id="addRole">+ ADD ROLE</button></div>
      <div class="role-editor-list">${all.map((r,i)=>`<article class="role-editor" data-role-editor data-type="${r._type}" data-id="${r.id}">
        <div class="role-editor-head"><select data-role-type><option value="required" ${r._type==="required"?"selected":""}>REQUIRED</option><option value="optional" ${r._type==="optional"?"selected":""}>OPTIONAL</option></select><button type="button" data-remove-role>REMOVE</button></div>
        <label>ROLE<input data-role-title value="${esc(r.title)}"></label>
        <label>SKILLS<input data-role-skills value="${esc((r.skills||[]).map(s=>s.name).join(", "))}"></label>
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
  </form>
  <div class="stage-actions"><button class="primary-btn" data-stage-go="roles">VIEW ROLE MAP →</button></div>`;
}
function roleMap(p){
  const roles=[...(p.requiredRoles||[]),...(p.optionalRoles||[])],n=Math.max(roles.length,1),cx=300,cy=230,r=165;
  const nodes=roles.map((role,i)=>{const a=(-Math.PI/2)+(i/n)*Math.PI*2,x=cx+Math.cos(a)*r,y=cy+Math.sin(a)*r;return {role,x,y}});
  const svg=`<svg viewBox="0 0 600 460" class="role-graph" aria-label="Project role graph">
    <defs><filter id="glow"><feGaussianBlur stdDeviation="4" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
    ${nodes.map(n=>`<line x1="${cx}" y1="${cy}" x2="${n.x}" y2="${n.y}"/>`).join("")}
    <g class="center-node"><circle cx="${cx}" cy="${cy}" r="65"/><text x="${cx}" y="${cy-6}" text-anchor="middle">PROJECT</text><text x="${cx}" y="${cy+13}" text-anchor="middle" class="small">${esc(p.category.slice(0,18))}</text></g>
    ${nodes.map(n=>`<g class="role-node ${n.role.required?"required":"optional"}" data-role-node="${n.role.id}"><circle cx="${n.x}" cy="${n.y}" r="47"/><text x="${n.x}" y="${n.y-3}" text-anchor="middle">${esc(n.role.title.split(" ").slice(0,2).join(" "))}</text><text x="${n.x}" y="${n.y+13}" text-anchor="middle" class="small">${n.role.required?"CORE":"OPTIONAL"}</text></g>`).join("")}
  </svg>`;
  return `<div class="stage-heading"><div><small>ORGANIZATION MODEL</small><h2>ROLE MAP</h2></div><span>${roles.length} NODES</span></div>
  <div class="graph-card">${svg}</div>
  <div class="role-map-list">${roles.map(r=>`<button data-role-detail="${r.id}"><span class="role-dot ${r.required?"":"optional"}"></span><div><b>${esc(r.title)}</b><small>${esc((r.skills||[]).map(s=>s.name).join(" · "))}</small></div><em>${r.required?"REQUIRED":"OPTIONAL"}</em></button>`).join("")}</div>
  <div class="stage-actions"><button class="outline-btn" data-stage-go="blueprint">EDIT BLUEPRINT</button><button class="primary-btn" id="runMatching">RUN MATCH ENGINE →</button></div>`;
}
function ensureMatches(p){
  if(!state.candidates){MatchingService.start(p);state.candidates=MatchingService.candidates(p,DEMO_PROFILES);MatchingService.complete(p,state.candidates)}
  return state.candidates;
}
function matchLab(p){
  const cand=ensureMatches(p);
  return `<div class="demo-banner"><b>DEVELOPMENT NETWORK</b><span>${esc(DEMO_NOTICE)}</span></div>
  <div class="stage-heading"><div><small>SWARM MATCH ENGINE</small><h2>MATCH LAB</h2></div><span>DETERMINISTIC / EXPLAINABLE</span></div>
  <div class="match-role-stack">${(p.requiredRoles||[]).map(role=>{
    const list=(cand[role.id]||[]).slice(0,4);
    return `<section class="match-role"><header><div><small>ROLE</small><h3>${esc(role.title)}</h3></div><span>${list.length} ELIGIBLE</span></header>
      ${list.length?list.map((item,i)=>candidateCard(item,role,i)).join(""):`<div class="no-match"><b>NO ELIGIBLE CANDIDATES</b><p>Adjust role skills, location, availability, or budget constraints.</p></div>`}
    </section>`}).join("")}</div>
    <div class="stage-actions"><button class="outline-btn" data-stage-go="roles">BACK TO ROLE MAP</button><button class="primary-btn" id="buildTeams">OPTIMIZE TEAMS →</button></div>`;
}
function candidateCard(item,role,i){
  const p=item.profile,m=item.match;
  return `<article class="candidate-card">
    <div class="candidate-rank">${String(i+1).padStart(2,"0")}</div>
    <div class="candidate-main"><div class="candidate-title"><div><h4>${esc(p.name)}</h4><span>${esc(p.location.city)}, ${esc(p.location.state)} · ${money(m.estimatedCost)} EST.</span></div><strong>${m.percent}%</strong></div>
      <div class="score-bars">${Object.entries(m.breakdown).map(([k,v])=>`<div><span>${esc(k.replace(/([A-Z])/g," $1").toUpperCase())}</span><i><b style="width:${score(v)}%"></b></i><em>${score(v)}</em></div>`).join("")}</div>
      <div class="match-reasons"><div><small>STRONGEST REASONS</small>${m.reasons.slice(0,3).map(x=>`<span>✓ ${esc(x)}</span>`).join("")||"<span>Structured fit across the required signals</span>"}</div>
      ${m.concerns.length?`<div class="concerns"><small>POSSIBLE CONCERNS</small>${m.concerns.map(x=>`<span>△ ${esc(x)}</span>`).join("")}</div>`:""}</div>
      <button class="text-action" data-profile-demo="${p.id}">VIEW PROOF + TRUST SIGNALS →</button>
    </div>
  </article>`;
}
function ensureTeams(p){
  if(!state.teams)state.teams=TeamOptimizer.options(p,DEMO_PROFILES);
  return state.teams;
}
function teamAssembly(p){
  const teams=ensureTeams(p);
  if(!teams.length)return `<div class="stage-heading"><div><small>TEAM OPTIMIZER</small><h2>NO VIABLE SWARM YET</h2></div></div><div class="no-match"><p>The current hard constraints and budget produced no complete team. Edit the blueprint instead of showing a fake result.</p><button class="primary-btn" data-stage-go="blueprint">EDIT CONSTRAINTS</button></div>`;
  return `<div class="demo-banner"><b>DEVELOPMENT NETWORK</b><span>These team configurations use clearly labeled seed profiles to validate SWARM's optimization engine.</span></div>
  <div class="stage-heading"><div><small>WHOLE-TEAM OPTIMIZATION</small><h2>TEAM ASSEMBLY</h2></div><span>${teams.length} DISTINCT OPTIONS</span></div>
  <div class="team-options">${teams.map((team,i)=>teamCard(team,i,p)).join("")}</div>`;
}
function teamCard(team,i,p){
  const m=team.metrics,profiles=new Map(DEMO_PROFILES.map(x=>[x.id,x]));
  return `<article class="team-card ${i===0?"featured":""}">
    <header><div><small>${esc(team.label)}</small><h3>${m.percent}% TEAM FIT</h3></div><button class="primary-btn" data-build-team="${i}">BUILD THIS SWARM</button></header>
    <div class="team-metrics"><div><b>${m.memberCount}</b><span>MEMBERS</span></div><div><b>${money(m.totalBudget)}</b><span>PROJECTED COST</span></div><div><b>${Math.round(m.roleCoverage*100)}%</b><span>ROLE COVERAGE</span></div><div><b>${Math.round(m.scheduleCompatibility*100)}%</b><span>SCHEDULE</span></div></div>
    <div class="team-members">${team.assignments.map(a=>{const pr=profiles.get(a.profileId);return `<div><span class="member-avatar">${initials(a.profileName)}</span><div><b>${esc(a.profileName)}</b><small>${esc(a.roleTitle)} · ${a.match.percent}% role fit</small></div><em>${money(a.incrementalCost)}</em></div>`}).join("")}</div>
    <div class="team-score-grid">${[["PAIRWISE",m.pairwiseCompatibility],["RELIABILITY",m.reliability],["BUDGET",m.budgetCompatibility],["SKILL COMPLEMENT",m.skillComplementarity],["PRIOR TEAM SIGNAL",m.priorTeamSuccess]].map(([l,v])=>`<span><b>${Math.round(v*100)}%</b><small>${l}</small></span>`).join("")}</div>
  </article>`;
}
function invitationsView(p){
  const swarm=currentSwarm(),invites=InvitationService.list(p.id);
  if(!swarm)return `<div class="empty-state"><b>NO SWARM SELECTED</b><p>Choose a team configuration before sending invitations.</p><button class="primary-btn" data-stage-go="teams">OPEN ASSEMBLY</button></div>`;
  return `<div class="demo-banner"><b>SIMULATION MODE</b><span>Seed profiles are not real users, so Accept/Decline below is an explicit development simulation—not a fake notification system.</span></div>
  <div class="stage-heading"><div><small>FORMATION STATUS</small><h2>INVITATIONS</h2></div><span>${esc(swarm.status)}</span></div>
  <div class="invite-stack">${invites.map(i=>`<article class="invite-card"><div><span class="member-avatar">${initials(i.profileName)}</span><div><b>${esc(i.profileName)}</b><small>${esc(i.roleTitle)} · ${i.matchPercent}% MATCH · ${money(i.estimatedCompensation)}</small></div></div><em class="invite-status ${i.status}">${i.status}</em>
  <p>${esc((i.whyMatched||[]).slice(0,2).join(" · "))}</p>
  ${i.status==="pending"?`<div class="invite-actions"><button data-invite="${i.id}" data-response="accepted">SIMULATE ACCEPT</button><button data-invite="${i.id}" data-response="declined">SIMULATE DECLINE</button></div>`:""}</article>`).join("")}</div>
  <div class="stage-actions"><button class="primary-btn" data-stage-go="room">OPEN SWARM ROOM →</button></div>`;
}
function roomView(p){
  let swarm=currentSwarm();if(!swarm)return `<div class="empty-state"><b>SWARM ROOM LOCKED</b><p>Build a team first.</p><button class="primary-btn" data-stage-go="teams">ASSEMBLE TEAM</button></div>`;
  swarm=SwarmService.syncMembers(swarm);
  const resources=p.resourcesNeeded||[];
  return `<div class="room-head"><div><small>SWARM ROOM / ${esc(swarm.status)}</small><h2>${esc(p.title)}</h2></div><button class="coordinator-btn" id="runCoordinator">ASK COORDINATOR ✦</button></div>
  <div class="room-grid">
    <section class="room-card span-2"><header><b>TEAM</b><span>${swarm.members.length}/${swarm.assignments.length} ACCEPTED</span></header><div class="room-members">${swarm.assignments.map(a=>{const joined=swarm.members.some(m=>m.profileId===a.profileId&&m.roleId===a.roleId);return `<div><span class="member-avatar">${initials(a.profileName)}</span><div><b>${esc(a.profileName)}</b><small>${esc(a.roleTitle)}</small></div><em class="${joined?"on":""}">${joined?"IN":"PENDING"}</em></div>`}).join("")}</div></section>
    <section class="room-card"><header><b>MILESTONES</b><span>${(p.milestones||[]).filter(m=>m.status==="done").length}/${(p.milestones||[]).length}</span></header><div class="check-list">${(p.milestones||[]).map(m=>`<label><input type="checkbox" data-ms-check="${m.id}" ${m.status==="done"?"checked":""}><span>${esc(m.title)}</span></label>`).join("")}</div></section>
    <section class="room-card"><header><b>RESOURCES</b><span>${resources.length}</span></header><div class="resource-list">${resources.map(x=>`<span>${esc(x)}</span>`).join("")}</div></section>
    <section class="room-card"><header><b>TASK BOARD</b><button id="addTask">+ TASK</button></header><div class="task-list">${(swarm.tasks||[]).map(t=>`<label><input type="checkbox" data-task-check="${t.id}" ${t.status==="done"?"checked":""}><span>${esc(t.title)}</span><small>${t.dueDate?fmtDate(t.dueDate):""}</small></label>`).join("")||"<p>No tasks yet.</p>"}</div></section>
    <section class="room-card"><header><b>DECISION LOG</b><button id="addDecision">+ DECISION</button></header><div class="decision-list">${(swarm.decisions||[]).slice().reverse().map(d=>`<div><span>${new Date(d.createdAt).toLocaleDateString()}</span><p>${esc(d.text)}</p></div>`).join("")||"<p>No decisions logged.</p>"}</div></section>
    <section class="room-card span-2"><header><b>PROJECT CHAT</b><span>LOCAL MVP</span></header><div class="chat-log">${(swarm.messages||[]).map(m=>`<div><b>${esc(m.sender)}</b><p>${esc(m.text)}</p></div>`).join("")||"<p>No messages yet.</p>"}</div><form id="messageForm" class="room-composer"><input id="messageInput" placeholder="Post an update to the room…" required><button>POST</button></form></section>
  </div>
  <div class="stage-actions"><button class="outline-btn" id="projectOutcome">COMPLETE / RECORD OUTCOME</button></div>`;
}
function discovery(){
  return `<div class="page-title"><small>SECONDARY MODE</small><h1>DISCOVERY.</h1><p>Explore capabilities, skills, and public opportunity structures without turning SWARM into a people directory.</p></div>
    <div class="demo-banner"><b>DEVELOPMENT NETWORK</b><span>${esc(DEMO_NOTICE)}</span></div>
    <div class="discovery-tools"><input id="discoverySearch" placeholder="Search skills, roles, industries…"><select id="discoveryFilter"><option value="">ALL CAPABILITIES</option><option>Technology</option><option>Fashion</option><option>Film</option><option>Events</option><option>Music</option><option>Food</option></select></div>
    <div class="people-grid" id="peopleGrid">${DEMO_PROFILES.map(discoveryCard).join("")}</div>`;
}
function discoveryCard(p){
  return `<button class="person-card" data-profile-demo="${p.id}" data-search="${esc([p.name,p.bio,...p.industries,...p.desiredRoles,...p.skills.map(s=>s[0])].join(" ").toLowerCase())}">
    <div><span class="member-avatar">${initials(p.name)}</span><em>DEMO</em></div><h3>${esc(p.name)}</h3><p>${esc(p.bio)}</p><div class="chips">${p.skills.slice(0,4).map(s=>`<span>${esc(s[0])}</span>`).join("")}</div><small>${esc(p.location.city)}, ${esc(p.location.state)} · ${p.remoteAllowed?"REMOTE OK":"LOCAL"}</small>
  </button>`;
}
function profilePage(){
  const p=state.profile,trust=TrustService.signals(p);
  return `<div class="page-title profile-title"><div><small>LIVE CAPABILITY PROFILE</small><h1>YOU.</h1></div><button class="outline-btn" id="editProfile">EDIT PROFILE</button></div>
  <section class="profile-hero"><div class="profile-big-avatar">${initials(p.name)}</div><div><h2>${esc(p.name)}</h2><p>${esc(p.bio||"Add what you can help with and what you are building.")}</p><span>${esc([p.location.city,p.location.state].filter(Boolean).join(", ")||"LOCATION PRIVATE")}</span></div></section>
  <div class="capability-grid"><section><small>I CAN HELP WITH</small><div class="chips">${(p.skills||[]).length?p.skills.map(s=>`<span>${esc(Array.isArray(s)?s[0]:s.name)}</span>`).join(""):"<span>ADD SKILLS</span>"}</div></section><section><small>WHAT I'M BUILDING</small><div class="chips">${(p.goals||[]).length?p.goals.map(x=>`<span>${esc(x)}</span>`).join(""):"<span>ADD GOALS</span>"}</div></section></div>
  <div class="section-head"><div><small>TRUST</small><h2>VISIBLE SIGNALS, NOT A SOCIAL SCORE</h2></div></div>
  <div class="trust-grid">${trust.map(s=>`<div><b>${s.value===true?"VERIFIED":s.value===false?"NOT VERIFIED":s.value??"NO DATA"}</b><span>${esc(s.label)}</span></div>`).join("")}</div>
  <div class="section-head"><div><small>PRIVACY</small><h2>YOU CONTROL WHAT IS SHARED</h2></div></div>
  <div class="privacy-card"><span>Profile visibility <b>${esc(p.visibility||"private")}</b></span><span>Exact location <b>HIDDEN</b></span><span>Rates <b>${p.hourlyRate||p.projectRate?"PROFILE ONLY":"HIDDEN"}</b></span><span>Contact information <b>PRIVATE</b></span></div>
  <div class="account-actions">${!appInstalled()?'<button id="installBtn">INSTALL SWARM</button>':""}<button id="signOut">SIGN OUT</button></div>`;
}
function notificationsModal(){
  const notes=NotificationService.list();
  openModal(`<div class="modal-head"><div><small>SWARM SYSTEM</small><h2>NOTIFICATIONS</h2></div><button data-close>×</button></div><div class="notification-list">${notes.length?notes.map(n=>`<div><b>${esc(n.title)}</b><p>${esc(n.body)}</p><small>${new Date(n.createdAt).toLocaleString()}</small></div>`).join(""):"<p>No notifications yet.</p>"}</div>`);
}
function profileModal(id){
  const p=DEMO_PROFILES.find(x=>x.id===id);if(!p)return;const trust=TrustService.signals(p);
  openModal(`<div class="modal-head"><div><small>DEMO CAPABILITY PROFILE</small><h2>${esc(p.name)}</h2></div><button data-close>×</button></div>
  <div class="demo-banner compact"><b>SEED DATA</b><span>Not a real SWARM member.</span></div><p class="modal-lead">${esc(p.bio)}</p>
  <div class="chips">${p.skills.map(s=>`<span>${esc(s[0])} · ${Math.round(s[1]*100)}%</span>`).join("")}</div>
  <div class="proof-grid"><div><b>${p.projectsCompleted}</b><span>PROJECTS</span></div><div><b>${Math.round(p.completionRate*100)}%</b><span>COMPLETION</span></div><div><b>${Math.round(p.responseRate*100)}%</b><span>RESPONSE</span></div><div><b>${p.peerRatings}</b><span>PEER RATING</span></div></div>
  <div class="trust-list">${trust.map(s=>`<span><b>${esc(s.label)}</b><em>${s.value===true?"YES":s.value===false?"NO":esc(s.value??"NO DATA")}</em></span>`).join("")}</div>`);
}
function roleModal(p,id){
  const r=[...(p.requiredRoles||[]),...(p.optionalRoles||[])].find(x=>x.id===id);if(!r)return;
  openModal(`<div class="modal-head"><div><small>${r.required?"REQUIRED ROLE":"OPTIONAL ROLE"}</small><h2>${esc(r.title)}</h2></div><button data-close>×</button></div><div class="modal-section"><small>SKILLS</small><div class="chips">${(r.skills||[]).map(s=>`<span>${esc(s.name)}</span>`).join("")}</div></div><div class="proof-grid"><div><b>${money(r.budgetCap)}</b><span>BUDGET CAP</span></div><div><b>${r.estimatedHours||24}</b><span>EST. HOURS</span></div></div>`);
}
function openModal(html){
  const dlg=$("#modal");$("#modalCard").innerHTML=html;dlg.showModal();$$("[data-close]",dlg).forEach(b=>b.onclick=()=>dlg.close());
}
function editProfileModal(){
  const p=state.profile;
  openModal(`<div class="modal-head"><div><small>CAPABILITY PROFILE</small><h2>EDIT PROFILE</h2></div><button data-close>×</button></div>
    <form id="profileForm" class="modal-form">
      <label>NAME<input name="name" value="${esc(p.name)}" required></label>
      <label>BIO<textarea name="bio">${esc(p.bio||"")}</textarea></label>
      <label>SKILLS <small>comma separated</small><input name="skills" value="${esc((p.skills||[]).map(s=>Array.isArray(s)?s[0]:s.name).join(", "))}"></label>
      <label>DESIRED ROLES<input name="desiredRoles" value="${esc((p.desiredRoles||[]).join(", "))}"></label>
      <div class="two-col"><label>CITY<input name="city" value="${esc(p.location.city||"")}"></label><label>STATE<input name="state" value="${esc(p.location.state||"")}"></label></div>
      <div class="two-col"><label>HOURLY RATE<input name="hourlyRate" type="number" value="${p.hourlyRate||""}"></label><label>PROJECT RATE<input name="projectRate" type="number" value="${p.projectRate||""}"></label></div>
      <label>GOALS<input name="goals" value="${esc((p.goals||[]).join(", "))}"></label>
      <label>WORKING STYLE<input name="workingStyle" value="${esc((p.workingStyle||[]).join(", "))}"></label>
      <label>VISIBILITY<select name="visibility"><option value="private" ${p.visibility==="private"?"selected":""}>PRIVATE</option><option value="public" ${p.visibility==="public"?"selected":""}>PUBLIC</option></select></label>
      <button class="primary-btn">SAVE PROFILE</button>
    </form>`);
  $("#profileForm").onsubmit=e=>{
    e.preventDefault();const f=new FormData(e.currentTarget),split=k=>String(f.get(k)||"").split(",").map(x=>x.trim()).filter(Boolean);
    const next={...p,name:String(f.get("name")),bio:String(f.get("bio")||""),skills:split("skills").map(x=>[x,.5,false]),desiredRoles:split("desiredRoles"),location:{...p.location,city:String(f.get("city")||""),state:String(f.get("state")||"")},hourlyRate:Number(f.get("hourlyRate")||0),projectRate:Number(f.get("projectRate")||0),goals:split("goals"),workingStyle:split("workingStyle"),visibility:String(f.get("visibility")||"private")};
    state.profile=ProfileService.save(next);$(".avatar").textContent=initials(next.name);$("#modal").close();render();toast("Profile updated");
  };
}
function taskModal(){
  openModal(`<div class="modal-head"><div><small>SWARM ROOM</small><h2>NEW TASK</h2></div><button data-close>×</button></div><form id="taskForm" class="modal-form"><label>TASK<input name="title" required></label><label>DUE DATE<input name="due" type="date"></label><button class="primary-btn">CREATE TASK</button></form>`);
  $("#taskForm").onsubmit=e=>{e.preventDefault();const f=new FormData(e.currentTarget),s=currentSwarm();SwarmService.addTask(s,String(f.get("title")),null,String(f.get("due")||"")||null);$("#modal").close();render();toast("Task created")};
}
function decisionModal(){
  openModal(`<div class="modal-head"><div><small>SWARM ROOM</small><h2>LOG DECISION</h2></div><button data-close>×</button></div><form id="decisionForm" class="modal-form"><label>DECISION<textarea name="text" required></textarea></label><button class="primary-btn">LOG DECISION</button></form>`);
  $("#decisionForm").onsubmit=e=>{e.preventDefault();const s=currentSwarm();SwarmService.addDecision(s,String(new FormData(e.currentTarget).get("text")));$("#modal").close();render();toast("Decision logged")};
}
function outcomeModal(p){
  openModal(`<div class="modal-head"><div><small>OUTCOME LEARNING</small><h2>PROJECT OUTCOME</h2></div><button data-close>×</button></div><form id="outcomeForm" class="modal-form">
    <label>PROJECT FINISHED?<select name="finished"><option value="true">YES</option><option value="false">NO</option></select></label>
    <label>ON TIME?<select name="onTime"><option value="true">YES</option><option value="false">NO</option></select></label>
    <label>ON BUDGET?<select name="onBudget"><option value="true">YES</option><option value="false">NO</option></select></label>
    <label>SATISFACTION 1–5<input name="satisfaction" type="number" min="1" max="5" value="5"></label>
    <label>WHAT WAS PRODUCED?<textarea name="produced"></textarea></label>
    <button class="primary-btn">RECORD OUTCOME</button></form>`);
  $("#outcomeForm").onsubmit=e=>{e.preventDefault();const f=new FormData(e.currentTarget),b=k=>f.get(k)==="true";OutcomeService.complete(p,currentSwarm(),{finished:b("finished"),onTime:b("onTime"),onBudget:b("onBudget"),creatorSatisfied:Number(f.get("satisfaction")),produced:String(f.get("produced")||"")});$("#modal").close();render();toast("Outcome recorded")};
}
async function coordinatorModal(p){
  openModal(`<div class="modal-head"><div><small>AI COORDINATOR</small><h2>PROJECT CHECK</h2></div><button data-close>×</button></div><div class="ai-wait"><i></i><p>Analyzing blueprint, milestones, tasks, team status, and budget…</p></div>`);
  const result=await AIService.coordinate(p,currentSwarm());$("#modalCard").innerHTML=`<div class="modal-head"><div><small>AI COORDINATOR · ${esc(result.source)}</small><h2>PROJECT CHECK</h2></div><button data-close>×</button></div><div class="coordinator-report"><p>${esc(result.text)}</p><small>SWARM AI can identify risk and options. It does not send invitations, move money, contact people, or make irreversible decisions without your approval.</small></div>`;$$("[data-close]",$("#modal")).forEach(b=>b.onclick=()=>$("#modal").close());
}

function render(){
  const view=$("#view");if(!view)return;
  const map={home,projects:projectsPage,discover:discovery,profile:profilePage};
  view.innerHTML=(map[state.tab]||home)();
  $$(".nav-item").forEach(b=>b.classList.toggle("active",b.dataset.tab===state.tab));
  bind();
}
function collectBlueprint(p){
  const form=$("#blueprintForm"),f=new FormData(form);
  const req=[],opt=[];
  $$("[data-role-editor]",form).forEach(el=>{
    const required=$("[data-role-type]",el)?.value==="required";const role={id:el.dataset.id||makeId("role"),title:$("[data-role-title]",el).value.trim()||"Specialist",skills:$("[data-role-skills]",el).value.split(",").map(x=>x.trim()).filter(Boolean).map(name=>({name,required:true,weight:1})),budgetCap:Number($("[data-role-budget]",el).value||0)||null,estimatedHours:Number($("[data-role-hours]",el).value||24),requiredLanguages:$("[data-role-languages]",el).value.split(",").map(x=>x.trim()).filter(Boolean),certifications:[],notes:"",required};
    (role.required?req:opt).push(role);
  });
  const milestones=$$("[data-ms-id]",form).map((el,i)=>({id:el.dataset.msId||makeId("ms"),title:$("input",el).value.trim()||"Milestone",status:(p.milestones||[]).find(m=>m.id===el.dataset.msId)?.status||"todo",order:i+1,dueDate:null}));
  return {title:String(f.get("title")),category:String(f.get("category")),objective:String(f.get("objective")),location:String(f.get("location")),remoteAllowed:f.get("remoteAllowed")==="true",budgetMin:Number(f.get("budgetMin")||0)||null,budgetMax:Number(f.get("budgetMax")||0)||null,startDate:String(f.get("startDate")),deadline:String(f.get("deadline")),teamSizeMin:Number(f.get("teamSizeMin")||0)||null,teamSizeMax:Number(f.get("teamSizeMax")||0)||null,requiredRoles:req,optionalRoles:opt,resourcesNeeded:String(f.get("resourcesNeeded")||"").split("\n").map(x=>x.trim()).filter(Boolean),constraints:String(f.get("constraints")||"").split("\n").map(x=>x.trim()).filter(Boolean),preferredWorkingStyle:String(f.get("preferredWorkingStyle")||"").split(",").map(x=>x.trim()).filter(Boolean),preferredExperience:String(f.get("preferredExperience")||"").split(",").map(x=>x.trim()).filter(Boolean),milestones};
}
function bind(){
  $$("[data-tab]").forEach(b=>b.onclick=()=>setTab(b.dataset.tab));
  $$("[data-tab-jump]").forEach(b=>b.onclick=()=>setTab(b.dataset.tabJump));
  $(".avatar")?.addEventListener("click",()=>setTab("profile"));
  $("#notifyBtn")?.addEventListener("click",notificationsModal);
  $("#goalForm")?.addEventListener("submit",async e=>{
    e.preventDefault();const input=$("#goalInput"),goal=input.value.trim();if(!goal)return;
    const btn=$("button",e.currentTarget);btn.disabled=true;btn.textContent="UNDERSTANDING GOAL…";
    const p=await GoalService.create(goal,state.profile.id);state.projectId=p.id;state.stage="blueprint";state.tab="projects";state.candidates=null;state.teams=null;render();toast(p.source==="ai"?"Blueprint generated with SWARM AI":"Blueprint generated with deterministic fallback");
  });
  $$("[data-example]").forEach(b=>b.onclick=()=>{const i=$("#goalInput");i.value=b.dataset.example;i.focus()});
  $$("[data-project]").forEach(b=>b.onclick=()=>openProject(b.dataset.project));
  $("#backProjects")?.addEventListener("click",()=>{state.projectId=null;render()});
  $$("[data-stage]").forEach(b=>b.onclick=()=>{state.stage=b.dataset.stage;render()});
  $$("[data-stage-go]").forEach(b=>b.onclick=()=>{state.stage=b.dataset.stageGo;render()});
  $("#saveBlueprint")?.addEventListener("click",()=>{const p=currentProject(),next=BlueprintService.update(p,collectBlueprint(p));state.candidates=null;state.teams=null;render();toast("Blueprint saved")});
  $("#addRole")?.addEventListener("click",()=>{const list=$(".role-editor-list");list.insertAdjacentHTML("beforeend",`<article class="role-editor" data-role-editor data-type="optional" data-id="${makeId("role")}"><div class="role-editor-head"><select data-role-type><option value="required">REQUIRED</option><option value="optional" selected>OPTIONAL</option></select><button type="button" data-remove-role>REMOVE</button></div><label>ROLE<input data-role-title value="New Specialist"></label><label>SKILLS<input data-role-skills value=""></label><div class="two-col"><label>BUDGET CAP<input data-role-budget type="number"></label><label>HOURS<input data-role-hours type="number" value="24"></label></div><label>LANGUAGES<input data-role-languages value="English"></label></article>`);bindDynamicBlueprint()});
  $("#addMilestone")?.addEventListener("click",()=>{ $("#milestoneEditors").insertAdjacentHTML("beforeend",`<div class="milestone-edit" data-ms-id="${makeId("ms")}"><input value="New milestone"><button type="button" data-remove-ms>×</button></div>`);bindDynamicBlueprint()});
  bindDynamicBlueprint();
  $("#runMatching")?.addEventListener("click",()=>{state.stage="matches";state.candidates=null;render()});
  $("#buildTeams")?.addEventListener("click",()=>{state.stage="teams";state.teams=null;render()});
  $$("[data-profile-demo]").forEach(b=>b.onclick=()=>profileModal(b.dataset.profileDemo));
  $("[data-role-detail],[data-role-node]").forEach(b=>b.onclick=()=>roleModal(currentProject(),b.dataset.roleDetail||b.dataset.roleNode));
  $$("[data-build-team]").forEach(b=>b.onclick=()=>{const p=currentProject(),team=ensureTeams(p)[Number(b.dataset.buildTeam)];if(!team)return;const swarm=SwarmService.create(p,team);graphMoment(p,team,()=>{state.stage="invites";render();toast("Swarm formation started")})});
  $$("[data-invite]").forEach(b=>b.onclick=()=>{const p=currentProject(),s=currentSwarm(),result=InvitationService.respond(b.dataset.invite,b.dataset.response,p,DEMO_PROFILES,s);if(result.replacement)toast("Declined → replacement matching ran automatically");SwarmService.syncMembers(s);render()});
  $$("[data-ms-check]").forEach(c=>c.onchange=()=>{ProjectService.setMilestone(currentProject().id,c.dataset.msCheck,c.checked?"done":"todo");render()});
  $("#addTask")?.addEventListener("click",taskModal);
  $$("[data-task-check]").forEach(c=>c.onchange=()=>{SwarmService.setTask(currentSwarm(),c.dataset.taskCheck,c.checked?"done":"todo");render()});
  $("#addDecision")?.addEventListener("click",decisionModal);
  $("#messageForm")?.addEventListener("submit",e=>{e.preventDefault();const input=$("#messageInput"),text=input.value.trim();if(!text)return;SwarmService.addMessage(currentSwarm(),text,"YOU");render()});
  $("#runCoordinator")?.addEventListener("click",()=>coordinatorModal(currentProject()));
  $("#projectOutcome")?.addEventListener("click",()=>outcomeModal(currentProject()));
  $("#discoverySearch")?.addEventListener("input",filterDiscovery);$("#discoveryFilter")?.addEventListener("change",filterDiscovery);
  $("#editProfile")?.addEventListener("click",editProfileModal);
  $("#installBtn")?.addEventListener("click",installApp);
  $("#signOut")?.addEventListener("click",()=>{Store.clearSession();state.session=null;showAuth("signin")});
}
function bindDynamicBlueprint(){
  $$("[data-remove-role]").forEach(b=>b.onclick=()=>b.closest("[data-role-editor]")?.remove());
  $$("[data-remove-ms]").forEach(b=>b.onclick=()=>b.closest("[data-ms-id]")?.remove());
}
function filterDiscovery(){
  const q=($("#discoverySearch")?.value||"").toLowerCase(),f=($("#discoveryFilter")?.value||"").toLowerCase();
  $$(".person-card").forEach(card=>{const text=card.dataset.search||"";card.hidden=!!((q&&!text.includes(q))||(f&&!text.includes(f)))});
}
async function installApp(){
  if(state.deferredInstall){state.deferredInstall.prompt();await state.deferredInstall.userChoice;state.deferredInstall=null}
  else toast("Use your browser's Add to Home Screen option.");
}
window.addEventListener("beforeinstallprompt",e=>{e.preventDefault();state.deferredInstall=e});
window.addEventListener("appinstalled",()=>toast("SWARM installed"));

showSplash();
if("serviceWorker" in navigator)navigator.serviceWorker.register("/sw.js",{updateViaCache:"none"}).then(r=>r.update()).catch(()=>{});
