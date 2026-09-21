const $ = (s, r=document) => r.querySelector(s);
const $$ = (s, r=document) => [...r.querySelectorAll(s)];

const VIDEO_URL = 'https://gcdn.picsart.com/editing-temp/99c62c28-207d-4bde-8335-0ae90cffb03c.mp4';
const VIDEO_POSTER = 'https://gcdn.picsart.com/cloud-storage/d861daf6-993d-4610-9f56-d8fdd904bca5.jpg';
const TRIBECA_IMAGE = 'https://ledgeramagazine.com/assets/images/tribeca/lsmg-tribeca-2026-announcement.png';

const PODCAST_RSS = 'https://anchor.fm/s/127eeb74/podcast/rss';
const PODCAST_APPLE = 'https://podcasts.apple.com/us/podcast/the-last-shot-podcast/id1494831568';
const nyfwPhotos = [
  {title:'ARIAHWOLF',subtitle:'RUNWAY 7 / NYFW',image:'https://gcdn.picsart.com/editing-temp/998803ae-4a5a-4f4d-a8eb-e53a3bf299df.jpeg'},
  {title:'SHOP THE RUNWAY',subtitle:'RUNWAY 7 / NYFW',image:'https://gcdn.picsart.com/editing-temp/e4a257e4-259b-451e-9315-f5433ec478f2.jpeg'},
  {title:'SHOP THE RUNWAY',subtitle:'RUNWAY 7 / NYFW',image:'https://gcdn.picsart.com/editing-temp/f3586a10-e2f0-4a49-af19-0906f4708e4c.jpeg'},
  {title:'AJIM FASHION',subtitle:'RUNWAY 7 / NYFW',image:'https://gcdn.picsart.com/editing-temp/fbf93ad9-147b-41a9-b505-da856fdd891a.jpeg'},
  {title:'HILIA SWIM',subtitle:'RUNWAY 7 / NYFW',image:'https://gcdn.picsart.com/editing-temp/20387fcd-8ee9-4046-bdd0-ce8b0f76bf90.jpeg'},
  {title:'JANEKE LUXUEUSE',subtitle:'RUNWAY 7 / NYFW',image:'https://gcdn.picsart.com/editing-temp/67a88ecd-3b4b-4e7b-95a0-2c78820d0c27.jpeg'}
];
const stockVideos = [
  {title:'RUNWAY STUDY 01',subtitle:'FASHION B-ROLL',src:'https://gcdn.picsart.com/editing-temp/8ac49354-c10a-4f75-818f-d0e64cf19135.mp4',poster:'https://images.pexels.com/videos/9512048/pexels-photo-9512048.jpeg?auto=compress&dpr=1&h=750&w=1260',credit:'cottonbro studio / Pexels',source:'https://www.pexels.com/video/fashion-model-walking-in-the-runway-9512048/'}
];
const fallbackEpisodes = [
  {title:'An Interview With Jaylen Christie | Stink Bomb Man and the Brain Kids',date:'Sep 7, 2026',duration:'59:25',description:'Creativity, ownership, representation and building an independent comic-book universe.',link:PODCAST_APPLE,audio:''},
  {title:'The Elegance Brand: M By Elegance | An Interview With Maggie Lee',date:'Sep 6, 2026',duration:'14:13',description:'M By Elegance on wrestling, presentation, branding and building a memorable presence.',link:PODCAST_APPLE,audio:''},
  {title:'VQFF 2026: A Seat at the Table | Eli Morris on the Future of Queer Cinema',date:'Aug 27, 2026',duration:'',description:'A conversation about the future of queer cinema and the Vancouver Queer Film Festival.',link:PODCAST_APPLE,audio:''}
];


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
  session: JSON.parse(localStorage.getItem('pulse.session.v1') || 'null'),
  podcast: {status:'loading',episodes:fallbackEpisodes}
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
  try{
    const r=await fetch('/api/live',{cache:'no-store'});
    if(r.ok){
      const d=await r.json();
      if(Array.isArray(d.articles)&&d.articles.length) state.articles=d.articles;
      const markets=Array.isArray(d.markets)&&d.markets.length?d.markets:fallbackMarkets;
      state.live={news:state.articles.map(a=>({title:a.title,url:a.url,domain:'LEDGERA',image:a.image||''})),markets,generatedAt:d.generatedAt||new Date().toISOString(),sources:[...new Set(markets.map(m=>m.source))]};
      state.liveStatus=d.markets?.length?'live':'fallback';
      if(Array.isArray(d.podcast)&&d.podcast.length){state.podcast={status:'live',episodes:d.podcast.map(x=>({...x,date:episodeDate(x.date),description:stripHTML(x.description||'').slice(0,240)}))};}
      if(state.tab==='feed'||state.tab==='predict'||state.tab==='watch')render();
      return;
    }
  }catch{}
  const markets=[];
  try{
    const r=await fetch('https://gamma-api.polymarket.com/markets?active=true&closed=false&limit=120&order=volume24hr&ascending=false',{cache:'no-store'});
    if(r.ok){const data=await r.json();for(const m of data){if(!isCultureMarket(m.question||''))continue;let outcomes=[],prices=[];try{outcomes=JSON.parse(m.outcomes||'[]');prices=JSON.parse(m.outcomePrices||'[]')}catch{}const yi=outcomes.findIndex(x=>String(x).toLowerCase()==='yes');if(yi<0)continue;const yes=Math.round(Number(prices[yi]||0)*100);markets.push({id:'poly-'+m.id,source:'POLYMARKET',title:m.question,yes,no:100-yes,volume24h:Number(m.volume24hr||0),change24h:Number(m.oneDayPriceChange||0)*100,endDate:m.endDate||'',image:m.image||''});if(markets.length>=12)break}}
  }catch{}
  try{const r=await fetch(LEDGERA+'/feed.json',{cache:'no-store'});if(r.ok){const feed=await r.json();if(Array.isArray(feed.items))state.articles=feed.items.map(x=>({title:x.title||'LEDGERA',summary:x.summary||'',category:x._ledgera?.category||x.tags?.join(' / ')||'LEDGERA',url:x.url||x.id,image:x.image||''}));}}catch{}
  state.live={news:state.articles.map(a=>({title:a.title,url:a.url,domain:'LEDGERA',image:a.image||''})),markets:markets.length?markets:fallbackMarkets,generatedAt:new Date().toISOString(),sources:markets.length?['POLYMARKET']:['PULSE SNAPSHOT']};
  state.liveStatus=markets.length?'live':'fallback';if(state.tab==='feed'||state.tab==='predict')render();
}
async function loadWallet(){ localWallet(); if(state.tab==='me') render(); }

function stripHTML(html=''){
  const d=document.createElement('div'); d.innerHTML=html; return (d.textContent||'').replace(/\s+/g,' ').trim();
}
function episodeDate(raw=''){
  const d=new Date(raw); return Number.isFinite(d.getTime())?d.toLocaleDateString(undefined,{month:'short',day:'numeric',year:'numeric'}):raw;
}
function parsePodcastRSS(xml){
  const doc=new DOMParser().parseFromString(xml,'text/xml');
  if(doc.querySelector('parsererror')) throw new Error('Invalid RSS');
  return [...doc.querySelectorAll('channel > item')].slice(0,8).map(item=>{
    const enclosure=item.querySelector('enclosure');
    const image=item.getElementsByTagName('itunes:image')[0];
    const duration=item.getElementsByTagName('itunes:duration')[0]?.textContent||'';
    return {
      title:item.querySelector('title')?.textContent?.trim()||'The Last Shot Podcast',
      date:episodeDate(item.querySelector('pubDate')?.textContent||''),
      duration,
      description:stripHTML(item.querySelector('description')?.textContent||'').slice(0,220),
      link:item.querySelector('link')?.textContent?.trim()||PODCAST_APPLE,
      audio:enclosure?.getAttribute('url')||'',
      image:image?.getAttribute('href')||''
    };
  }).filter(x=>x.title);
}
async function loadPodcast(){
  state.podcast.status='loading';
  const sources=[
    PODCAST_RSS,
    'https://api.allorigins.win/raw?url='+encodeURIComponent(PODCAST_RSS)
  ];
  for(const url of sources){
    try{
      const r=await fetch(url,{cache:'no-store'});
      if(!r.ok) continue;
      const eps=parsePodcastRSS(await r.text());
      if(eps.length){state.podcast={status:'live',episodes:eps};if(state.tab==='watch')render();return;}
    }catch{}
  }
  try{
    const r=await fetch('https://api.rss2json.com/v1/api.json?rss_url='+encodeURIComponent(PODCAST_RSS),{cache:'no-store'});
    if(r.ok){
      const j=await r.json();
      if(Array.isArray(j.items)&&j.items.length){
        state.podcast={status:'live',episodes:j.items.slice(0,8).map(x=>({
          title:x.title||'The Last Shot Podcast',
          date:episodeDate(x.pubDate||''),
          duration:x.enclosure?.duration||'',
          description:stripHTML(x.description||x.content||'').slice(0,220),
          link:x.link||PODCAST_APPLE,
          audio:x.enclosure?.link||x.enclosure?.url||'',
          image:x.thumbnail||j.feed?.image||''
        }))};
        if(state.tab==='watch')render();return;
      }
    }
  }catch{}
  try{
    const r=await fetch('https://itunes.apple.com/lookup?id=1494831568&entity=podcastEpisode&limit=8&country=US',{cache:'no-store'});
    if(r.ok){
      const j=await r.json();
      const eps=(j.results||[]).filter(x=>x.wrapperType==='podcastEpisode').slice(0,8).map(x=>({
        title:x.trackName||x.collectionName||'The Last Shot Podcast',
        date:episodeDate(x.releaseDate||''),
        duration:x.trackTimeMillis?Math.round(x.trackTimeMillis/60000)+' min':'',
        description:stripHTML(x.description||x.shortDescription||'').slice(0,220),
        link:x.trackViewUrl||PODCAST_APPLE,
        audio:x.episodeUrl||'',
        image:x.artworkUrl600||x.artworkUrl100||''
      }));
      if(eps.length){state.podcast={status:'live',episodes:eps};if(state.tab==='watch')render();return;}
    }
  }catch{}
  state.podcast={status:'fallback',episodes:fallbackEpisodes};
  if(state.tab==='watch')render();
}
function podcastMarkup(limit=6){
  const eps=(state.podcast.episodes||fallbackEpisodes).slice(0,limit);
  return eps.map((e,i)=>`
    <article class="podcast-card">
      <div class="podcast-number">${String(i+1).padStart(2,'0')}</div>
      <div class="podcast-body">
        <div class="podcast-meta"><span>${esc(e.date||'THE LAST SHOT PODCAST')}</span><span>${esc(e.duration||'EPISODE')}</span></div>
        <h3>${esc(e.title)}</h3>
        <p>${esc(e.description||'The Last Shot Podcast from LSMG.')}</p>
        ${e.audio?`<audio controls preload="none" src="${esc(e.audio)}"></audio>`:''}
        <a href="${esc(e.link||PODCAST_APPLE)}" target="_blank" rel="noopener">OPEN EPISODE ↗</a>
      </div>
    </article>`).join('');
}

function userInitials(name='P'){ return String(name).trim().split(/\s+/).slice(0,2).map(x=>x[0]||'').join('').toUpperCase()||'P'; }
function bytesToB64(bytes){ return btoa(String.fromCharCode(...bytes)); }
function b64ToBytes(s){ return Uint8Array.from(atob(s),c=>c.charCodeAt(0)); }
async function passwordHash(password,salt){
  const base=await crypto.subtle.importKey('raw',new TextEncoder().encode(password),'PBKDF2',false,['deriveBits']);
  const bits=await crypto.subtle.deriveBits({name:'PBKDF2',salt,iterations:120000,hash:'SHA-256'},base,256);
  return bytesToB64(new Uint8Array(bits));
}
function playPulseBeep(){
  try{ const Ctx=window.AudioContext||window.webkitAudioContext; if(!Ctx)return; const ctx=new Ctx(); const o=ctx.createOscillator(); const g=ctx.createGain(); o.type='sine'; o.frequency.setValueAtTime(520,ctx.currentTime); o.frequency.exponentialRampToValueAtTime(880,ctx.currentTime+.06); g.gain.setValueAtTime(.0001,ctx.currentTime); g.gain.exponentialRampToValueAtTime(.07,ctx.currentTime+.01); g.gain.exponentialRampToValueAtTime(.0001,ctx.currentTime+.1); o.connect(g);g.connect(ctx.destination);o.start();o.stop(ctx.currentTime+.11);setTimeout(()=>ctx.close(),160);}catch{}
}
function showOnboarding(){
  const wrap=document.createElement('div'); wrap.className='onboarding-layer';
  wrap.innerHTML=`<div class="onboard-top"><b>PULSE.</b><button id="skipOnboard">SKIP</button></div><div class="onboard-slides">
  <section class="onboard-slide active"><div class="onboard-icon">⌁</div><small>LIVE CULTURE</small><h2>SEE WHAT'S MOVING.</h2><p>Stories, video, creators and live public culture-market signals in one place.</p></section>
  <section class="onboard-slide"><div class="onboard-icon">RA</div><small>READ INSIDE PULSE</small><h2>OPEN THE STORY.<br>FLIP THE ISSUE.</h2><p>Read LEDGERA articles and full magazine editions without leaving the app.</p></section>
  <section class="onboard-slide"><div class="onboard-icon">✦</div><small>PULSE AI</small><h2>ASK THE SIGNAL.</h2><p>Search stories, issues, creators and prediction signals conversationally.</p></section></div>
  <div class="onboard-bottom"><div class="onboard-dots"><i class="on"></i><i></i><i></i></div><button id="onboardNext">NEXT</button></div>`;
  document.body.appendChild(wrap); let i=0;
  const paint=()=>{ $$('.onboard-slide',wrap).forEach((s,n)=>s.classList.toggle('active',n===i)); $$('.onboard-dots i',wrap).forEach((d,n)=>d.classList.toggle('on',n===i)); $('#onboardNext',wrap).textContent=i===2?'CREATE ACCOUNT':'NEXT'; };
  const done=()=>{ localStorage.setItem('pulse.intro.v1','1'); wrap.classList.add('leaving'); setTimeout(()=>{wrap.remove();showAuth('create');},220); };
  $('#skipOnboard',wrap).onclick=done; $('#onboardNext',wrap).onclick=()=>{haptic(); if(i<2){i++;paint()}else done();};
}
function showAuth(mode='create'){
  let wrap=$('#pulseAuth'); if(wrap)wrap.remove(); wrap=document.createElement('div'); wrap.id='pulseAuth'; wrap.className='auth-layer';
  const create=mode==='create';
  wrap.innerHTML=`<div class="auth-card"><div class="auth-brand"><b>PULSE<span>.</span></b><small>LSMG × LEDGERA</small></div>
  <div class="auth-tabs"><button data-auth="create" class="${create?'active':''}">CREATE ACCOUNT</button><button data-auth="signin" class="${!create?'active':''}">SIGN IN</button></div>
  <form id="authForm">${create?'<label>NAME<input id="authName" autocomplete="name" required placeholder="Your name"></label>':''}<label>EMAIL<input id="authEmail" type="email" autocomplete="email" required placeholder="you@example.com"></label><label>PASSWORD<input id="authPass" type="password" minlength="6" required placeholder="6+ characters"></label><button class="auth-submit">${create?'CREATE ACCOUNT':'SIGN IN'}</button></form>
  <p class="auth-note">This no-Netlify-credit build stores the account securely on this device. Cross-device sync will use a separate auth backend before public launch.</p><button class="auth-guest" id="authGuest">CONTINUE AS GUEST</button></div>`;
  document.body.appendChild(wrap);
  $$('[data-auth]',wrap).forEach(b=>b.onclick=()=>showAuth(b.dataset.auth));
  $('#authGuest',wrap).onclick=()=>{state.session={name:'Guest',email:'guest@local'};localStorage.setItem('pulse.session.v1',JSON.stringify(state.session));wrap.remove();pulseStarted=false;startPulse();};
  $('#authForm',wrap).onsubmit=async e=>{ e.preventDefault(); const email=$('#authEmail',wrap).value.trim().toLowerCase(); const pass=$('#authPass',wrap).value; const accounts=JSON.parse(localStorage.getItem('pulse.accounts.v1')||'{}');
    if(create){ const name=$('#authName',wrap).value.trim(); if(accounts[email]){toast('Account already exists on this device');return;} const salt=crypto.getRandomValues(new Uint8Array(16)); accounts[email]={name,email,salt:bytesToB64(salt),hash:await passwordHash(pass,salt)}; localStorage.setItem('pulse.accounts.v1',JSON.stringify(accounts)); state.session={name,email}; }
    else { const acct=accounts[email]; if(!acct){toast('Account not found on this device');return;} if(await passwordHash(pass,b64ToBytes(acct.salt))!==acct.hash){toast('Password does not match');return;} state.session={name:acct.name,email}; }
    localStorage.setItem('pulse.session.v1',JSON.stringify(state.session)); wrap.remove(); pulseStarted=false; startPulse(); toast(create?'Welcome to PULSE':'Signed in');
  };
}
function bootPulse(){
  const splash=$('#splash'); const btn=$('#enterPulse');
  const enter=()=>{playPulseBeep();haptic();splash?.classList.add('exit');setTimeout(()=>{splash?.classList.add('hide'); if(!localStorage.getItem('pulse.intro.v1'))showOnboarding();else if(!state.session)showAuth('create');else startPulse();},300);};
  if(btn)btn.onclick=enter; else setTimeout(enter,1200);
}
let pulseStarted=false;
let liveTimer=null;
function startPulse(){
  if(pulseStarted)return;
  pulseStarted=true;
  const av=$('.avatar'); if(av)av.textContent=userInitials(state.session?.name||'PULSE');
  render();
  Promise.all([loadLive(),loadWallet(),loadPodcast()]);
  if(liveTimer) clearInterval(liveTimer);
  liveTimer=setInterval(loadLive,60000);
}

function installChip(){
  if(appInstalled()) return '<span class="app-mode-pill">APP MODE</span>';
  return '<button class="app-mode-pill install-chip" id="installApp">INSTALL APP</button>';
}

function feed(){
  const liveNews = state.live.news.length ? state.live.news.slice(0,8).map((a,i)=>`
    <button class="live-story" data-read-article="${i}">
      <div class="live-story-img" ${a.image?`style="background-image:linear-gradient(180deg,transparent 28%,rgba(0,0,0,.88)),url('${esc(a.image)}')"`:''}>
        <span>${i<2?'FEATURED':'READ'}</span>
      </div>
      <div class="live-story-copy"><b>${esc(a.title)}</b><small>LEDGERA · READ IN PULSE</small></div>
    </button>`).join('') : `
      <div class="live-fallback"><div class="skeleton sk-line"></div><div class="skeleton sk-line short"></div><span>${state.liveStatus==='loading'?'SYNCING LIVE CULTURE…':'LIVE FEED WILL RETRY AUTOMATICALLY'}</span></div>`;

  const pulseSignals=(state.live.markets.length?state.live.markets:fallbackMarkets).slice(0,3).map(m=>`
    <button class="signal-mini" data-market="${esc(m.id)}">
      <span class="source-badge">${iconForSource(m.source)}</span>
      <div><b>${esc(m.title)}</b><small>${esc(m.source)} · ${compact(m.volume24h)} 24H VOL</small></div>
      <strong>${Number(m.yes||0)}%</strong>
    </button>`).join('');

  const nyfwRail=nyfwPhotos.map((p,i)=>`<button class="nyfw-card" data-photo="${i}"><div class="nyfw-media" style="background-image:linear-gradient(rgba(0,0,0,.48),rgba(0,0,0,.48)),url('${p.image}')"><img src="${p.image}" alt="${esc(p.title)} at NYFW" loading="lazy"></div><span><small>${esc(p.subtitle)}</small><b>${esc(p.title)}</b></span></button>`).join('');

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

  <div class="section-kicker"><span><b>MAGAZINE</b> / READ FULL ISSUES</span><button class="text-btn" id="allIssues">ARCHIVE →</button></div>
  <div class="issue-rail">${issues.slice(0,4).map((x,i)=>`<button class="issue-card" data-read-issue="${i}"><img src="${esc(x.cover)}" alt="${esc(x.title)} cover" loading="lazy"><span><small>${esc(x.label)}</small><b>${esc(x.title)}</b><em>READ ISSUE →</em></span></button>`).join('')}</div>

  <div class="section-kicker"><span><b>NYFW</b> / FROM THE LSMG DRIVE</span><span>RUNWAY 7</span></div>
  <div class="nyfw-rail">${nyfwRail}</div>

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
  const stockRail=stockVideos.map((v,i)=>`
    <article class="stock-video-card">
      <video controls playsinline preload="metadata" poster="${esc(v.poster)}" src="${esc(v.src)}"></video>
      <div><small>${esc(v.subtitle)}</small><b>${esc(v.title)}</b><a href="${esc(v.source)}" target="_blank" rel="noopener">${esc(v.credit)} ↗</a></div>
    </article>`).join('');
  return `
  <div class="screen-title"><div><small>PULSE TV + AUDIO</small><h1>WATCH.</h1></div><span>LSMG × LEDGERA</span></div>
  <article class="video-shell app-card">
    <video controls playsinline preload="metadata" poster="${VIDEO_POSTER}" src="${VIDEO_URL}"></video>
    <div class="video-copy"><div><span class="category">LEDGERA / FASHION</span><h2>LEDGERA FASHION EDIT</h2><p>Original visual from the LSMG × LEDGERA network.</p></div><span class="live-badge">ORIGINAL</span></div>
  </article>

  <div class="section-kicker"><span><b>NYFW MOTION</b> / STOCK B-ROLL</span><span>PULSE TV</span></div>
  <div class="stock-video-rail">${stockRail}</div>

  <section id="podcastSection">
    <div class="section-kicker"><span><b>THE LAST SHOT PODCAST</b> / RSS</span><button class="text-btn" id="refreshPodcast">${state.podcast.status==='live'?'RSS LIVE':'REFRESH ↻'}</button></div>
    <div class="podcast-hero app-card">
      <div><small>LSMG AUDIO</small><h2>THE LAST SHOT<br>PODCAST.</h2><p>Latest episodes pulled from the show's RSS feed when available.</p></div>
      <a href="${PODCAST_APPLE}" target="_blank" rel="noopener">FULL CATALOG ↗</a>
    </div>
    <div class="podcast-stack">${podcastMarkup(6)}</div>
  </section>

  <div class="section-kicker"><span>CHANNELS</span><span>SWIPE THROUGH PULSE</span></div>
  <div class="channel-grid">
    <a class="channel-card" href="https://lastshotmediagroup.com/watch" target="_blank"><small>LSMG</small><strong>ORIGINALS</strong><span>Podcast · Interviews · BTS</span></a>
    <a class="channel-card red" href="https://ledgeramagazine.com/after-dark/" target="_blank"><small>LEDGERA</small><strong>AFTER DARK</strong><span>Night edition · Visual culture</span></a>
    <a class="channel-card" href="https://ledgeramagazine.com/coverage/" target="_blank"><small>FIELD</small><strong>ARCHIVE</strong><span>Festivals · Sports · Film · Events</span></a>
  </div>
  <div class="section-kicker"><span>READ LEDGERA</span><button class="text-btn" id="allIssues">MAGAZINE →</button></div>
  <div class="compact-stories">${state.articles.slice(0,4).map((a,i)=>`<button data-read-article="${i}"><span>${String(i+1).padStart(2,'0')}</span><div><small>${esc(a.category||'LEDGERA')}</small><b>${esc(a.title)}</b></div><em>›</em></button>`).join('')}</div>
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
      <div class="creator-visual">
        <div class="creator-photo-bg" style="background-image:url('${c.image}')"></div>
        <img class="creator-photo" src="${c.image}" alt="${esc(c.name)}" draggable="false">
        <div class="creator-gradient"></div>
        <div class="creator-title"><span class="creator-role">${esc(c.role)}</span><h2>${esc(c.name)}</h2><div class="creator-location">${esc(c.loc)}</div></div>
      </div>
      <div class="creator-copy">
        <div class="chips">${c.skills.map(s=>`<span class="chip">${esc(s)}</span>`).join('')}</div>
        <div class="need"><b>LOOKING FOR</b>${esc(c.need)}</div>
        <a href="${c.url}" target="_blank" rel="noopener" class="profile-link">VIEW LEDGERA PROFILE ↗</a>
      </div>
    </article>
    <div class="swipe-hint"><span>← SKIP</span><b>SWIPE THE CARD</b><span>LIKE →</span></div>
    <div class="connect-actions"><button class="round-action" data-swipe-card="skip">×</button><button class="round-action star" data-swipe-card="save">☆</button><button class="round-action like" data-swipe-card="like">♡</button></div>
  </div>`;
}

function me(){
  const u=state.session||{name:'Guest',email:'guest@local'};
  return `
  <div class="screen-title"><div><small>PULSE ID</small><h1>YOU.</h1></div>${installChip()}</div>
  <section class="profile-head app-card"><div class="profile-row"><div class="profile-avatar">${userInitials(u.name)}</div><div><h2>${esc(u.name)}</h2><p>${esc(u.email)}</p></div></div></section>
  <div class="profile-grid app-card"><div class="profile-stat"><strong>${state.matches.length}</strong><span>CONNECTIONS</span></div><div class="profile-stat"><strong>₱${Number(state.wallet.pulse_bucks||0)}</strong><span>PULSE BUCKS</span></div><div class="profile-stat"><strong>${state.liveStatus==='live'?'LIVE':'ON'}</strong><span>SIGNAL</span></div></div>
  <div class="section-kicker"><span><b>READ</b> / LEDGERA LIBRARY</span></div>
  <div class="settings-list app-card"><button id="profileStories"><span>Articles</span><b>${state.articles.length}</b></button><button id="profileIssues"><span>Magazine editions</span><b>${issues.length}</b></button><button id="openAISettings"><span>PULSE AI</span><b>ON-DEVICE</b></button></div>
  <div class="section-kicker"><span><b>WALLET</b> / PULSE BUCKS</span></div>
  <section class="bucks-wallet app-card"><div class="bucks-balance"><div><small>AVAILABLE</small><strong>₱${Number(state.wallet.pulse_bucks||0).toLocaleString()}</strong></div><span>PULSE BUCKS</span></div><div class="bucks-actions"><button id="claimDaily">DAILY DROP +50</button><button id="tradeBucks">TRADE IN</button></div></section>
  <div class="section-kicker"><span><b>CASH</b> / WALLET RAIL</span></div>
  <section class="cash-wallet app-card"><div><small>AVAILABLE CASH</small><strong>${moneyCents(state.wallet.cash_cents)}</strong><span>External payment rail required before funds can move.</span></div><div><button data-cash="deposit">DEPOSIT</button><button data-cash="withdraw">WITHDRAW</button></div></section>
  <div class="section-kicker"><span>ACCOUNT</span></div>
  <div class="settings-list app-card"><button id="installSettings"><span>Install PULSE to Home Screen</span><b>${appInstalled()?'INSTALLED':'›'}</b></button><button id="signOut"><span>Sign out</span><b>›</b></button></div>`;
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
  <p>The wallet interface is built. Real deposits and withdrawals stay locked until an approved payment/settlement provider and permitted-jurisdiction verification are connected.</p>
  <div class="status-grid"><span><b>✓</b> WALLET UI</span><span><b>✓</b> LOCAL APP WALLET</span><span><b>✓</b> PERMITTED-JURISDICTION UI</span><span class="pending"><b>○</b> CASH PROVIDER</span></div>
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

function readerShell(title,label,url){
  const layer=document.createElement('div');layer.className='reader-overlay pulse-reader';
  layer.innerHTML=`<header class="reader-bar pulse-reader-bar"><button class="reader-back" aria-label="Back">‹</button><div><small>${esc(label)}</small><b>${esc(title)}</b></div><a href="${esc(url)}" target="_blank" rel="noopener">↗</a></header><main class="native-reader"><div class="native-loading"><i></i><b>PULSE IS BUILDING THE READER…</b></div></main>`;
  document.body.appendChild(layer);$('.reader-back',layer).onclick=()=>{layer.classList.add('closing');setTimeout(()=>layer.remove(),180)};return layer;
}
function closeNativeReader(layer){layer?.classList.add('closing');setTimeout(()=>layer?.remove(),180)}
async function openArticleReader(a){
  const layer=readerShell(a.title,a.category||'LEDGERA ARTICLE',a.url),main=$('.native-reader',layer);
  try{
    const r=await fetch('/api/content?url='+encodeURIComponent(a.url),{cache:'no-store'});if(!r.ok)throw new Error('reader');
    const d=await r.json();if(d.type!=='article'||!d.paragraphs?.length)throw new Error('reader');
    main.innerHTML=`<article class="pulse-article">
      <div class="article-progress"><i></i></div>
      <header>${d.hero?`<img class="pulse-article-hero" src="${esc(d.hero)}" alt="">`:''}<span class="pulse-article-kicker">${esc(d.kicker||a.category||'LEDGERA')}</span><h1>${esc(d.title||a.title)}</h1>${d.dek?`<p class="pulse-dek">${esc(d.dek)}</p>`:''}${d.byline?`<p class="pulse-byline">${esc(d.byline)}</p>`:''}</header>
      <div class="pulse-story-body">${d.paragraphs.map((p,i)=>`<p class="${i===0?'lead':''}">${esc(p)}</p>`).join('')}</div>
      <footer><span>LEDGERA</span><b>THE RECORD OF CULTURE.</b><button class="btn primary" data-reader-close>BACK TO PULSE</button></footer>
    </article>`;
    $('[data-reader-close]',main).onclick=()=>closeNativeReader(layer);
    const progress=$('.article-progress i',main);main.addEventListener('scroll',()=>{const max=main.scrollHeight-main.clientHeight;progress.style.width=(max?Math.min(100,main.scrollTop/max*100):100)+'%'},{passive:true});
  }catch{
    main.innerHTML=`<div class="reader-error"><b>THIS STORY COULDN'T BE REFORMATTED.</b><p>Open the original LEDGERA story without leaving your reading flow.</p><a class="btn primary" href="${esc(a.url)}" target="_blank" rel="noopener">OPEN ORIGINAL ↗</a></div>`;
  }
}
function renderMagazinePage(layer,pages,index){
  const stage=$('.mag-stage',layer),status=$('.mag-status',layer),strip=$('.mag-thumbs',layer);const p=pages[index];if(!p)return;
  stage.innerHTML=`<img src="${esc(p.src)}" alt="${esc(p.alt||p.title||'Magazine page')}" draggable="false">`;
  status.innerHTML=`<small>PAGE ${String(index+1).padStart(2,'0')} / ${String(pages.length).padStart(2,'0')}</small><b>${esc(p.title||p.short||'LEDGERA')}</b><span>${esc(p.chapter||'')}</span>`;
  strip.querySelectorAll('button').forEach((b,i)=>b.classList.toggle('active',i===index));strip.querySelector(`button[data-page="${index}"]`)?.scrollIntoView({behavior:'smooth',block:'nearest',inline:'center'});
  layer.dataset.page=String(index);
}
async function openIssueReader(x){
  const layer=readerShell(x.title,x.label,x.url),main=$('.native-reader',layer);
  try{
    const r=await fetch('/api/content?url='+encodeURIComponent(x.url),{cache:'no-store'});if(!r.ok)throw new Error('reader');const d=await r.json();if(d.type!=='issue'||!d.pages?.length)throw new Error('reader');
    const pages=d.pages;main.innerHTML=`<section class="pulse-magazine">
      <div class="mag-top"><span>LEDGERA / PULSE READER</span><button data-mag-fit>FIT</button></div>
      <div class="mag-stage"></div>
      <div class="mag-controls"><button data-mag-prev>‹</button><div class="mag-status"></div><button data-mag-next>›</button></div>
      <div class="mag-thumbs">${pages.map((p,i)=>`<button data-page="${i}"><img src="${esc(p.src)}" alt=""><span>${String(i+1).padStart(2,'0')}</span></button>`).join('')}</div>
    </section>`;
    let idx=0;renderMagazinePage(layer,pages,idx);
    const go=n=>{idx=Math.max(0,Math.min(pages.length-1,n));renderMagazinePage(layer,pages,idx);haptic()};
    $('[data-mag-prev]',layer).onclick=()=>go(idx-1);$('[data-mag-next]',layer).onclick=()=>go(idx+1);
    $$('[data-page]',layer).forEach(b=>b.onclick=()=>go(Number(b.dataset.page)));
    $('[data-mag-fit]',layer).onclick=()=>layer.classList.toggle('mag-width');
    let sx=0,sy=0;const stage=$('.mag-stage',layer);stage.addEventListener('pointerdown',e=>{sx=e.clientX;sy=e.clientY;try{stage.setPointerCapture(e.pointerId)}catch{}});
    stage.addEventListener('pointerup',e=>{const dx=e.clientX-sx,dy=e.clientY-sy;if(Math.abs(dx)>55&&Math.abs(dx)>Math.abs(dy)*1.2)go(idx+(dx<0?1:-1));});
  }catch{main.innerHTML=`<div class="reader-error"><b>ISSUE READER IS RETRYING.</b><p>The original edition is still available.</p><a class="btn primary" href="${esc(x.url)}" target="_blank" rel="noopener">OPEN EDITION ↗</a></div>`;}
}
function readArticle(i){const a=state.articles[Number(i)];if(a)openArticleReader(a)}
function readIssue(i){const x=issues[Number(i)];if(x)openIssueReader(x)}
function issuesModal(){
  openModal(`<button class="modal-close" data-close>×</button><span class="category">LEDGERA MAGAZINE</span><h2>READ THE ISSUES.</h2><p>Full editions open inside PULSE in LEDGERA’s mobile reader.</p><div class="issue-library">${issues.map((x,i)=>`<button data-read-issue="${i}"><img src="${esc(x.cover)}" alt=""><span><small>${esc(x.label)}</small><b>${esc(x.title)}</b><p>${esc(x.subtitle)}</p></span></button>`).join('')}</div>`);
  $$('[data-read-issue]',$('#modalCard')).forEach(b=>b.onclick=()=>{closeModal();readIssue(b.dataset.readIssue);});
}
function allStoriesModal(){
  openModal(`<button class="modal-close" data-close>×</button><span class="category">LEDGERA</span><h2>ALL STORIES.</h2><div class="article-library">${state.articles.map((a,i)=>`<button data-read-article="${i}"><span>${String(i+1).padStart(2,'0')}</span><div><small>${esc(a.category||'LEDGERA')}</small><b>${esc(a.title)}</b><p>${esc(a.summary||'')}</p></div><em>›</em></button>`).join('')}</div>`);
  $$('[data-read-article]',$('#modalCard')).forEach(b=>b.onclick=()=>{closeModal();readArticle(b.dataset.readArticle);});
}


function photoModal(i){
  const p=nyfwPhotos[Number(i)]; if(!p)return;
  openModal(`<button class="modal-close" data-close>×</button><span class="category">NYFW / RUNWAY 7</span><img class="photo-lightbox" src="${esc(p.image)}" alt="${esc(p.title)}"><h2>${esc(p.title)}</h2><p>${esc(p.subtitle)} · selected from the LSMG Google Drive archive.</p>`,'photo-modal');
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
    <div class="ai-mode"><i></i><span id="aiModeLabel">LIVE LLM · GPT · PULSE CONTEXT</span></div>
    <div class="ai-chat" id="aiChat">${msgs||'<div class="ai-welcome">Ask about stories, full magazine issues, creators, fashion, film, music, wrestling, or any culture prediction on screen.</div>'}</div>
    <div class="ai-quick"><button data-ai-quick="What are the biggest culture prediction signals right now?">BIGGEST SIGNALS</button><button data-ai-quick="What culture headlines should I know right now?">HEADLINES</button></div>
    <form id="aiForm" class="ai-form"><input id="aiInput" autocomplete="off" placeholder="Ask PULSE AI…" value="${esc(prefill)}"><button>↑</button></form>`, 'ai-sheet');
  setTimeout(()=>$('#aiInput')?.focus(),100);
}

let browserAI=null;
async function browserAIAnswer(prompt){
  if(!globalThis.LanguageModel) return null;
  try{
    const availability=await LanguageModel.availability({expectedInputs:[{type:'text',languages:['en']}],expectedOutputs:[{type:'text',languages:['en']}]});
    if(availability==='unavailable') return null;
    if(!browserAI){ browserAI=await LanguageModel.create({expectedInputs:[{type:'text',languages:['en']}],expectedOutputs:[{type:'text',languages:['en']}],initialPrompts:[{role:'system',content:'You are PULSE AI for LSMG x LEDGERA. Be concise and factual. Use the supplied app context. Treat prediction market prices as changing crowd signals, never certainty. Do not recommend political candidates or election outcomes.'}]}); }
    const context=JSON.stringify({articles:state.articles.slice(0,8).map(a=>({title:a.title,category:a.category,summary:a.summary})),issues:issues.slice(0,4).map(x=>({title:x.title,label:x.label,subtitle:x.subtitle})),markets:(state.live.markets.length?state.live.markets:fallbackMarkets).slice(0,8).map(m=>({title:m.title,source:m.source,yes:m.yes,no:m.no}))});
    return await browserAI.prompt('APP CONTEXT: '+context+'\nUSER: '+prompt);
  }catch{return null;}
}

function buildAIAnswer(prompt){
  const q=String(prompt||'').toLowerCase();
  if(/\b(politic|election|president|senate|congress|governor|mayor)\b/.test(q)){
    return {text:'PULSE keeps election and political outcome recommendations out of the prediction feed. I can still help you find factual culture coverage.'};
  }
  if(/biggest|top|live prediction|market|signal|odds/.test(q)){
    const top=[...(state.live.markets.length?state.live.markets:fallbackMarkets)].sort((a,b)=>Number(b.volume24h||0)-Number(a.volume24h||0)).slice(0,3);
    return {text:top.map((m,i)=>`${i+1}. ${m.title} — ${m.yes}% YES on ${m.source}.`).join(' ')+' These are changing public market signals, not guarantees.',action:{label:'OPEN PREDICTIONS',run:()=>{closeModal();setTab('predict');}}};
  }
  if(/newest|latest|magazine|issue|edition/.test(q)){
    const x=issues[0]; return {text:`The newest LEDGERA edition in PULSE is ${x.title} ${x.subtitle}`,action:{label:'READ '+x.title,run:()=>{closeModal();readIssue(0);}}};
  }
  if(/fashion|music|film|movie|sports|wrestling|culture|article|story|read/.test(q)){
    const keys=['fashion','music','film','movie','sports','wrestling','culture'].filter(k=>q.includes(k));
    const ranked=state.articles.map((a,i)=>({a,i,score:keys.reduce((n,k)=>n+((a.category+' '+a.title+' '+a.summary).toLowerCase().includes(k)?1:0),0)})).sort((a,b)=>b.score-a.score);
    const best=ranked.find(x=>x.score>0)||ranked[0];
    if(best)return {text:`Start with “${best.a.title}.” ${best.a.summary}`,action:{label:'READ ARTICLE',run:()=>{closeModal();readArticle(best.i);}}};
  }
  if(/podcast|episode|listen|audio/.test(q)){
    const e=(state.podcast.episodes||fallbackEpisodes)[0];
    return {text:`The latest Last Shot Podcast episode in PULSE is “${e.title}.” ${e.description||''}`,action:{label:'OPEN PODCAST',run:()=>{closeModal();setTab('watch');setTimeout(()=>document.getElementById('podcastSection')?.scrollIntoView({behavior:'smooth'}),180);}}};
  }
  if(/model|creator|talent|connect|collab|photographer|stylist/.test(q)){
    const words=q.split(/\W+/).filter(w=>w.length>3);
    const c=creators.map((x,i)=>({x,i,score:words.filter(w=>(x.name+' '+x.role+' '+x.skills.join(' ')+' '+x.need).toLowerCase().includes(w)).length})).sort((a,b)=>b.score-a.score)[0]||{x:creators[0],i:0};
    return {text:`A current PULSE network match is ${c.x.name}, ${c.x.role} in ${c.x.loc}. ${c.x.need}`,action:{label:'OPEN CONNECT',run:()=>{state.creatorIndex=c.i;closeModal();setTab('connect');}}};
  }
  const words=q.split(/\W+/).filter(w=>w.length>3);
  const a=state.articles.map((x,i)=>({x,i,score:words.filter(w=>(x.title+' '+x.summary+' '+x.category).toLowerCase().includes(w)).length})).sort((a,b)=>b.score-a.score)[0];
  const m=(state.live.markets.length?state.live.markets:fallbackMarkets).map(x=>({x,score:words.filter(w=>x.title.toLowerCase().includes(w)).length})).sort((a,b)=>b.score-a.score)[0];
  if(a?.score>0)return {text:`The closest LEDGERA story is “${a.x.title}.” ${a.x.summary}`,action:{label:'READ IT',run:()=>{closeModal();readArticle(a.i);}}};
  if(m?.score>0)return {text:`The closest culture prediction is “${m.x.title},” currently ${m.x.yes}% YES on ${m.x.source}.`,action:{label:'OPEN MARKET',run:()=>{closeModal();marketModal(m.x.id);}}};
  return {text:'I can search PULSE across LEDGERA articles, full magazine editions, culture prediction signals and creator profiles. Ask what you want to read, watch, track or find.'};
}
async function sendAI(prompt){
  const p=String(prompt||'').trim();if(!p)return;
  state.aiMessages.push({role:'user',text:p});
  const chat=$('#aiChat');const paintThinking=()=>{if(chat){chat.innerHTML=state.aiMessages.slice(-10).map(m=>`<div class="ai-msg ${m.role}"><span>${m.role==='assistant'?'PULSE AI':'YOU'}</span><p>${esc(m.text)}</p></div>`).join('')+'<div class="ai-thinking">PULSE LLM IS THINKING LIVE…</div>';chat.scrollTop=chat.scrollHeight}};paintThinking();
  let answer=null,mode='live-llm';
  try{
    const context={
      generatedAt:state.live.generatedAt,
      articles:state.articles.slice(0,12).map(a=>({title:a.title,category:a.category,summary:a.summary})),
      issues:issues.map(x=>({title:x.title,label:x.label,subtitle:x.subtitle})),
      markets:(state.live.markets.length?state.live.markets:fallbackMarkets).slice(0,10).map(m=>({title:m.title,source:m.source,yes:m.yes,no:m.no,volume24h:m.volume24h,endDate:m.endDate})),
      podcast:(state.podcast.episodes||[]).slice(0,6).map(e=>({title:e.title,date:e.date,description:e.description})),
      creators:creators.map(c=>({name:c.name,role:c.role,location:c.loc,skills:c.skills}))
    };
    const messages=state.aiMessages.slice(-10).map(m=>({role:m.role,content:m.text}));
    const r=await fetch('/api/ai',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({messages,context})});
    if(r.ok){const d=await r.json();if(d.text)answer={text:d.text};}
  }catch{}
  if(!answer){const generated=await browserAIAnswer(p);if(generated){answer={text:generated};mode='browser-ai'}else{answer=buildAIAnswer(p);mode='signal-fallback'}}
  state.aiMessages.push({role:'assistant',text:answer.text});state.aiMode=mode;
  if(chat){chat.innerHTML=state.aiMessages.slice(-10).map(m=>`<div class="ai-msg ${m.role}"><span>${m.role==='assistant'?'PULSE AI':'YOU'}</span><p>${esc(m.text)}</p></div>`).join('')+(answer.action?`<button class="ai-action" id="aiAction">${esc(answer.action.label)}</button>`:'');chat.scrollTop=chat.scrollHeight;if(answer.action)$('#aiAction').onclick=answer.action.run}
  if($('#aiModeLabel'))$('#aiModeLabel').textContent=mode==='live-llm'?'LIVE LLM · GPT · PULSE CONTEXT':mode==='browser-ai'?'BROWSER GENERATIVE AI':'SIGNAL FALLBACK · RETRY LIVE LLM';
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


function creatorAction(action, animate=false){
  const c=creators[state.creatorIndex%creators.length];
  if(action==='like' && !state.matches.includes(c.name)){state.matches.push(c.name);toast('Connection saved');}
  else if(action==='save') toast('Profile saved');
  const card=$('#creatorCard');
  const finish=()=>{state.creatorIndex=(state.creatorIndex+1)%creators.length;save();render();};
  if(animate&&card){
    const dir=action==='like'?1:-1;
    card.style.transition='transform .18s ease, opacity .18s ease';
    card.style.transform=`translateX(${dir*120}%) rotate(${dir*8}deg)`;
    card.style.opacity='0';
    setTimeout(finish,170);
  }else finish();
}
function bindCreatorCardSwipe(){
  const card=$('#creatorCard'); if(!card)return;
  let g=null;
  card.addEventListener('pointerdown',e=>{
    if(e.pointerType==='mouse'&&e.button!==0)return;
    if(e.target.closest('a,button,audio,video,input'))return;
    g={id:e.pointerId,x:e.clientX,y:e.clientY,t:performance.now(),dx:0};
    try{card.setPointerCapture(e.pointerId)}catch{}
    card.classList.add('dragging');
  });
  card.addEventListener('pointermove',e=>{
    if(!g||e.pointerId!==g.id)return;
    const dx=e.clientX-g.x,dy=e.clientY-g.y;
    if(Math.abs(dy)>Math.abs(dx)*1.4&&Math.abs(dy)>18)return;
    g.dx=dx;
    const limited=Math.max(-150,Math.min(150,dx));
    card.style.transform=`translateX(${limited}px) rotate(${limited*.025}deg)`;
    card.style.opacity=String(Math.max(.72,1-Math.abs(limited)/520));
  });
  const end=e=>{
    if(!g||e.pointerId!==g.id)return;
    const dx=e.clientX-g.x,dt=Math.max(1,performance.now()-g.t),velocity=Math.abs(dx)/dt;
    g=null; card.classList.remove('dragging');
    if(Math.abs(dx)>86||velocity>.55){
      creatorAction(dx>0?'like':'skip',true);
    }else{
      card.style.transition='transform .22s cubic-bezier(.2,.8,.2,1), opacity .22s';
      card.style.transform='';card.style.opacity='';
      setTimeout(()=>card.style.transition='',230);
    }
  };
  card.addEventListener('pointerup',end);
  card.addEventListener('pointercancel',()=>{if(!g)return;g=null;card.classList.remove('dragging');card.style.transform='';card.style.opacity='';});
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
  $$('[data-photo]').forEach(b=>b.onclick=()=>photoModal(b.dataset.photo));
  $('#refreshPodcast')?.addEventListener('click',()=>{loadPodcast();toast('Refreshing podcast RSS');});
  $$('[data-read-article]').forEach(b=>b.onclick=()=>{closeModal();readArticle(b.dataset.readArticle);});
  $$('[data-read-issue]').forEach(b=>b.onclick=()=>{closeModal();readIssue(b.dataset.readIssue);});
  $('#allIssues')?.addEventListener('click',issuesModal);
  $('#allStories')?.addEventListener('click',allStoriesModal);
  $$('[data-swipe-card]').forEach(b=>b.onclick=()=>creatorAction(b.dataset.swipeCard,false));
  bindCreatorCardSwipe();
  $$('#installApp, #installSettings').forEach(b=>b.onclick=installApp);
  $('#openAISettings')?.addEventListener('click',()=>aiModal());
  $('#profileStories')?.addEventListener('click',allStoriesModal);
  $('#profileIssues')?.addEventListener('click',issuesModal);
  $('#signOut')?.addEventListener('click',()=>{localStorage.removeItem('pulse.session.v1');state.session=null;pulseStarted=false;showAuth('signin');});
}

$('#searchBtn')?.addEventListener('click',()=>{
  openModal(`<button class="modal-close" data-close>×</button><span class="category">PULSE SEARCH</span><h2>SEARCH EVERYTHING.</h2><input class="search-box" id="searchInput" placeholder="Stories, issues, creators, markets…"><div id="searchResults" class="search-results"></div>`);
  $('#searchInput')?.addEventListener('input',e=>{
    const q=e.target.value.trim().toLowerCase(); const results=[];
    if(q){
      state.articles.filter(a=>(a.title+' '+a.summary+' '+a.category).toLowerCase().includes(q)).slice(0,5).forEach(a=>results.push({type:'article',label:a.title,sub:a.category,index:state.articles.indexOf(a)}));
      issues.filter(x=>(x.title+' '+x.subtitle+' '+x.label).toLowerCase().includes(q)).slice(0,4).forEach(x=>results.push({type:'issue',label:x.title,sub:x.label,index:issues.indexOf(x)}));
      (state.live.markets||[]).filter(x=>String(x.title).toLowerCase().includes(q)).slice(0,4).forEach(x=>results.push({type:'market',label:x.title,sub:`${x.source} · ${Number(x.yes)}% YES`,id:x.id}));
      creators.filter(x=>(x.name+' '+x.role+' '+x.skills.join(' ')).toLowerCase().includes(q)).slice(0,4).forEach(x=>results.push({type:'creator',label:x.name,sub:x.role,index:creators.indexOf(x)}));
      (state.podcast.episodes||[]).filter(x=>(x.title+' '+x.description).toLowerCase().includes(q)).slice(0,4).forEach(x=>results.push({type:'podcast',label:x.title,sub:'THE LAST SHOT PODCAST'}));
    }
    $('#searchResults').innerHTML=results.length?results.map((x,i)=>`<button class="search-result" data-search-result="${i}"><b>${esc(x.label)}</b><span>${esc(x.sub||'PULSE')}</span></button>`).join(''):'<div class="empty">Type to search PULSE.</div>';
    $$('[data-search-result]').forEach(b=>b.onclick=()=>{ const x=results[Number(b.dataset.searchResult)]; closeModal(); if(x.type==='article')readArticle(x.index); if(x.type==='issue')readIssue(x.index); if(x.type==='market')marketModal(x.id); if(x.type==='creator'){state.creatorIndex=x.index;setTab('connect');} if(x.type==='podcast'){setTab('watch');setTimeout(()=>document.getElementById('podcastSection')?.scrollIntoView({behavior:'smooth'}),180);} });
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

const swipeSurface=$('#view');
let tabSwipe=null;
let suppressClickUntil=0;
const noTabSwipe=t=>!!t.closest('.nyfw-rail,.issue-rail,.face-rail,.stock-video-rail,.podcast-card,audio,video,input,textarea,select,.reader-overlay,.onboarding-layer,.auth-layer,#creatorCard');
swipeSurface?.addEventListener('pointerdown',e=>{
  if((e.pointerType==='mouse'&&e.button!==0)||$('#modal')?.open||noTabSwipe(e.target))return;
  tabSwipe={id:e.pointerId,x:e.clientX,y:e.clientY,t:performance.now(),dx:0,dragging:false};
  try{swipeSurface.setPointerCapture(e.pointerId)}catch{}
});
swipeSurface?.addEventListener('pointermove',e=>{
  if(!tabSwipe||e.pointerId!==tabSwipe.id)return;
  const dx=e.clientX-tabSwipe.x,dy=e.clientY-tabSwipe.y;
  if(Math.abs(dx)>12&&Math.abs(dx)>Math.abs(dy)*1.15){
    tabSwipe.dragging=true;tabSwipe.dx=dx;
    const visual=Math.max(-28,Math.min(28,dx*.18));
    swipeSurface.style.transition='none';
    swipeSurface.style.transform=`translateX(${visual}px)`;
    swipeSurface.style.opacity=String(Math.max(.9,1-Math.abs(visual)/220));
  }
});
function endTabSwipe(e){
  if(!tabSwipe||e.pointerId!==tabSwipe.id)return;
  const g=tabSwipe;tabSwipe=null;
  const dx=e.clientX-g.x,dy=e.clientY-g.y,dt=Math.max(1,performance.now()-g.t),velocity=Math.abs(dx)/dt;
  swipeSurface.style.transition='transform .18s ease, opacity .18s ease';
  swipeSurface.style.transform='';swipeSurface.style.opacity='';
  setTimeout(()=>swipeSurface.style.transition='',190);
  if(!g.dragging)return;
  suppressClickUntil=Date.now()+260;
  if(Math.abs(dx)>68&&Math.abs(dx)>Math.abs(dy)*1.18||velocity>.65&&Math.abs(dx)>38){
    const tabs=['feed','watch','predict','connect','me'];
    const i=tabs.indexOf(state.tab);
    if(dx<0&&i<tabs.length-1)setTab(tabs[i+1]);
    else if(dx>0&&i>0)setTab(tabs[i-1]);
    else haptic();
  }
}
swipeSurface?.addEventListener('pointerup',endTabSwipe);
swipeSurface?.addEventListener('pointercancel',e=>{
  tabSwipe=null;swipeSurface.style.transform='';swipeSurface.style.opacity='';
});
document.addEventListener('click',e=>{
  if(Date.now()<suppressClickUntil){e.preventDefault();e.stopImmediatePropagation();}
},true);

window.addEventListener('beforeinstallprompt',e=>{e.preventDefault();state.deferredInstall=e;render();});
window.addEventListener('appinstalled',()=>{state.deferredInstall=null;toast('PULSE installed');render();});

bootPulse();
if('serviceWorker' in navigator) navigator.serviceWorker.register('/sw.js',{updateViaCache:'none'}).then(r=>r.update()).catch(()=>{});
