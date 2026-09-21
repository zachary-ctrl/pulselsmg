const SYSTEM="You are PULSE AI, the live culture intelligence assistant inside PULSE by LSMG × LEDGERA. Answer naturally and directly. Use the supplied current app context: LEDGERA stories, magazine issues, The Last Shot Podcast, creators, and live public culture prediction-market signals. Never invent a current fact that is not supported by the supplied context. Clearly distinguish reported facts from changing market prices. Never claim a market price guarantees an outcome. For political or electoral questions, remain neutral and factual and do not recommend a candidate, rank political choices, or predict an election winner. Do not tell users what cash wager to place or promise profit. Keep most answers under 220 words unless the user asks for detail.";
export default async function(req){
  const openaiBase=Netlify.env.get("OPENAI_BASE_URL");
  const openaiKey=Netlify.env.get("OPENAI_API_KEY");
  const gatewayBase=Netlify.env.get("NETLIFY_AI_GATEWAY_BASE_URL")||Netlify.env.get("NETLIFY_AI_GATEWAY_URL");
  const gatewayKey=Netlify.env.get("NETLIFY_AI_GATEWAY_KEY");
  if(req.method==="GET")return Response.json({
    ok:true,
    gatewayReady:Boolean(gatewayBase&&gatewayKey),
    openaiReady:Boolean(openaiBase&&openaiKey),
    model:"gpt-5-mini"
  },{headers:{"cache-control":"no-store"}});
  if(req.method!=="POST")return Response.json({error:"POST required"},{status:405});
  try{
    const body=await req.json();const messages=Array.isArray(body.messages)?body.messages.slice(-10):[];const context=body.context||{};
    if(!messages.length)return Response.json({error:"Message required"},{status:400});
    const base=openaiBase||gatewayBase,key=openaiKey||gatewayKey;
    if(!base||!key)return Response.json({error:"AI Gateway unavailable"},{status:503});
    const input=[{role:"system",content:SYSTEM+"\nCURRENT PULSE CONTEXT:\n"+JSON.stringify(context).slice(0,24000)},...messages.map(m=>({role:m.role==="assistant"?"assistant":"user",content:String(m.content||"").slice(0,4500)}))];
    const controller=new AbortController();const timer=setTimeout(()=>controller.abort(),9000);
    let r;
    try{
      r=await fetch(base.replace(/\/$/,"")+"/v1/chat/completions",{method:"POST",headers:{"content-type":"application/json","authorization":"Bearer "+key},body:JSON.stringify({model:"gpt-5-mini",store:false,messages:input,max_completion_tokens:360}),signal:controller.signal});
    }finally{clearTimeout(timer)}
    const data=await r.json().catch(()=>null);if(!r.ok)throw new Error(data?.error?.message||"Model request failed");
    const text=data?.choices?.[0]?.message?.content?.trim();if(!text)throw new Error("Empty model response");
    return Response.json({ok:true,text,model:data.model||"gpt-5-mini"},{headers:{"cache-control":"no-store"}});
  }catch(e){return Response.json({error:String(e)},{status:500})}
}
export const config={path:"/api/ai",rateLimit:{windowLimit:12,windowSize:60,aggregateBy:["ip","domain"]}};
