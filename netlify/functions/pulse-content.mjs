const allowed=u=>{try{const x=new URL(u);return x.protocol==="https:"&&(x.hostname==="ledgeramagazine.com"||x.hostname==="www.ledgeramagazine.com")}catch{return false}};
const decode=s=>String(s||"").replace(/<br\s*\/?>/gi,"\n").replace(/<[^>]+>/g," ").replace(/&nbsp;/g," ").replace(/&amp;/g,"&").replace(/&quot;/g,'"').replace(/&#39;/g,"'").replace(/&ldquo;|&rdquo;/g,'"').replace(/&lsquo;|&rsquo;/g,"'").replace(/&mdash;/g,"—").replace(/&ndash;/g,"–").replace(/\s+/g," ").trim();
export default async function(req){
  const u=new URL(req.url).searchParams.get("url")||"";
  if(!allowed(u))return Response.json({error:"Unsupported source"},{status:400});
  try{
    const r=await fetch(u,{headers:{"user-agent":"PULSE Reader/1.0"}});if(!r.ok)throw new Error("Source "+r.status);const h=await r.text();
    const pageMatch=h.match(/<script[^>]*class=["']reader-pages["'][^>]*>([\s\S]*?)<\/script>/i);
    if(pageMatch){let pages=[];try{pages=JSON.parse(pageMatch[1])}catch{}return Response.json({type:"issue",url:u,pages});}
    const title=decode(h.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i)?.[1]||h.match(/<title[^>]*>(.*?)<\/title>/i)?.[1]||"LEDGERA");
    const dek=decode(h.match(/<p[^>]*class=["'][^"']*dek[^"']*["'][^>]*>([\s\S]*?)<\/p>/i)?.[1]||"");
    const byline=decode(h.match(/<p[^>]*class=["'][^"']*byline[^"']*["'][^>]*>([\s\S]*?)<\/p>/i)?.[1]||"");
    const kicker=decode(h.match(/<(?:div|span)[^>]*class=["'][^"']*kicker[^"']*["'][^>]*>([\s\S]*?)<\/(?:div|span)>/i)?.[1]||"LEDGERA");
    const body=h.match(/<article[^>]*class=["'][^"']*body[^"']*["'][^>]*>([\s\S]*?)<\/article>/i)?.[1]||"";
    const paras=[...body.matchAll(/<p([^>]*)>([\s\S]*?)<\/p>/gi)].filter(m=>!/(source-note)/i.test(m[1]||"")).map(m=>decode(m[2])).filter(Boolean);
    const hero=h.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)/i)?.[1]||h.match(/<img[^>]+class=["'][^"']*(?:hero|article)[^"']*["'][^>]+src=["']([^"']+)/i)?.[1]||"";
    return Response.json({type:"article",url:u,title,dek,byline,kicker,hero,paragraphs:paras});
  }catch(e){return Response.json({error:String(e)},{status:502})}
}
export const config={path:"/api/content",method:"GET"};