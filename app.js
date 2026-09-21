const $ = (s, r=document) => r.querySelector(s);
const $$ = (s, r=document) => [...r.querySelectorAll(s)];

const VIDEO_URL = 'https://gcdn.picsart.com/editing-temp/99c62c28-207d-4bde-8335-0ae90cffb03c.mp4';
const VIDEO_POSTER = 'https://gcdn.picsart.com/cloud-storage/d861daf6-993d-4610-9f56-d8fdd904bca5.jpg';
const TRIBECA_IMAGE = 'https://ledgeramagazine.com/assets/images/tribeca/lsmg-tribeca-2026-announcement.png';

const creators = [
  {name:'HALIE',role:'MODEL',loc:'NEW YORK',image:'https://gcdn.picsart.com/editing-temp/6d834b75-cb57-42ca-a1b3-5772eab6d376.jpeg',skills:['EDITORIAL','COMMERCIAL','LEDGERA FACES'],need:'Editorials, fashion campaigns, photographers and creative collaborators.',url:'https://ledgeramagazine.com/new-faces/halie'},
  {name:'JADA',role:'MODEL / LSMG TALENT',loc:'DALLAS',image:'https://gcdn.picsart.com/editing-temp/e3f21ce2-4650-4bf0-879e-9bc1ce1b9d4c.jpeg',skills:['EDITORIAL','BEAUTY','FASHION'],need:'Beauty, editorial, fashion and on-camera opportunities.',url:'https://ledgeramagazine.com/new-faces/jada'},
  {name:'JANE TAYLOR',role:'MODEL / CREATOR',loc:'AUSTIN',image:'https://gcdn.picsart.com/editing-temp/dc8b7397-5f5f-4f8a-aebc-fc3731cdf71e.jpeg',skills:['MODEL','CREATOR','EDITORIAL'],need:'Commercial, UGC, acting, beauty and fashion opportunities.',url:'https://ledgeramagazine.com/new-faces/jane'},
  {name:'SOPHIA',role:'MODEL',loc:'LEDGERA FACES',image:'https://gcdn.picsart.com/editing-temp/d1210a97-37b9-4dc3-b9b0-091c0879171a.jpeg',skills:['STREETWEAR','LIFESTYLE','EDITORIAL'],need:'Fashion, streetwear, lifestyle and editorial collaborations.',url:'https://ledgeramagazine.com/new-faces/sophia'}
];

const LEDGERA = 'https://ledgeramagazine.com';
const fallbackArticles = [
  {title:'The NFL Cutdown Is Where the Season Gets Real',summary:'For hundreds of players, the 53-man deadline turns a summer audition into a career decision.',category:'SPORTS / NFL',url:LEDGERA+'/articles/nfl-roster-cuts-2026-53-man-deadline.html',image:''},
  {title:'College Sports Eligibility Is Colliding With the Courts',summary:'Conference rules, court orders and athlete rights are forcing the sport to redraw the line between college and pro.',category:'SPORTS / COLLEGE ATHLETICS',url:LEDGERA+'/articles/college-sports-eligibility-sec-court-fight-2026.html',image:''},
  {title:'The U.S. Open Is Getting the RedZone Treatment',summary:'ESPN is turning 16 courts into one fast-moving live feed and testing the future of sports television.',category:'SPORTS / MEDIA',url:LEDGERA+'/articles/us-open-redzone-espn-sports-broadcast-2026.html',image:''},
  {title:'Remembering Dolly Parton, 1946–2026',summary:'The songs made her immortal. The generosity, business instinct and radical warmth made her something even bigger.',category:'REMEMBRANCE / MUSIC / CULTURE',url:LEDGERA+'/articles/remembering-dolly-parton-1946-2026.html',image:'https://cdn.prod.website-files.com/6a8deb242351864903af5057/6a8dfd7b4e874c9803980efe_Dolly%20Main.avif'},
  {title:'Remembering Hayden Panettiere',summary:'The Heroes, Nashville and Scream star leaves behind more than three decades of work across television, film and music.',category:'REMEMBRANCE / CULTURE',url:LEDGERA+'/articles/hayden-panettiere-dies-at-36.html',image:''},
  {title:'How to Feed a Dictator',summary:'Andrew Neel’s documentary turns private kitchens into a study of power, complicity and survival.',category:'FILM / TRIBECA',url:LEDGERA+'/articles/how-to-feed-a-dictator-tribeca-2026.html',image:''},
  {title:'The Robin Byrd Story',summary:'New York cable-access history finally gets the documentary spotlight it deserves.',category:'CULTURE / TRIBECA',url:LEDGERA+'/articles/the-robin-byrd-story-tribeca-2026.html',image:''},
  {title:'Met Gala 2026',summary:'Fashion’s biggest night, the politics of the guest list, and who gets to define the room.',category:'FASHION',url:LEDGERA+'/articles/met-gala-2026-predictions-and-politics.html',image:''},
  {title:'Why Vinyl Keeps Climbing',summary:'Physical media is not nostalgia anymore — it is identity, ritual and a billion-dollar signal.',category:'MUSIC',url:LEDGERA+'/articles/why-vinyl-sales-keep-climbing.html',image:''},
  {title:'Celebrity Brand Deals in 2026: Who Is Actually Cashing In',summary:'From equity stakes to co-ownership, the smartest celebrities are building businesses — not just collecting checks.',category:'BUSINESS / CULTURE',url:LEDGERA+'/articles/celebrity-brand-deals-2026-who-is-cashing-in.html',image:''}
];
const issues = [
  {title:'RUNWAY SEVEN.',subtitle:'37 pages from Runway 7 at New York Fashion Week.',label:'SPECIAL EDITION / NYFW / SEPT. 2026',url:LEDGERA+'/magazine/runway-7-nyfw/',cover:'https://gcdn.picsart.com/editing-temp/38a8dae5-d809-42ae-bfa4-e953de41b213.jpeg'},
  {title:'TOWER OF ELEGANCE.',subtitle:'M by Elegance on championship gold, pressure, branding and presence.',label:'ISSUE NO. 05 / 2026',url:LEDGERA+'/magazine/issue-05/',cover:'https://gcdn.picsart.com/editing-temp/fac7efda-c422-4bfa-9bea-5cda7afc3e82.jpeg'},
  {title:'WIND SHIFTS',subtitle:'A New Direction · The Same Purpose · Culture in Motion',label:'ISSUE NO. 04',url:LEDGERA+'/magazine/issue-04/',cover:LEDGERA+'/assets/covers/ledgera-issue-04-wind-shifts.jpeg'},
  {title:'THE NIGHT ISSUE',subtitle:'Monster Squad · New Energy · Summer After Dark',label:'ISSUE NO. 03',url:LEDGERA+'/magazine/issue-03/',cover:LEDGERA+'/assets/covers/ledgera-issue-03-monster-squad-cover.jpeg'},
  {title:'THE POWER ISSUE',subtitle:'Karmen Petrovic · Confidence · Discipline',label:'ISSUE NO. 02',url:LEDGERA+'/magazine/issue-02/',cover:LEDGERA+'/assets/covers/ledgera-issue-02-karmen-petrovic-cover.png'},
  {title:'THE SUMMER ISSUE',subtitle:'New Faces · Culture · Tribeca',label:'ISSUE NO. 01',url:LEDGERA+'/magazine/issue-01/',cover:LEDGERA+'/assets/covers/ledgera-issue-01-cover.png'}
];

const fallbackMarkets = [
  {id:'fallback-film',source:'PULSE',title:'Will a major streaming title announce a renewal this month?',yes:63,no:37,volume24h:0,endDate:'2026-09-30T23:59:00-05:00'},
  {id:'fallback-music',source:'PULSE',title:'Will a major artist announce a surprise release before October?',yes:58,no:42,volume24h:0,endDate:'2026-10-01T00:00:00-05:00'}
];

const state = {
  tab: localStorage.getItem('pulse.tab') || 'feed',
  creatorIndex: Number(localStorage.getItem('pulse.creatorIndex') || 0),
  matches: JSON.parse(localStorage.getItem('pulse.matches') || '[]'),
  live: {news:[],markets:[],generatedAt:null,sources:[]},
  liveStatus: 'loading',
  wallet: {pulse_bucks:250,cash_cents:0,last_daily_claim:null},
  rewards: {},
  transactions: [],
  aiMessages: [],
  aiMode: 'signal',
  deferredInstall: null,
  articles: fallbackArticles,
  session: JSON.parse(localStorage.getItem('pulse.session.v1') || 'null')
};

function getDeviceId(){
  let id = localStorage.getItem('pulse.device');
  if(!id){
    const rand = crypto?.getRandomValues ? [...crypto.getRandomValues(new Uint8Array(16))].map(x=>x.toString(16).padStart(2,'0')).join('') : Math.random().toString(36).slice(2)+Date.now().toString(36);
    id = 'pulse_' + rand.slice(0,36);
    localStorage.setItem('pulse.device',id);
  }
  return id;
}
const DEVICE_ID = getDeviceId();

function save(){
  localStorage.setItem('pulse.tab', state.tab);
  localStorage.setItem('pulse.creatorIndex', state.creatorIndex);
  localStorage.setItem('pulse.matches', JSON.stringify(state.matches));
}

function esc(v=''){ return String(v).replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c])); }
function moneyCents(cents){ return (Number(cents||0)/100).toLocaleString('en-US',{style:'currency',currency:'USD'}); }
function compact(n){ return Number(n||0) ? Intl.NumberFormat('en',{notation:'compact',maximumFractionDigits:1}).format(Number(n||0)) : '—'; }
function haptic(){ if(navigator.vibrate) navigator.vibrate(8); }
function toast(msg){
  let el=$('.toast'); if(!el){el=document.createElement('div');el.className='toast';document.body.appendChild(el)}
  el.textContent=msg; el.classList.add('show'); clearTimeout(window.__pulseToast); window.__pulseToast=setTimeout(()=>el.classList.remove('show'),2200);
}
function openModal(html, cls=''){
  $('#modalCard').className='modal-card '+cls;
  $('#modalCard').innerHTML=html;
  $('#modal').showModal();
  haptic();
}
function closeModal(){ if($('#modal')?.open) $('#modal').close(); }

function timeLeft(iso){
  if(!iso) return 'LIVE';
  const ms = new Date(iso) - new Date();
  if(!Number.isFinite(ms) || ms <= 0) return 'CLOSING';
  const d=Math.floor(ms/86400000), h=Math.floor(ms%86400000/3600000), m=Math.floor(ms%3600000/60000);
  if(d>0) return d+'D '+h+'H';
  return h+'H '+m+'M';
}
function signed(n){
  const x=Number(n||0);
  if(!x) return '0.0';
  return (x>0?'+':'')+x.toFixed(1);
}
function iconForSource(source){
  return source==='POLYMARKET'?'P':source==='KALSHI'?'K':'●';
}
function appInstalled(){
  return window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;
}

function localWallet(){
  const saved=JSON.parse(localStorage.getItem('pulse.wallet.local.v1') || 'null');
  if(saved) state.wallet=saved;
  else localStorage.setItem('pulse.wallet.local.v1',JSON.stringify(state.wallet));
  state.rewards={
    'after-dark-pass':{cost:100,label:'LEDGERA After Dark access badge'},
    'creator-boost':{cost:250,label:'24-hour creator profile boost'},
    'issue-drop':{cost:500,label:'LEDGERA digital issue drop'},
    'profile-review':{cost:1000,label:'LSMG creative profile review request'}
  };
}
function saveLocalWallet(){ localStorage.setItem('pulse.wallet.local.v1',JSON.stringify(state.wallet)); }
async function walletAction(action,extra={}){
  localWallet();
  if(action==='deposit'||action==='withdraw'){ paymentRailModal(action); return null; }
  if(action==='claim_daily'){
    const today=new Date().toISOString().slice(0,10);
    if(state.wallet.last_daily_claim===today){toast('Daily Pulse Bucks already claimed');return null;}
    state.wallet.pulse_bucks=Number(state.wallet.pulse_bucks||0)+50; state.wallet.last_daily_claim=today; saveLocalWallet(); return {ok:true};
  }
  if(action==='redeem'){
    const reward=state.rewards[extra.reward_key]; if(!reward) return null;
    if(Number(state.wallet.pulse_bucks||0)<reward.cost){toast('Not enough Pulse Bucks');return null;}
    state.wallet.pulse_bucks-=reward.cost; saveLocalWallet(); return {ok:true};
  }
  return null;
}
function isCultureMarket(text=''){
  const t=text.toLowerCase();
  const culture=['movie','film','box office','oscar','grammy','emmy','album','song','music','artist','singer','rapper','concert','tour','billboard','spotify','netflix','hbo','disney','marvel','celebrity','actor','actress','television','streaming','fashion','runway','designer','wrestling','wwe','aew','tna','youtube','tiktok','creator','influencer','award'];
  const blocked=['election','president','senate','congress','parliament','minister','governor','mayor','democrat','republican'];
  return culture.some(x=>t.includes(x))&&!blocked.some(x=>t.includes(x));
}
async function loadLive(){
  state.liveStatus='loading';
  const markets=[];
  try{
    const r=await fetch('https://gamma-api.polymarket.com/markets?active=true&closed=false&limit=250&order=volume24hr&ascending=false',{cache:'no-store'});
    if(r.ok){ const data=await r.json(); for(const m of data){
      if(!isCultureMarket((m.question||'')+' '+(m.events?.[0]?.title||''))) continue;
      let outcomes=[],prices=[]; try{outcomes=JSON.parse(m.outcomes||'[]')}catch{} try{prices=JSON.parse(m.outcomePrices||'[]')}catch{}
      const yi=outcomes.findIndex(x=>String(x).toLowerCase()==='yes'); if(yi<0) continue;
      const yes=Math.max(0,Math.min(100,Math.round(Number(prices[yi]||0)*100)));
      markets.push({id:'poly-'+m.id,source:'POLYMARKET',title:m.question,yes,no:100-yes,volume24h:Number(m.volume24hr||0),change24h:Number(m.oneDayPriceChange||0)*100,endDate:m.endDate||m.endDateIso||'',image:m.image||m.icon||''});
      if(markets.length>=14) break;
    }}
  }catch{}
  try{
    const r=await fetch(LEDGERA+'/feed.json',{cache:'no-store'});
    if(r.ok){ const feed=await r.json(); if(Array.isArray(feed.items)) state.articles=feed.items.map(x=>({title:x.title||'LEDGERA',summary:x.summary||'',category:x._ledgera?.category||x.tags?.join(' / ')||'LEDGERA',url:x.url||x.id,image:x.image||''})); }
  }catch{}
  state.live={news:state.articles.map(a=>({title:a.title,url:a.url,domain:'LEDGERA',image:a.image||''})),markets:markets.length?markets:fallbackMarkets,generatedAt:new Date().toISOString(),sources:markets.length?['Polymarket']:['PULSE SNAPSHOT']};
  state.liveStatus=markets.length?'live':'fallback';
  if(state.tab==='feed'||state.tab==='predict') render();
}
async function loadWallet(){ localWallet(); if(state.tab==='me') render(); }
function installChip(){
  if(appInstalled()) return '<span class="app-mode-pill">APP MODE</span>';
  return '<button class="app-mode-pill install-chip" id="installApp">INSTALL APP</button>';
}

function feed(){
  const liveNews = state.live.news.length ? state.live.news.slice(0,8).map((a,i)=>`
    <a class="live-story" href="${esc(a.url)}" target="_blank" rel="noopener">
      <div class="live-story-img" ${a.image?`style="background-image:linear-gradient(180deg,transparent 28%,rgba(0,0,0,.88)),url('${esc(a.image)}')"`:''}>
        <span>${i<2?'BREAKING':'NOW'}</span>
      </div>
      <div class="live-story-copy"><b>${esc(a.title)}</b><small>${esc(a.domain||'LIVE SOURCE')} · AUTO-UPDATED</small></div>
    </a>`).join('') : `
      <div class="live-fallback"><div class="skeleton sk-line"></div><div class="skeleton sk-line short"></div><span>${state.liveStatus==='loading'?'SYNCING LIVE CULTURE…':'LIVE FEED WILL RETRY AUTOMATICALLY'}</span></div>`;

  const pulseSignals=(state.live.markets.length?state.live.markets:fallbackMarkets).slice(0,3).map(m=>`
    <button class="signal-mini" data-market="${esc(m.id)}">
      <span class="source-badge">${iconForSource(m.source)}</span>
      <div><b>${esc(m.title)}</b><small>${esc(m.source)} · ${compact(m.volume24h)} 24H VOL</small></div>
      <strong>${Number(m.yes||0)}%</strong>
    </button>`).join('');

  const faceRail=creators.map((c,i)=>`
    <button class="face-tile" data-face="${i}">
      <img src="${c.image}" alt="${esc(c.name)}" loading="lazy">
      <span><b>${esc(c.name)}</b><small>${esc(c.role)}</small></span>
    </button>`).join('');

  return `
  <section class="hero app-card">
    <div class="hero-grid"></div>
    <div class="hero-topline"><div class="live-pill"><i></i> PULSE LIVE</div>${installChip()}</div>
    <div class="brand-lockup"><span>LSMG</span><em>×</em><span>LEDGERA</span></div>
    <h1>THE CULTURE<br><mark>IN MOTION.</mark></h1>
    <p>Watch the network. Track live public prediction signals. Find collaborators. Ask PULSE AI what is moving.</p>
    <div class="cta-row"><button class="btn primary" data-go="predict">LIVE SIGNALS</button><button class="btn ghost" data-go="watch">WATCH</button></div>
  </section>

  <div class="ticker"><span class="ticker-label">LIVE</span><div class="ticker-track"><span>ENTERTAINMENT</span><b>•</b><span>FASHION</span><b>•</b><span>MUSIC</span><b>•</b><span>FILM</span><b>•</b><span>WRESTLING</span><b>•</b><span>CREATORS</span><b>•</b><span>PREDICTIONS</span></div></div>

  <div class="section-kicker"><span><b>PULSE SIGNAL</b> / LIVE PREDICTIONS</span><button class="text-btn" data-go="predict">SEE ALL →</button></div>
  <div class="signal-stack">${pulseSignals}</div>

  <div class="section-kicker"><span><b>NOW</b> / CULTURE WIRE</span><button class="text-btn" id="refreshLive">REFRESH ↻</button></div>
  <div class="live-grid">${liveNews}</div>

  <div class="section-kicker"><span><b>WATCH</b> / NEW CUT</span><span>LSMG × LEDGERA</span></div>
  <article class="feature-video-card app-card" data-go="watch">
    <div class="feature-video-poster" style="background-image:linear-gradient(180deg,transparent 18%,rgba(0,0,0,.9)),url('${VIDEO_POSTER}')">
      <div class="play-orb">▶</div><div class="feature-tag">LEDGERA FASHION EDIT · NEW</div><h2>WATCH THE<br>NEW CUT.</h2>
    </div>
  </article>

  <div class="section-kicker"><span><b>CONNECT</b> / LEDGERA FACES</span><button class="text-btn" data-go="connect">DISCOVER →</button></div>
  <div class="face-rail">${faceRail}</div>

  <a class="network-banner" href="https://ledgeramagazine.com/coverage/" target="_blank" rel="noopener" style="background-image:linear-gradient(90deg,rgba(0,0,0,.92),rgba(0,0,0,.45)),url('${TRIBECA_IMAGE}')">
    <span>FROM THE NETWORK</span><strong>LSMG FIELD ARCHIVE</strong><small>Interviews · Festivals · Fashion · Film · Culture →</small>
  </a>`;
}

function watch(){
  return `
  <div class="screen-title"><div><small>PULSE TV</small><h1>WATCH.</h1></div><span>LSMG × LEDGERA</span></div>
  <article class="video-shell app-card">
    <video controls playsinline preload="metadata" poster="${VIDEO_POSTER}" src="${VIDEO_URL}"></video>
    <div class="video-copy"><div><span class="category">LEDGERA / FASHION</span><h2>LEDGERA FASHION EDIT</h2><p>New visual from the LSMG × LEDGERA network.</p></div><span class="live-badge">NEW</span></div>
  </article>
  <div class="section-kicker"><span>CHANNELS</span><span>SWIPE THROUGH PULSE</span></div>
  <div class="channel-grid">
    <a class="channel-card" href="https://lastshotmediagroup.com/watch" target="_blank"><small>LSMG</small><strong>ORIGINALS</strong><span>Podcast · Interviews · BTS</span></a>
    <a class="channel-card red" href="https://ledgeramagazine.com/after-dark/" target="_blank"><small>LEDGERA</small><strong>AFTER DARK</strong><span>Night edition · Visual culture</span></a>
    <a class="channel-card" href="https://ledgeramagazine.com/coverage/" target="_blank"><small>FIELD</small><strong>ARCHIVE</strong><span>Festivals · Sports · Film · Events</span></a>
  </div>
  <div class="section-kicker"><span>FROM LEDGERA</span></div>
  <div class="face-rail">${creators.map((c,i)=>`<button class="face-tile" data-face="${i}"><img src="${c.image}" alt="${esc(c.name)}" loading="lazy"><span><b>${esc(c.name)}</b><small>${esc(c.role)}</small></span></button>`).join('')}</div>`;
}

function predict(){
  const markets=state.live.markets.length?state.live.markets:fallbackMarkets;
  const updated=state.live.generatedAt?new Date(state.live.generatedAt).toLocaleTimeString([], {hour:'numeric',minute:'2-digit'}):'SYNCING';
  return `
  <div class="screen-title"><div><small>PUBLIC MARKET DATA</small><h1>PREDICT.</h1></div><span><i class="live-dot"></i> ${updated}</span></div>

  <section class="wallet-strip app-card">
    <div><small>CASH WALLET</small><strong>${moneyCents(state.wallet.cash_cents)}</strong><span>PAYMENT RAIL REQUIRED</span></div>
    <div class="wallet-mini-actions"><button data-cash="deposit">DEPOSIT</button><button data-cash="withdraw">WITHDRAW</button></div>
  </section>

  <section class="bucks-strip app-card">
    <div><small>PULSE BUCKS</small><strong>₱${Number(state.wallet.pulse_bucks||0).toLocaleString()}</strong><span>PULSE DIGITAL CURRENCY</span></div>
    <button class="wallet-btn" id="tradeBucks">TRADE IN</button>
  </section>

  <div class="market-disclosure">LIVE PRICES BELOW ARE PUBLIC SIGNALS FROM EXTERNAL PREDICTION MARKETS. THEY MOVE IN REAL TIME AND ARE NOT GUARANTEES.</div>

  <div class="section-kicker"><span><b>LIVE</b> / CULTURE MARKETS</span><button class="text-btn" id="refreshPredictions">REFRESH ↻</button></div>
  <div class="market-list">
  ${markets.map(m=>`
    <article class="market-card app-card">
      <div class="market-top"><span class="source-pill">${esc(m.source||'PULSE')}</span><span class="close-time">${timeLeft(m.endDate)}</span></div>
      ${m.image?`<div class="market-image" style="background-image:linear-gradient(180deg,transparent,rgba(0,0,0,.75)),url('${esc(m.image)}')"></div>`:''}
      <h3>${esc(m.title)}</h3>
      <div class="market-meta"><span>${compact(m.volume24h)} 24H VOL</span><span>${signed(m.change24h)} PTS 24H</span></div>
      <div class="market-prob"><div><small>YES</small><strong>${Number(m.yes||0)}%</strong></div><div class="prob-track"><span style="width:${Math.max(2,Math.min(98,Number(m.yes||0)))}%"></span></div><div class="no"><small>NO</small><strong>${Number(m.no||0)}%</strong></div></div>
      <div class="market-actions"><button data-market="${esc(m.id)}">DETAILS</button><button class="ai-market" data-ai-market="${esc(m.id)}">ASK AI ✦</button></div>
    </article>`).join('')}
  </div>
  <div class="market-source-note">Market data: ${esc((state.live.sources||[]).filter(s=>s!=='GDELT').join(' + ')||'live public sources')}. PULSE is displaying market information; it is not routing orders to those services.</div>`;
}

function connect(){
  const c=creators[state.creatorIndex%creators.length];
  return `
  <div class="screen-title"><div><small>CREATIVE NETWORK</small><h1>CONNECT.</h1></div><span>${state.creatorIndex%creators.length+1} / ${creators.length}</span></div>
  <div class="connect-wrap">
    <article class="creator-card app-card" id="creatorCard">
      <div class="creator-visual" style="background-image:linear-gradient(180deg,transparent 35%,rgba(0,0,0,.85)),url('${c.image}')">
        <div><span class="creator-role">${esc(c.role)}</span><h2>${esc(c.name)}</h2><div class="creator-location">${esc(c.loc)}</div></div>
      </div>
      <div class="creator-copy">
        <div class="chips">${c.skills.map(s=>`<span class="chip">${esc(s)}</span>`).join('')}</div>
        <div class="need"><b>LOOKING FOR</b>${esc(c.need)}</div>
        <a href="${c.url}" target="_blank" rel="noopener" class="profile-link">VIEW LEDGERA PROFILE ↗</a>
      </div>
    </article>
    <div class="connect-actions"><button class="round-action" data-swipe-card="skip">×</button><button class="round-action star" data-swipe-card="save">☆</button><button class="round-action like" data-swipe-card="like">♡</button></div>
  </div>`;
}

function me(){
  return `
  <div class="screen-title"><div><small>PULSE ID</small><h1>YOU.</h1></div>${installChip()}</div>
  <section class="profile-head app-card"><div class="profile-row"><div class="profile-avatar">ZH</div><div><h2>PULSE PROFILE</h2><p>LSMG × LEDGERA NETWORK</p></div></div></section>
  <div class="profile-grid app-card">
    <div class="profile-stat"><strong>${state.matches.length}</strong><span>CONNECTIONS</span></div>
    <div class="profile-stat"><strong>₱${Number(state.wallet.pulse_bucks||0)}</strong><span>PULSE BUCKS</span></div>
    <div class="profile-stat"><strong>${state.liveStatus==='live'?'LIVE':'ON'}</strong><span>SIGNAL</span></div>
  </div>

  <div class="section-kicker"><span><b>WALLET</b> / PULSE BUCKS</span></div>
  <section class="bucks-wallet app-card">
    <div class="bucks-balance"><div><small>AVAILABLE</small><strong>₱${Number(state.wallet.pulse_bucks||0).toLocaleString()}</strong></div><span>PULSE BUCKS</span></div>
    <div class="bucks-actions"><button id="claimDaily">DAILY DROP +50</button><button id="tradeBucks">TRADE IN</button></div>
  </section>

  <div class="section-kicker"><span><b>CASH</b> / WALLET RAIL</span></div>
  <section class="cash-wallet app-card">
    <div><small>AVAILABLE CASH</small><strong>${moneyCents(state.wallet.cash_cents)}</strong><span>Provider connection required before funds can move.</span></div>
    <div><button data-cash="deposit">DEPOSIT</button><button data-cash="withdraw">WITHDRAW</button></div>
  </section>

  <div class="section-kicker"><span>ACCOUNT</span></div>
  <div class="settings-list app-card">
    <button id="openAISettings"><span>PULSE AI</span><b>${state.aiMode==='ai'?'CONNECTED':'SIGNAL MODE'}</b></button>
    <button><span>Creative connections</span><b>${state.matches.length}</b></button>
    <button><span>Live culture alerts</span><b>ON</b></button>
    <button id="installSettings"><span>Install PULSE to home screen</span><b>${appInstalled()?'INSTALLED':'›'}</b></button>
  </div>

  ${state.transactions.length?`<div class="section-kicker"><span>RECENT ACTIVITY</span></div><div class="tx-list">${state.transactions.slice(0,6).map(tx=>`<div><span><b>${esc(String(tx.kind||'activity').replaceAll('_',' ').toUpperCase())}</b><small>${new Date(tx.created_at).toLocaleDateString()}</small></span><strong class="${Number(tx.amount)>=0?'pos':''}">${tx.currency==='PB'?'₱':''}${Number(tx.amount)>=0?'+':''}${Number(tx.amount)}</strong></div>`).join('')}</div>`:''}`;
}

function render(){
  const view=$('#view');
  view.classList.remove('view-enter');
  view.innerHTML=({feed,watch,predict,connect,me}[state.tab]||feed)();
  requestAnimationFrame(()=>view.classList.add('view-enter'));
  $$('.nav-item').forEach(b=>b.classList.toggle('active',b.dataset.tab===state.tab));
  bind();
}

function setTab(t){
  if(t===state.tab) return;
  haptic();
  state.tab=t; save(); render();
  window.scrollTo({top:0,behavior:'smooth'});
}

function paymentRailModal(action){
  openModal(`<button class="modal-close" data-close>×</button><span class="category">CASH WALLET</span><h2>${String(action).toUpperCase()}</h2>
  <div class="big-status">PAYMENT RAIL<br>NOT CONNECTED</div>
  <p>The wallet interface and ledger are built. Real deposits and withdrawals stay locked until a payment/settlement provider that approves the operator's exact licensed prediction-wagering use case is connected.</p>
  <div class="status-grid"><span><b>✓</b> WALLET UI</span><span><b>✓</b> SERVER LEDGER</span><span><b>✓</b> TX / FL GATING UI</span><span class="pending"><b>○</b> CASH PROVIDER</span></div>
  <button class="btn primary full" data-close>GOT IT</button>`);
}

function tradeModal(){
  const items=Object.entries(state.rewards||{});
  const catalog=items.length?items:[
    ['after-dark-pass',{cost:100,label:'LEDGERA After Dark access badge'}],
    ['creator-boost',{cost:250,label:'24-hour creator profile boost'}],
    ['issue-drop',{cost:500,label:'LEDGERA digital issue drop'}],
    ['profile-review',{cost:1000,label:'LSMG creative profile review request'}]
  ];
  openModal(`<button class="modal-close" data-close>×</button><span class="category">PULSE BUCKS</span><h2>TRADE IN.</h2>
  <div class="modal-balance">AVAILABLE <strong>₱${Number(state.wallet.pulse_bucks||0).toLocaleString()}</strong></div>
  <p>Pulse Bucks are PULSE's digital currency inside the app. Earn them, hold them, and trade them for PULSE / LEDGERA / LSMG drops, access, boosts, and experiences. They are separate from your cash wallet.</p>
  <div class="reward-list">${catalog.map(([key,r])=>`<button data-redeem="${esc(key)}"><span><b>${esc(r.label)}</b><small>PULSE BUCKS MARKET</small></span><strong>₱${Number(r.cost)}</strong></button>`).join('')}</div>`);
}

function marketModal(id){
  const m=[...state.live.markets,...fallbackMarkets].find(x=>x.id===id);
  if(!m) return;
  openModal(`<button class="modal-close" data-close>×</button><span class="source-pill">${esc(m.source||'PULSE')}</span><h2>${esc(m.title)}</h2>
  ${m.image?`<img class="modal-market-image" src="${esc(m.image)}" alt="">`:''}
  <div class="detail-prob"><div><small>YES</small><strong>${Number(m.yes||0)}%</strong></div><div><small>NO</small><strong>${Number(m.no||0)}%</strong></div></div>
  <div class="detail-stats"><span>24H VOLUME <b>${compact(m.volume24h)}</b></span><span>24H MOVE <b>${signed(m.change24h)} pts</b></span><span>CLOSES <b>${timeLeft(m.endDate)}</b></span></div>
  <p>This is a live public prediction-market signal shown for context. Price is not certainty and PULSE does not route orders to this external market.</p>
  <button class="btn primary full" data-ai-market="${esc(m.id)}">ASK PULSE AI ✦</button>`);
}

function faceModal(i){
  const c=creators[Number(i)];
  if(!c) return;
  openModal(`<button class="modal-close" data-close>×</button><img class="face-modal-image" src="${c.image}" alt="${esc(c.name)}"><span class="category">LEDGERA FACES</span><h2>${esc(c.name)}</h2><p>${esc(c.need)}</p><div class="chips">${c.skills.map(x=>`<span class="chip">${esc(x)}</span>`).join('')}</div><a class="btn primary full link-btn" href="${c.url}" target="_blank" rel="noopener">VIEW PROFILE ↗</a>`);
}

function aiModal(prefill=''){
  const msgs=state.aiMessages.slice(-6).map(m=>`<div class="ai-msg ${m.role}"><span>${m.role==='assistant'?'PULSE AI':'YOU'}</span><p>${esc(m.text)}</p></div>`).join('');
  openModal(`<button class="modal-close" data-close>×</button><div class="ai-head"><span class="ai-orb">✦</span><div><small>PULSE AI</small><h2>ASK WHAT'S NEXT.</h2></div></div>
    <div class="ai-mode"><i></i><span id="aiModeLabel">${state.aiMode==='ai'?'GENERATIVE AI':'LIVE SIGNAL ENGINE'}</span></div>
    <div class="ai-chat" id="aiChat">${msgs||'<div class="ai-welcome">Ask about an artist, show, film, fashion trend, wrestling story, headline, or any live prediction on screen.</div>'}</div>
    <div class="ai-quick"><button data-ai-quick="What are the biggest culture prediction signals right now?">BIGGEST SIGNALS</button><button data-ai-quick="What culture headlines should I know right now?">HEADLINES</button></div>
    <form id="aiForm" class="ai-form"><input id="aiInput" autocomplete="off" placeholder="Ask PULSE AI…" value="${esc(prefill)}"><button>↑</button></form>`, 'ai-sheet');
  setTimeout(()=>$('#aiInput')?.focus(),100);
}

async function sendAI(prompt){
  const p=String(prompt||'').trim();
  if(!p) return;
  state.aiMessages.push({role:'user',text:p});
  const chat=$('#aiChat');
  if(chat) chat.innerHTML=state.aiMessages.slice(-6).map(m=>`<div class="ai-msg ${m.role}"><span>${m.role==='assistant'?'PULSE AI':'YOU'}</span><p>${esc(m.text)}</p></div>`).join('')+'<div class="ai-thinking">PULSE IS READING THE SIGNAL…</div>';
  try{
    const response=await fetch('/api/ai',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({prompt:p,context:{markets:state.live.markets.slice(0,12),news:state.live.news.slice(0,12)}})});
    const data=await response.json();
    state.aiMode=data.mode==='ai'?'ai':'signal';
    state.aiMessages.push({role:'assistant',text:data.answer||'No answer returned.'});
  }catch(e){
    state.aiMessages.push({role:'assistant',text:'The AI endpoint is reconnecting. Live PULSE signals are still updating in the app.'});
  }
  const c=$('#aiChat');
  if(c){c.innerHTML=state.aiMessages.slice(-7).map(m=>`<div class="ai-msg ${m.role}"><span>${m.role==='assistant'?'PULSE AI':'YOU'}</span><p>${esc(m.text)}</p></div>`).join('');c.scrollTop=c.scrollHeight;}
  if($('#aiModeLabel')) $('#aiModeLabel').textContent=state.aiMode==='ai'?'GENERATIVE AI':'LIVE SIGNAL ENGINE';
}

function installApp(){
  if(appInstalled()){toast('PULSE is already in app mode');return;}
  if(state.deferredInstall){
    state.deferredInstall.prompt();
    state.deferredInstall.userChoice.finally(()=>{state.deferredInstall=null;});
    return;
  }
  const ios=/iphone|ipad|ipod/i.test(navigator.userAgent);
  openModal(`<button class="modal-close" data-close>×</button><span class="category">INSTALL PULSE</span><h2>MAKE IT AN APP.</h2><p>${ios?'On iPhone: tap the Share button in Safari, then choose “Add to Home Screen.” PULSE opens full-screen with its own app icon.':'Open your browser menu and choose “Install app” or “Add to Home screen.”'}</p><div class="install-preview"><img src="/assets/icon-192.png" alt=""><span><b>PULSE</b><small>LSMG × LEDGERA</small></span></div>`);
}

function bind(){
  $$('[data-go]').forEach(b=>b.onclick=()=>setTab(b.dataset.go));
  $('#refreshLive')?.addEventListener('click',loadLive);
  $('#refreshPredictions')?.addEventListener('click',loadLive);
  $('#claimDaily')?.addEventListener('click',async()=>{const d=await walletAction('claim_daily');if(d){toast('+50 Pulse Bucks');render();}});
  $$('#tradeBucks, #tradeBucks').forEach(b=>b.onclick=tradeModal);
  $$('[data-cash]').forEach(b=>b.onclick=()=>walletAction(b.dataset.cash));
  $$('[data-market]').forEach(b=>b.onclick=()=>marketModal(b.dataset.market));
  $$('[data-ai-market]').forEach(b=>b.onclick=()=>{
    const m=[...state.live.markets,...fallbackMarkets].find(x=>x.id===b.dataset.aiMarket);
    closeModal(); aiModal(m?`Break down this live prediction signal: ${m.title}`:'Break down this market.');
  });
  $$('[data-face]').forEach(b=>b.onclick=()=>faceModal(b.dataset.face));
  $$('[data-swipe-card]').forEach(b=>b.onclick=()=>{
    const action=b.dataset.swipeCard; const c=creators[state.creatorIndex%creators.length];
    if(action==='like' && !state.matches.includes(c.name)){state.matches.push(c.name);toast('Connection saved');}
    else if(action==='save') toast('Profile saved');
    state.creatorIndex=(state.creatorIndex+1)%creators.length;save();render();
  });
  $$('#installApp, #installSettings').forEach(b=>b.onclick=installApp);
  $('#openAISettings')?.addEventListener('click',()=>aiModal());
}

$('#searchBtn')?.addEventListener('click',()=>{
  openModal(`<button class="modal-close" data-close>×</button><span class="category">PULSE SEARCH</span><h2>SEARCH EVERYTHING.</h2><input class="search-box" id="searchInput" placeholder="Creators, stories, live markets…"><div id="searchResults" class="search-results"></div>`);
  $('#searchInput')?.addEventListener('input',e=>{
    const q=e.target.value.trim().toLowerCase(); const results=[];
    if(q){
      state.live.news.filter(x=>String(x.title).toLowerCase().includes(q)).slice(0,4).forEach(x=>results.push(`<a class="search-result" target="_blank" href="${esc(x.url)}"><b>${esc(x.title)}</b><span>LIVE STORY · ${esc(x.domain)}</span></a>`));
      state.live.markets.filter(x=>String(x.title).toLowerCase().includes(q)).slice(0,4).forEach(x=>results.push(`<button class="search-result" data-market="${esc(x.id)}"><b>${esc(x.title)}</b><span>${esc(x.source)} · ${Number(x.yes)}% YES</span></button>`));
      creators.filter(x=>(x.name+x.role+x.skills.join(' ')).toLowerCase().includes(q)).forEach((x,i)=>results.push(`<button class="search-result" data-face-search="${creators.indexOf(x)}"><b>${esc(x.name)}</b><span>${esc(x.role)} · ${esc(x.loc)}</span></button>`));
    }
    $('#searchResults').innerHTML=results.join('')||'<div class="empty">Type to search PULSE.</div>';
    $$('[data-market]').forEach(b=>b.onclick=()=>marketModal(b.dataset.market));
    $$('[data-face-search]').forEach(b=>b.onclick=()=>faceModal(b.dataset.faceSearch));
  });
});

$('#modal')?.addEventListener('click',e=>{if(e.target===e.currentTarget)closeModal();});
document.addEventListener('click',e=>{
  if(e.target.closest('[data-close]')) closeModal();
  const r=e.target.closest('[data-redeem]');
  if(r){
    walletAction('redeem',{reward_key:r.dataset.redeem}).then(d=>{if(d){toast('Pulse Bucks traded in');closeModal();render();}});
  }
  const quick=e.target.closest('[data-ai-quick]');
  if(quick){const p=quick.dataset.aiQuick;$('#aiInput').value=p;sendAI(p);$('#aiInput').value='';}
});
document.addEventListener('submit',e=>{
  if(e.target.id==='aiForm'){
    e.preventDefault();
    const input=$('#aiInput');const p=input.value;input.value='';sendAI(p);
  }
});

$$('.nav-item').forEach(b=>b.onclick=()=>setTab(b.dataset.tab));
$('.avatar')?.addEventListener('click',()=>setTab('me'));

const aiButton=document.createElement('button');
aiButton.className='floating-ai';
aiButton.innerHTML='<span>✦</span><b>AI</b>';
aiButton.setAttribute('aria-label','Open PULSE AI');
aiButton.onclick=()=>aiModal();
document.body.appendChild(aiButton);

let touchStart=null;
document.addEventListener('touchstart',e=>{
  if(e.touches.length!==1 || $('#modal')?.open) return;
  touchStart={x:e.touches[0].clientX,y:e.touches[0].clientY};
},{passive:true});
document.addEventListener('touchend',e=>{
  if(!touchStart || $('#modal')?.open) return;
  const t=e.changedTouches[0], dx=t.clientX-touchStart.x, dy=t.clientY-touchStart.y;
  touchStart=null;
  if(Math.abs(dx)>85 && Math.abs(dx)>Math.abs(dy)*1.5){
    const tabs=['feed','watch','predict','connect','me'];
    const i=tabs.indexOf(state.tab);
    if(dx<0 && i<tabs.length-1) setTab(tabs[i+1]);
    if(dx>0 && i>0) setTab(tabs[i-1]);
  }
},{passive:true});

window.addEventListener('beforeinstallprompt',e=>{e.preventDefault();state.deferredInstall=e;render();});
window.addEventListener('appinstalled',()=>{state.deferredInstall=null;toast('PULSE installed');render();});

render();
Promise.all([loadLive(),loadWallet()]);
setInterval(loadLive,60000);
setTimeout(()=>$('#splash')?.classList.add('hide'),650);
if('serviceWorker' in navigator) navigator.serviceWorker.register('/sw.js').catch(()=>{});
