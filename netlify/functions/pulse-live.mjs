export default async function(req){
  const headers={"content-type":"application/json","cache-control":"public, max-age=5, s-maxage=15, stale-while-revalidate=30"};
  const culture=["movie","film","box office","oscar","grammy","emmy","album","song","music","artist","singer","rapper","concert","tour","billboard","spotify","netflix","hbo","disney","marvel","celebrity","actor","actress","television","streaming","fashion","runway","designer","wrestling","wwe","aew","tna","youtube","tiktok","creator","influencer","award"];
  const blocked=["election","president","senate","congress","parliament","minister","governor","mayor","democrat","republican"];
  const ok=t=>{t=String(t||"").toLowerCase();return culture.some(x=>t.includes(x))&&!blocked.some(x=>t.includes(x))};
  const json=async u=>{const r=await fetch(u,{headers:{"user-agent":"PULSE/1.0"}});if(!r.ok)throw new Error(String(r.status));return r.json()};
  const markets=[]; let articles=[]; let podcast=[];
  const jobs=await Promise.allSettled([
    json("https://raw.githubusercontent.com/zachary-ctrl/theledgeramagazine/main/feed.json?ts="+Date.now()),
    json("https://gamma-api.polymarket.com/markets?active=true&closed=false&limit=250&order=volume24hr&ascending=false"),
    json("https://api.elections.kalshi.com/trade-api/v2/markets?limit=300&status=open"),
    json("https://itunes.apple.com/lookup?id=1494831568&entity=podcastEpisode&limit=12&country=US")
  ]);
  if(jobs[0].status==="fulfilled") articles=(jobs[0].value.items||[]).map(x=>({title:x.title||"LEDGERA",summary:x.summary||"",category:x._ledgera?.category||(x.tags||[]).join(" / ")||"LEDGERA",url:x.url||x.id,image:x.image||""}));
  if(jobs[1].status==="fulfilled") for(const m of jobs[1].value||[]){if(!ok((m.question||"")+" "+(m.events?.[0]?.title||"")))continue;let o=[],p=[];try{o=JSON.parse(m.outcomes||"[]");p=JSON.parse(m.outcomePrices||"[]")}catch{}const yi=o.findIndex(x=>String(x).toLowerCase()==="yes");if(yi<0)continue;const yes=Math.max(0,Math.min(100,Math.round(Number(p[yi]||0)*100)));markets.push({id:"poly-"+m.id,source:"POLYMARKET",title:m.question,yes,no:100-yes,volume24h:Number(m.volume24hr||0),change24h:Number(m.oneDayPriceChange||0)*100,endDate:m.endDate||m.endDateIso||"",image:m.image||m.icon||""});if(markets.length>=14)break}
  if(jobs[2].status==="fulfilled") for(const m of jobs[2].value.markets||[]){if(!ok((m.title||"")+" "+(m.yes_sub_title||"")))continue;const p=Number(m.last_price_dollars||m.yes_ask_dollars||m.yes_bid_dollars||0);if(!(p>0&&p<1))continue;const yes=Math.round(p*100);markets.push({id:"kalshi-"+m.ticker,source:"KALSHI",title:m.title,yes,no:100-yes,volume24h:Number(m.volume_24h_fp||0),change24h:(p-Number(m.previous_price_dollars||p))*100,endDate:m.close_time||m.expiration_time||"",image:""});if(markets.length>=22)break}
  if(jobs[3].status==="fulfilled") podcast=(jobs[3].value.results||[]).filter(x=>x.wrapperType==="podcastEpisode").slice(0,10).map(x=>({title:x.trackName||"The Last Shot Podcast",date:x.releaseDate||"",duration:x.trackTimeMillis?Math.round(x.trackTimeMillis/60000)+" min":"",description:x.description||x.shortDescription||"",link:x.trackViewUrl||"",audio:x.episodeUrl||"",image:x.artworkUrl600||x.artworkUrl100||""}));
  return new Response(JSON.stringify({ok:true,generatedAt:new Date().toISOString(),articles,markets,podcast}),{headers});
}
export const config={path:"/api/live",method:"GET"};