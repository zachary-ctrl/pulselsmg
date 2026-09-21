const SITE="https://ledgeramagazine.com";
const RAW="https://raw.githubusercontent.com/zachary-ctrl/theledgeramagazine/main/";
const allowed=u=>{try{const x=new URL(u);return x.protocol==="https:"&&(x.hostname==="ledgeramagazine.com"||x.hostname==="www.ledgeramagazine.com")}catch{return false}};
const decode=s=>String(s||"").replace(/<br\s*\/?>/gi,"\n").replace(/<[^>]+>/g," ").replace(/&nbsp;/g," ").replace(/&amp;/g,"&").replace(/&quot;/g,'"').replace(/&#39;/g,"'").replace(/&ldquo;|&rdquo;/g,'"').replace(/&lsquo;|&rsquo;/g,"'").replace(/&mdash;/g,"—").replace(/&ndash;/g,"–").replace(/\s+/g," ").trim();
const absolute=h=>String(h||"")
  .replace(/(src|href)=(["'])\/(?!\/)/gi,'$1=$2'+SITE+'/')
  .replace(/(src|href)=(["'])\.\//gi,'$1=$2'+SITE+'/');
const clean=h=>absolute(String(h||"")
  .replace(/<script[\s\S]*?<\/script>/gi,"")
  .replace(/<style[\s\S]*?<\/style>/gi,"")
  .replace(/<iframe[\s\S]*?<\/iframe>/gi,"")
  .replace(/<form[\s\S]*?<\/form>/gi,"")
  .replace(/\son\w+=(["'])[\s\S]*?\1/gi,""));
export default async function(req){
  const u=new URL(req.url).searchParams.get("url")||"";
  if(!allowed(u))return Response.json({error:"Unsupported source"},{status:400});
  try{
    const parsed=new URL(u);
    let path=parsed.pathname.replace(/^\/+/,"");
    if(path.endsWith("/"))path+="index.html";
    const r=await fetch(RAW+path+"?ts="+Date.now(),{headers:{"user-agent":"PULSE Reader/2.0"}});
    if(!r.ok)throw new Error("Source "+r.status);
    const h=await r.text();
    if(parsed.pathname.includes("/magazine/")){
      const pageMatch=h.match(/<script[^>]*class=["']reader-pages["'][^>]*>([\s\S]*?)<\/script>/i);
      let pages=[];try{if(pageMatch)pages=JSON.parse(pageMatch[1])}catch{}
      const cover=(h.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)/i)?.[1]||h.match(/<img[^>]+(?:class=["'][^"']*(?:cover|issue)[^"']*["'][^>]*)?src=["']([^"']+)/i)?.[1]||"").replace(/^\//,SITE+"/");
      const m=parsed.pathname.match(/issue-(\d+)/);
      const issue=m?m[1]:"";
      const member=!pages.length&&["01","02","03"].includes(issue);
      if(!pages.length&&cover)pages=[{src:cover,short:"Cover",title:decode(h.match(/<h(?:1|2)[^>]*>([\s\S]*?)<\/h(?:1|2)>/i)?.[1]||"LEDGERA"),chapter:member?"Member Preview":"Archive Preview",alt:"LEDGERA cover",unlockUrl:member?SITE+"/subscribe/?issue="+issue:"",previewOnly:!member,originalUrl:u}];
      return Response.json({type:"issue",url:u,pages,access:pages.length>1?"full":member?"member":"preview"},{headers:{"cache-control":"no-store"}});
    }
    const title=decode(h.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i)?.[1]||h.match(/<title[^>]*>(.*?)<\/title>/i)?.[1]||"LEDGERA");
    const dek=decode(h.match(/<p[^>]*class=["'][^"']*dek[^"']*["'][^>]*>([\s\S]*?)<\/p>/i)?.[1]||"");
    const byline=decode(h.match(/<p[^>]*class=["'][^"']*byline[^"']*["'][^>]*>([\s\S]*?)<\/p>/i)?.[1]||"");
    const kicker=decode(h.match(/<(?:div|span)[^>]*class=["'][^"']*kicker[^"']*["'][^>]*>([\s\S]*?)<\/(?:div|span)>/i)?.[1]||"LEDGERA");
    const body=h.match(/<article[^>]*class=["'][^"']*body[^"']*["'][^>]*>([\s\S]*?)<\/article>/i)?.[1]||"";
    const bodyHtml=clean(body);
    const paras=[...body.matchAll(/<p([^>]*)>([\s\S]*?)<\/p>/gi)].filter(m=>!/(source-note)/i.test(m[1]||"")).map(m=>decode(m[2])).filter(Boolean);
    let hero=h.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)/i)?.[1]||h.match(/<figure[^>]*class=["'][^"']*article-image[^"']*["'][\s\S]*?<img[^>]+src=["']([^"']+)/i)?.[1]||"";
    if(hero.startsWith("/"))hero=SITE+hero;
    return Response.json({type:"article",url:u,title,dek,byline,kicker,hero,bodyHtml,paragraphs:paras},{headers:{"cache-control":"no-store"}});
  }catch(e){return Response.json({error:String(e)},{status:502})}
}
export const config={path:"/api/content",method:"GET",rateLimit:{windowLimit:60,windowSize:60,aggregateBy:["ip","domain"]}};