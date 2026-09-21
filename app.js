const state = {
  tab: localStorage.getItem('pulse.tab') || 'feed',
  points: Number(localStorage.getItem('pulse.points') || 1240),
  streak: Number(localStorage.getItem('pulse.streak') || 6),
  picks: JSON.parse(localStorage.getItem('pulse.picks') || '{}'),
  matches: JSON.parse(localStorage.getItem('pulse.matches') || '[]'),
  creatorIndex: Number(localStorage.getItem('pulse.creatorIndex') || 0)
};

const predictions = [
  {id:'tour',cat:'MUSIC',q:'Will a surprise arena-tour extension be announced before October 15?',desc:'PULSE AI is tracking venue holds, artist activity, and promoter signals.',ai:67,close:'24 DAYS',out:[['YES',71],['NO',29]]},
  {id:'reality',cat:'TV + REALITY',q:'Which storyline dominates next week’s episode?',desc:'Community forecast for the most likely lead storyline.',ai:58,close:'4 DAYS',out:[['THE BREAKUP',46],['THE ALLIANCE',32],['THE RETURN',22]]},
  {id:'fashion',cat:'FASHION',q:'Will metallic tailoring become a top-five runway trend this month?',desc:'Signals include show notes, stylist pulls, and recent collection frequency.',ai:74,close:'10 DAYS',out:[['YES',63],['NO',37]]},
  {id:'wrestling',cat:'WRESTLING',q:'Will the teased mystery partner appear before the next premium event?',desc:'Prediction based on official teases, storyline cadence, and fan consensus.',ai:61,close:'6 DAYS',out:[['YES',66],['NO',34]]}
];

const creators = [
  {name:'JADA R.',initials:'JR',role:'MODEL / ACTOR',loc:'DALLAS, TX',skills:['EDITORIAL','BEAUTY','UGC','FILM'],need:'Photographers, fashion designers, beauty campaigns and casting opportunities.',mutual:true},
  {name:'MAYA K.',initials:'MK',role:'PHOTOGRAPHER',loc:'AUSTIN, TX',skills:['FASHION','35MM','PORTRAIT','TOUR'],need:'Models, stylists, musicians and editorial commissions.',mutual:false},
  {name:'DEVON A.',initials:'DA',role:'DIRECTOR / EDITOR',loc:'ATLANTA, GA',skills:['MUSIC VIDEO','DOC','COLOR','SHORT FILM'],need:'Artists, producers, actors and branded-content partners.',mutual:true},
  {name:'SOL B.',initials:'SB',role:'STYLIST',loc:'NEW YORK, NY',skills:['EDITORIAL','RUNWAY','CELEBRITY','ARCHIVE'],need:'Photographers, publications and talent for experimental editorials.',mutual:true}
];

const view = document.getElementById('view');
const modal = document.getElementById('modal');
const modalCard = document.getElementById('modalCard');

function save(){
  localStorage.setItem('pulse.tab', state.tab);
  localStorage.setItem('pulse.points', state.points);
  localStorage.setItem('pulse.streak', state.streak);
  localStorage.setItem('pulse.picks', JSON.stringify(state.picks));
  localStorage.setItem('pulse.matches', JSON.stringify(state.matches));
  localStorage.setItem('pulse.creatorIndex', state.creatorIndex);
}
function toast(msg){
  let el=document.querySelector('.toast');
  if(!el){el=document.createElement('div');el.className='toast';document.body.appendChild(el)}
  el.textContent=msg;el.classList.add('show');setTimeout(()=>el.classList.remove('show'),1600);
}
function setTab(tab){
  state.tab=tab;save();
  document.querySelectorAll('.nav-item').forEach(b=>b.classList.toggle('active',b.dataset.tab===tab));
  render();window.scrollTo({top:0,behavior:'smooth'});
}
function feed(){return `
  <section class="hero">
    <div class="hero-grid"></div>
    <div class="live-pill">LIVE PULSE · CULTURE NOW</div>
    <h1>WATCH CULTURE.<br>PREDICT WHAT'S NEXT.</h1>
    <p>PULSE combines LEDGERA editorial, LSMG originals, culture forecasting and a network built for people making the next thing.</p>
    <div class="cta-row"><button class="btn primary" data-go="predict">MAKE A PREDICTION</button><button class="btn ghost" data-go="connect">FIND CREATIVES</button></div>
  </section>
  <div class="stat-strip"><div class="stat"><strong>24</strong><span>Live predictions</span></div><div class="stat"><strong>1.2K</strong><span>Your pulse</span></div><div class="stat"><strong>06</strong><span>Day streak</span></div></div>
  <div class="section-kicker"><span><b>LEDGERA</b> NOW</span><span>THE RECORD OF CULTURE</span></div>
  <div class="cards">
    <article class="story-card"><div class="story-visual editorial"><span class="story-mark">LEDGERA / FASHION</span><div class="story-big">THE NEXT<br>LOOK</div></div><div class="story-copy"><h3>Five signals reshaping what culture wears next.</h3><p>A visual-first trend briefing built for the people watching the runway and the street at the same time.</p><div class="meta"><span>5 MIN READ</span><span>NOW</span></div></div></article>
    <article class="story-card"><div class="story-visual"><span class="story-mark">LSMG ORIGINAL</span><div class="story-big">BEHIND<br>THE BUILD</div></div><div class="story-copy"><h3>Inside the creators turning local scenes into national moments.</h3><p>Original interviews, short docs and behind-the-scenes access from the LSMG network.</p><div class="meta"><span>WATCH</span><span>12:48</span></div></div></article>
    <article class="story-card"><div class="story-visual alt"><span class="story-mark">PULSE SIGNAL</span><div class="story-big">64%<br>LIKELY</div></div><div class="story-copy"><h3>The community thinks a major surprise announcement lands this week.</h3><p>See the forecast, the evidence and how your call compares with PULSE AI.</p><div class="meta"><span>8,402 CALLS</span><span data-go="predict">PREDICT →</span></div></div></article>
  </div>`}
function watch(){return `
  <div class="section-kicker"><span><b>WATCH</b> / CHANNELS</span><span>LSMG × LEDGERA</span></div>
  <div class="horizontal">
    <article class="watch-card"><div class="channel">LSMG ORIGINAL · EP 01</div><div><h3>THE PEOPLE<br>MAKING IT</h3><button class="play" data-watch="LSMG Original">▶</button></div></article>
    <article class="watch-card light"><div class="channel">LEDGERA FILM</div><div><h3>AFTER<br>DARK</h3><button class="play" data-watch="LEDGERA After Dark">▶</button></div></article>
    <article class="watch-card"><div class="channel">PARTNER CHANNEL</div><div><h3>RUNWAY<br>ACCESS</h3><button class="play" data-watch="Partner Channel">▶</button></div></article>
  </div>
  <div class="section-kicker"><span>NEW THIS WEEK</span><span>VIEW ALL</span></div>
  <div class="cards">
    <div class="list-card"><div><h4>LSMG ORIGINALS: Scene Builders</h4><p>Dallas creatives on making work before the industry notices.</p></div><span class="badge red">18:22</span></div>
    <div class="list-card"><div><h4>LEDGERA Interview Room</h4><p>Fast interviews with talent, designers and culture shapers.</p></div><span class="badge">09:31</span></div>
    <div class="list-card"><div><h4>Partner Premiere</h4><p>A space for approved partner films, shows, events and drops.</p></div><span class="badge">NEW</span></div>
  </div>
  <div class="section-kicker"><span>WHY WATCH HERE</span></div>
  <div class="brand-panel"><img src="/assets/lsmg-ledgera.jpeg" alt="LSMG and LEDGERA branding"><div class="copy"><p>PULSE brings LSMG productions, LEDGERA editorial video and approved partner programming into one culture-first feed.</p></div></div>`}
function predict(){return `
  <div class="score-hero"><div class="tiny">YOUR PULSE SCORE</div><strong>${state.points.toLocaleString()}</strong><p>${state.streak}-day call streak · Top 18% this week</p></div>
  <div class="section-kicker"><span><b>PREDICT</b> / LIVE</span><span>NO CASH WAGERING</span></div>
  ${predictions.map(p=>`<article class="predict-card">
    <div class="predict-head"><div class="predict-top"><span class="category">${p.cat}</span><span class="closes">CLOSES IN ${p.close}</span></div><h3>${p.q}</h3><p>${p.desc}</p></div>
    <div class="outcomes">${p.out.map(([label,pct])=>`<button class="outcome ${state.picks[p.id]===label?'picked':''}" data-predict="${p.id}" data-label="${label}"><span class="fill" style="width:${pct}%"></span><span class="label">${label}${state.picks[p.id]===label?' · YOUR CALL':''}</span><span class="pct">${pct}%</span></button>`).join('')}</div>
    <div class="predict-foot"><span class="ai-chip">PULSE AI <b>${p.ai}%</b> CONFIDENCE</span><span>COMMUNITY FORECAST</span></div>
  </article>`).join('')}
  <div class="empty">PULSE predictions use points, streaks and rankings only in this prototype. No real-money wagering.</div>`}
function connect(){
  const idx=state.creatorIndex%creators.length;const c=creators[idx];
  return `<div class="section-kicker"><span><b>CONNECT</b> / DISCOVER</span><span>${idx+1} OF ${creators.length}</span></div>
  <div class="connect-wrap">
    <article class="creator-card" id="creatorCard">
      <div class="creator-visual" data-initials="${c.initials}"><span class="creator-role">${c.role}</span></div>
      <div class="creator-copy"><h2>${c.name}</h2><div class="creator-location">${c.loc}</div><div class="chips">${c.skills.map(x=>`<span class="chip">${x}</span>`).join('')}</div><div class="need"><b>LOOKING FOR</b>${c.need}</div></div>
    </article>
    <div class="connect-actions"><button class="round-action" data-swipe="skip" aria-label="Skip">×</button><button class="round-action star" data-swipe="save" aria-label="Save">☆</button><button class="round-action like" data-swipe="like" aria-label="Connect">♡</button></div>
  </div>`
}
function me(){return `
  <div class="profile-head"><div class="profile-row"><div class="profile-avatar">ZH</div><div><h2>Zachary</h2><p>Creative · Media · Dallas</p></div></div><div class="level"><div class="level-top"><span>PULSE LEVEL 07</span><span>68%</span></div><div class="level-bar"><div class="level-fill"></div></div></div></div>
  <div class="profile-grid"><div class="profile-stat"><strong>${state.points.toLocaleString()}</strong><span>PULSE</span></div><div class="profile-stat"><strong>${Object.keys(state.picks).length}</strong><span>CALLS</span></div><div class="profile-stat"><strong>${state.matches.length}</strong><span>MATCHES</span></div></div>
  <div class="section-kicker"><span>BADGES</span><span>VIEW ALL</span></div>
  <div class="horizontal" style="grid-auto-columns:46%"><div class="list-card"><div><h4>EARLY SIGNAL</h4><p>Called a trend before 70% of the community.</p></div></div><div class="list-card"><div><h4>CULTURE STREAK</h4><p>${state.streak} consecutive active days.</p></div></div><div class="list-card"><div><h4>CONNECTOR</h4><p>Building your creative graph.</p></div></div></div>
  <div class="section-kicker"><span>YOUR MATCHES</span></div>
  ${state.matches.length?state.matches.map(n=>`<div class="list-card"><div><h4>${n}</h4><p>Creative connection · PULSE</p></div><span class="badge red">CHAT</span></div>`).join(''):'<div class="empty">No matches yet. Head to CONNECT and start building your network.</div>'}
  <div class="section-kicker"><span>BRAND SYSTEM</span></div>
  <div class="brand-panel"><img src="/assets/lsmg-ledgera.jpeg" alt="LSMG and LEDGERA branding"><div class="copy"><p><b style="color:white">PULSE</b> is the product. <b style="color:white">LEDGERA</b> powers culture and editorial. <b style="color:white">LSMG</b> powers creators, productions and partnerships.</p></div></div>`}

function render(){
  const map={feed,watch,predict,connect,me};view.innerHTML=map[state.tab]();
  bind();
}
function bind(){
  view.querySelectorAll('[data-go]').forEach(el=>el.addEventListener('click',()=>setTab(el.dataset.go)));
  view.querySelectorAll('[data-watch]').forEach(el=>el.addEventListener('click',()=>openModal(`<button class="modal-close" data-close>×</button><h2>${el.dataset.watch}</h2><p>This prototype is ready for your actual video URLs or embeds. The production build can pull LSMG, LEDGERA and approved partner content from a CMS or media database.</p><button class="btn primary" data-close>GOT IT</button>`)));
  view.querySelectorAll('[data-predict]').forEach(el=>el.addEventListener('click',()=>makePrediction(el.dataset.predict,el.dataset.label)));
  view.querySelectorAll('[data-swipe]').forEach(el=>el.addEventListener('click',()=>swipe(el.dataset.swipe)));
}
function makePrediction(id,label){
  if(!state.picks[id]){state.points+=25;toast('+25 PULSE · CALL LOCKED')}
  state.picks[id]=label;save();render();
}
function swipe(action){
  const c=creators[state.creatorIndex%creators.length];const card=document.getElementById('creatorCard');
  if(card){card.style.transform=action==='skip'?'translateX(-130%) rotate(-14deg)':'translateX(130%) rotate(14deg)';card.style.opacity='0'}
  if(action==='save')toast('SAVED TO YOUR CREATIVE LIST');
  if(action==='like'){
    state.points+=10;
    if(c.mutual && !state.matches.includes(c.name)){
      state.matches.push(c.name);
      setTimeout(()=>openModal(`<button class="modal-close" data-close>×</button><div class="category">IT'S A CREATIVE MATCH</div><h2>YOU × ${c.name}</h2><p>You both want to connect. Messaging can be wired to Supabase in the production build.</p><button class="btn primary" data-close>OPEN CHAT SOON</button>`),330);
    } else toast('+10 PULSE · INTEREST SENT');
  }
  state.creatorIndex=(state.creatorIndex+1)%creators.length;save();setTimeout(render,320);
}
function openModal(html){modalCard.innerHTML=html;modal.showModal();modalCard.querySelectorAll('[data-close]').forEach(b=>b.addEventListener('click',()=>modal.close()))}
function searchModal(){openModal(`<button class="modal-close" data-close>×</button><h2>SEARCH PULSE</h2><input id="searchInput" class="search-box" placeholder="Creators, predictions, shows, culture…" autofocus><div id="searchResults" class="search-results"><div class="search-result"><b>Try “fashion”</b><span>Search across PULSE</span></div></div>`);setTimeout(()=>{const input=document.getElementById('searchInput');const res=document.getElementById('searchResults');input?.addEventListener('input',()=>{const q=input.value.toLowerCase().trim();const items=[['Fashion predictions','PREDICT'],['LSMG Originals','WATCH'],['Jada R. · Model / Actor','CONNECT'],['LEDGERA Now','FEED']].filter(x=>!q||x[0].toLowerCase().includes(q));res.innerHTML=items.map(x=>`<div class="search-result"><b>${x[0]}</b><span>${x[1]}</span></div>`).join('')||'<div class="empty">No results in the demo dataset.</div>'})},30)}

document.querySelectorAll('[data-tab]').forEach(btn=>btn.addEventListener('click',()=>setTab(btn.dataset.tab)));
document.getElementById('searchBtn').addEventListener('click',searchModal);
modal.addEventListener('click',e=>{if(e.target===modal)modal.close()});

window.addEventListener('load',()=>{
  setTimeout(()=>document.getElementById('splash').classList.add('hide'),1200);
  render();
  document.querySelectorAll('.nav-item').forEach(b=>b.classList.toggle('active',b.dataset.tab===state.tab));
  if('serviceWorker' in navigator) navigator.serviceWorker.register('/sw.js').catch(()=>{});
});
