const $ = (s, r=document) => r.querySelector(s);
const $$ = (s, r=document) => [...r.querySelectorAll(s)];

const VIDEO_URL = 'https://gcdn.picsart.com/editing-temp/99c62c28-207d-4bde-8335-0ae90cffb03c.mp4';
const VIDEO_POSTER = 'https://gcdn.picsart.com/cloud-storage/d861daf6-993d-4610-9f56-d8fdd904bca5.jpg';

const seedMarkets = [
  { id:'music-surprise', cat:'MUSIC', title:'Will a major artist announce a surprise release before October 1?', yes:61, no:39, closes:'2026-10-01T23:59:00-05:00', volume:18420 },
  { id:'tv-renewal', cat:'TV + STREAMING', title:'Will a currently trending streaming series announce a renewal this month?', yes:68, no:32, closes:'2026-09-30T23:59:00-05:00', volume:12760 },
  { id:'fashion-metallic', cat:'FASHION', title:'Will metallic tailoring remain a top-five runway trend through the end of September?', yes:72, no:28, closes:'2026-09-30T20:00:00-05:00', volume:9340 },
  { id:'wrestling-return', cat:'WRESTLING', title:'Will a teased surprise return happen before the next premium event?', yes:57, no:43, closes:'2026-09-27T19:00:00-05:00', volume:16110 },
];

const creators = [
  {name:'JADA R.',initials:'JR',role:'MODEL / ACTOR',loc:'DALLAS, TX',skills:['EDITORIAL','BEAUTY','UGC','FILM'],need:'Photographers, fashion designers, beauty campaigns and casting opportunities.'},
  {name:'MAYA K.',initials:'MK',role:'PHOTOGRAPHER',loc:'AUSTIN, TX',skills:['FASHION','35MM','PORTRAIT','TOUR'],need:'Models, stylists, musicians and editorial commissions.'},
  {name:'DEVON A.',initials:'DA',role:'DIRECTOR / EDITOR',loc:'ATLANTA, GA',skills:['MUSIC VIDEO','DOC','COLOR','SHORT FILM'],need:'Artists, producers, actors and branded-content partners.'},
  {name:'SOL B.',initials:'SB',role:'STYLIST',loc:'NEW YORK, NY',skills:['EDITORIAL','RUNWAY','CELEBRITY','ARCHIVE'],need:'Photographers, publications and talent for experimental editorials.'}
];

const state = {
  tab: localStorage.getItem('pulse.tab') || 'feed',
  creatorIndex: Number(localStorage.getItem('pulse.creatorIndex') || 0),
  matches: JSON.parse(localStorage.getItem('pulse.matches') || '[]'),
  wallet: JSON.parse(localStorage.getItem('pulse.wallet') || JSON.stringify({active:false,balance:0,state:null,age:false,location:false,identity:false})),
  liveStories: [],
  liveStatus: 'loading',
  markets: seedMarkets,
};

function save(){
  localStorage.setItem('pulse.tab', state.tab);
  localStorage.setItem('pulse.creatorIndex', state.creatorIndex);
  localStorage.setItem('pulse.matches', JSON.stringify(state.matches));
  localStorage.setItem('pulse.wallet', JSON.stringify(state.wallet));
}

function esc(v=''){ return String(v).replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c])); }
function money(n){ return Number(n||0).toLocaleString('en-US',{style:'currency',currency:'USD'}); }
function compact(n){ return Intl.NumberFormat('en',{notation:'compact',maximumFractionDigits:1}).format(n); }
function toast(msg){
  let el=$('.toast'); if(!el){el=document.createElement('div');el.className='toast';document.body.appendChild(el)}
  el.textContent=msg; el.classList.add('show'); clearTimeout(window.__pulseToast); window.__pulseToast=setTimeout(()=>el.classList.remove('show'),1900);
}
function openModal(html){ $('#modalCard').innerHTML=html; $('#modal').showModal(); }
function closeModal(){ $('#modal').close(); }

function timeLeft(iso){
  const ms = new Date(iso) - new Date();
  if(ms <= 0) return 'CLOSED';
  const d=Math.floor(ms/86400000), h=Math.floor(ms%86400000/3600000), m=Math.floor(ms%3600000/60000);
  if(d>0) return `${d}D ${h}H`;
  return `${h}H ${m}M`;
}

async function loadLiveStories(){
  state.liveStatus='loading';
  try{
    const q = encodeURIComponent('(fashion OR music OR movie OR television OR celebrity OR wrestling) sourcelang:english');
    const url = `https://api.gdeltproject.org/api/v2/doc/doc?query=${q}&mode=artlist&maxrecords=12&format=json&sort=hybridrel&timespan=24h`;
    const r = await fetch(url,{cache:'no-store'});
    if(!r.ok) throw new Error('feed');
    const data = await r.json();
    const articles = Array.isArray(data.articles) ? data.articles : [];
    state.liveStories = articles.slice(0,10).map(a=>({
      title:a.title || 'Culture update',
      url:a.url || '#',
      domain:a.domain || '',
      seen:a.seendate || '',
      image:(a.socialimage||'').startsWith('https://') ? a.socialimage : ''
    }));
    state.liveStatus='live';
  }catch(e){
    state.liveStatus='fallback';
    state.liveStories=[];
  }
  if(state.tab==='feed') render();
}

function feed(){
  const live = state.liveStories.length ? state.liveStories.map((a,i)=>`
    <a class="live-story" href="${esc(a.url)}" target="_blank" rel="noopener">
      <div class="live-story-img" ${a.image?`style="background-image:linear-gradient(180deg,transparent 35%,rgba(0,0,0,.8)),url('${esc(a.image)}')"`:''}>
        <span>${i<3?'BREAKING':'LIVE'}</span>
      </div>
      <div class="live-story-copy"><b>${esc(a.title)}</b><small>${esc(a.domain||'LIVE SOURCE')} · UPDATED</small></div>
    </a>`).join('') : `
    <div class="live-fallback">
      <b>${state.liveStatus==='loading'?'PULLING LIVE CULTURE HEADLINES…':'LIVE FEED TEMPORARILY UNAVAILABLE'}</b>
      <span>PULSE automatically refreshes entertainment, fashion, music, film and wrestling headlines.</span>
    </div>`;

  return `
  <section class="hero">
    <div class="hero-grid"></div><div class="live-pill"><i></i> LIVE CULTURE SIGNAL</div>
    <div class="brand-lockup"><span>LSMG</span><em>×</em><span>LEDGERA</span></div>
    <h1>WHAT'S HAPPENING.<br><mark>WHAT'S NEXT.</mark></h1>
    <p>Watch LSMG × LEDGERA content, follow culture in real time, make market calls and connect with the creatives shaping the next wave.</p>
    <div class="cta-row"><button class="btn primary" data-go="predict">OPEN MARKETS</button><button class="btn ghost" data-go="watch">WATCH NOW</button></div>
  </section>
  <div class="ticker"><span class="ticker-label">PULSE LIVE</span><div class="ticker-track"><span>ENTERTAINMENT</span><b>•</b><span>FASHION</span><b>•</b><span>MUSIC</span><b>•</b><span>FILM</span><b>•</b><span>WRESTLING</span><b>•</b><span>CREATOR ECONOMY</span></div></div>
  <div class="section-kicker"><span><b>NOW</b> / LIVE UPDATES</span><button class="text-btn" id="refreshLive">REFRESH ↻</button></div>
  <div class="live-grid">${live}</div>
  <div class="section-kicker"><span><b>FEATURED</b> / LSMG × LEDGERA</span><span>THE RECORD OF CULTURE</span></div>
  <article class="feature-video-card" data-go="watch">
    <div class="feature-video-poster" style="background-image:linear-gradient(180deg,transparent 20%,rgba(0,0,0,.88)),url('${VIDEO_POSTER}')">
      <div class="play-orb">▶</div><div class="feature-tag">LEDGERA FASHION EDIT · NEW</div>
      <h2>WATCH THE<br>NEW CUT.</h2>
    </div>
  </article>`;
}

function watch(){ return `
  <div class="section-kicker"><span><b>WATCH</b> / PULSE TV</span><span>LSMG × LEDGERA</span></div>
  <article class="video-shell">
    <video controls playsinline preload="metadata" poster="${VIDEO_POSTER}" src="${VIDEO_URL}"></video>
    <div class="video-copy"><div><span class="category">LEDGERA / FASHION</span><h2>LEDGERA FASHION EDIT</h2><p>New visual from the LSMG × LEDGERA network.</p></div><span class="live-badge">NEW</span></div>
  </article>
  <div class="section-kicker"><span>CHANNELS</span><span>MORE COMING</span></div>
  <div class="channel-grid">
    <button class="channel-card"><small>LSMG</small><strong>ORIGINALS</strong><span>Interviews · Docs · BTS</span></button>
    <button class="channel-card red"><small>LEDGERA</small><strong>AFTER DARK</strong><span>Fashion · Nightlife · Culture</span></button>
    <button class="channel-card"><small>PARTNERS</small><strong>PREMIERES</strong><span>Approved partner programming</span></button>
  </div>`; }

function predict(){
  const checks = [state.wallet.age,state.wallet.location,state.wallet.identity].filter(Boolean).length;
  return `
  <section class="wallet-hero">
    <div><small>AVAILABLE CASH</small><strong>${money(state.wallet.balance)}</strong><span>${state.wallet.active?'CASH WALLET ACTIVE':'CASH WALLET NOT YET ACTIVATED'}</span></div>
    <button class="wallet-btn" id="walletBtn">${state.wallet.active?'WALLET':'ACTIVATE'}</button>
  </section>
  <div class="compliance-strip"><span>${checks}/3 CHECKS</span><b>21+ · LOCATION · IDENTITY</b><span>${state.wallet.state||'TX / FL'}</span></div>
  <div class="section-kicker"><span><b>PREDICT</b> / CASH MARKETS</span><span><i class="live-dot"></i> LIVE</span></div>
  ${state.markets.map(m=>`
    <article class="market-card">
      <div class="market-top"><span class="category">${m.cat}</span><span class="close-time">${timeLeft(m.closes)}</span></div>
      <h3>${esc(m.title)}</h3>
      <div class="market-volume">${compact(m.volume)} MARKET VOLUME</div>
      <div class="market-sides">
        <button class="market-side yes" data-bet="${m.id}" data-side="YES" data-price="${m.yes}"><span>YES</span><strong>${m.yes}¢</strong></button>
        <button class="market-side no" data-bet="${m.id}" data-side="NO" data-price="${m.no}"><span>NO</span><strong>${m.no}¢</strong></button>
      </div>
      <div class="market-bar"><span style="width:${m.yes}%"></span></div>
      <div class="market-foot"><span>YES ${m.yes}%</span><span>NO ${m.no}%</span></div>
    </article>`).join('')}
  <div class="cash-note"><b>CASH MODE</b><span>Real-money settlement is designed for licensed operation only and remains gated by identity, location, payment/settlement and license-scope verification.</span></div>`;
}

function connect(){
  const c=creators[state.creatorIndex%creators.length];
  return `
  <div class="section-kicker"><span><b>CONNECT</b> / DISCOVER</span><span>${state.creatorIndex%creators.length+1} OF ${creators.length}</span></div>
  <div class="connect-wrap"><article class="creator-card" id="creatorCard">
    <div class="creator-visual" data-initials="${c.initials}"><span class="creator-role">${c.role}</span></div>
    <div class="creator-copy"><h2>${c.name}</h2><div class="creator-location">${c.loc}</div><div class="chips">${c.skills.map(s=>`<span class="chip">${s}</span>`).join('')}</div><div class="need"><b>LOOKING FOR</b>${c.need}</div></div>
  </article><div class="connect-actions"><button class="round-action" data-swipe="skip">×</button><button class="round-action star" data-swipe="save">☆</button><button class="round-action like" data-swipe="like">♡</button></div></div>`;
}

function me(){ return `
  <section class="profile-head"><div class="profile-row"><div class="profile-avatar">ZH</div><div><h2>PULSE PROFILE</h2><p>LSMG × LEDGERA CREATIVE NETWORK</p></div></div></section>
  <div class="profile-grid"><div class="profile-stat"><strong>${state.matches.length}</strong><span>CONNECTIONS</span></div><div class="profile-stat"><strong>${state.wallet.state||'—'}</strong><span>MARKET STATE</span></div><div class="profile-stat"><strong>${state.liveStatus==='live'?'LIVE':'ON'}</strong><span>UPDATES</span></div></div>
  <div class="section-kicker"><span>ACCOUNT</span></div>
  <div class="settings-list">
    <button data-action="wallet"><span>Cash wallet & verification</span><b>›</b></button>
    <button data-action="matches"><span>Creative connections</span><b>${state.matches.length}</b></button>
    <button data-action="notifications"><span>Live culture alerts</span><b>ON</b></button>
  </div>`; }

function render(){
  const view=$('#view');
  view.innerHTML = ({feed,watch,predict,connect,me}[state.tab]||feed)();
  $$('.nav-item').forEach(b=>b.classList.toggle('active',b.dataset.tab===state.tab));
  bind();
}

function setTab(t){ state.tab=t; save(); render(); window.scrollTo({top:0,behavior:'smooth'}); }

function walletModal(){
  openModal(`<button class="modal-close" data-close>×</button><span class="category">CASH ACCESS</span><h2>ACTIVATE WALLET</h2>
  <p>PULSE cash markets require the operator's applicable authorization plus user identity, age and permitted-location checks. Choose your state and complete the checks below.</p>
  <div class="state-picker"><button data-state="TX" class="${state.wallet.state==='TX'?'selected':''}">TEXAS</button><button data-state="FL" class="${state.wallet.state==='FL'?'selected':''}">FLORIDA</button></div>
  <label class="verify-row"><input id="ageCheck" type="checkbox" ${state.wallet.age?'checked':''}><span><b>21+ AGE CHECK</b><small>I confirm I am at least 21.</small></span></label>
  <button class="verify-action ${state.wallet.location?'done':''}" id="locationCheck"><span>${state.wallet.location?'✓':'○'}</span><div><b>LOCATION CHECK</b><small>${state.wallet.location?'Browser location permission granted':'Verify physical presence in an allowed state'}</small></div></button>
  <button class="verify-action ${state.wallet.identity?'done':''}" id="identityCheck"><span>${state.wallet.identity?'✓':'○'}</span><div><b>IDENTITY / KYC</b><small>${state.wallet.identity?'Prototype status recorded':'Connect an approved identity provider before production'}</small></div></button>
  <button class="btn primary full" id="completeWallet">COMPLETE SETUP</button>
  <div class="legal-mini">Production cash deposits, withdrawals and wagers stay disabled until a licensed payment/settlement provider and the exact wagering authorization are connected.</div>`);
}

function betModal(id,side,price){
  const m=state.markets.find(x=>x.id===id); if(!m) return;
  openModal(`<button class="modal-close" data-close>×</button><span class="category">${m.cat} · ${side}</span><h2>PLACE CASH WAGER</h2><p>${esc(m.title)}</p>
  <div class="bet-quote"><div><small>PRICE</small><strong>${price}¢</strong></div><div><small>AVAILABLE</small><strong>${money(state.wallet.balance)}</strong></div></div>
  <label class="amount-label">WAGER AMOUNT<input id="betAmount" inputmode="decimal" type="number" min="1" step="1" placeholder="$25"></label>
  <div id="payoutPreview" class="payout-preview">ENTER AN AMOUNT TO SEE ESTIMATED PAYOUT</div>
  <button class="btn primary full" id="submitBet">REVIEW WAGER</button>
  <div class="legal-mini">This build will not transmit real funds until the production wallet, geolocation/KYC stack, and license scope are verified and connected.</div>`);
  const input=$('#betAmount');
  input?.addEventListener('input',()=>{
    const amt=Math.max(0,Number(input.value||0));
    const contracts=price?amt/(price/100):0;
    const gross=contracts;
    $('#payoutPreview').textContent = amt ? `EST. GROSS RETURN IF ${side} RESOLVES TRUE: ${money(gross)}` : 'ENTER AN AMOUNT TO SEE ESTIMATED PAYOUT';
  });
  $('#submitBet')?.addEventListener('click',()=>{
    if(!state.wallet.active){ closeModal(); walletModal(); return; }
    toast('Cash settlement provider not connected yet');
  });
}

function bind(){
  $$('[data-go]').forEach(b=>b.onclick=()=>setTab(b.dataset.go));
  $('#refreshLive')?.addEventListener('click',loadLiveStories);
  $('#walletBtn')?.addEventListener('click',walletModal);
  $$('[data-bet]').forEach(b=>b.addEventListener('click',()=>betModal(b.dataset.bet,b.dataset.side,Number(b.dataset.price))));
  $$('[data-swipe]').forEach(b=>b.addEventListener('click',()=>{
    const action=b.dataset.swipe; const c=creators[state.creatorIndex%creators.length];
    if(action==='like' && !state.matches.includes(c.name)){ state.matches.push(c.name); toast('Connection request saved'); }
    else if(action==='save') toast('Creative saved');
    state.creatorIndex=(state.creatorIndex+1)%creators.length; save(); render();
  }));
  $$('[data-action="wallet"]').forEach(b=>b.onclick=walletModal);
}

$('#searchBtn')?.addEventListener('click',()=>{
  openModal(`<button class="modal-close" data-close>×</button><span class="category">PULSE SEARCH</span><h2>SEARCH CULTURE</h2><input class="search-box" id="searchInput" placeholder="Creators, stories, markets…"><div id="searchResults" class="search-results"></div>`);
  $('#searchInput')?.addEventListener('input',e=>{
    const q=e.target.value.trim().toLowerCase();
    const results=[];
    if(q){
      state.liveStories.filter(x=>x.title.toLowerCase().includes(q)).slice(0,4).forEach(x=>results.push(`<a class="search-result" target="_blank" href="${esc(x.url)}"><b>${esc(x.title)}</b><span>LIVE STORY · ${esc(x.domain)}</span></a>`));
      state.markets.filter(x=>x.title.toLowerCase().includes(q)).slice(0,4).forEach(x=>results.push(`<button class="search-result" data-jump="predict"><b>${esc(x.title)}</b><span>${x.cat} · CASH MARKET</span></button>`));
      creators.filter(x=>(x.name+x.role+x.skills.join(' ')).toLowerCase().includes(q)).slice(0,4).forEach(x=>results.push(`<button class="search-result" data-jump="connect"><b>${x.name}</b><span>${x.role} · ${x.loc}</span></button>`));
    }
    $('#searchResults').innerHTML=results.join('')||'<div class="empty">Type to search PULSE.</div>';
    $$('[data-jump]').forEach(b=>b.onclick=()=>{closeModal();setTab(b.dataset.jump)});
  });
});

$('#modal')?.addEventListener('click',e=>{ if(e.target===e.currentTarget) closeModal(); });
document.addEventListener('click',e=>{ if(e.target.closest('[data-close]')) closeModal(); });
document.addEventListener('click',e=>{
  const s=e.target.closest('[data-state]'); if(s){state.wallet.state=s.dataset.state;save();walletModal();}
});
document.addEventListener('change',e=>{ if(e.target.id==='ageCheck'){state.wallet.age=e.target.checked;save();} });
document.addEventListener('click',e=>{
  if(e.target.closest('#locationCheck')){
    if(!navigator.geolocation){ toast('Location is not available in this browser'); return; }
    navigator.geolocation.getCurrentPosition(()=>{state.wallet.location=true;save();walletModal();},()=>toast('Location permission was not granted'),{enableHighAccuracy:true,timeout:9000});
  }
  if(e.target.closest('#identityCheck')){ state.wallet.identity=true; save(); walletModal(); }
  if(e.target.closest('#completeWallet')){
    if(!state.wallet.state || !state.wallet.age || !state.wallet.location || !state.wallet.identity){toast('Complete all verification checks first');return;}
    state.wallet.active=true; save(); closeModal(); render(); toast('Wallet gate completed — funding provider still required');
  }
});

$$('.nav-item').forEach(b=>b.onclick=()=>setTab(b.dataset.tab));
$('.avatar')?.addEventListener('click',()=>setTab('me'));

render();
loadLiveStories();
setInterval(()=>{ if(state.tab==='feed') loadLiveStories(); else if(state.tab==='predict') render(); },60000);
setTimeout(()=>$('#splash')?.classList.add('hide'),750);
if('serviceWorker' in navigator) navigator.serviceWorker.register('/sw.js').catch(()=>{});
