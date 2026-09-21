const SYSTEM=`You are PULSE AI, the live culture intelligence assistant inside PULSE by LSMG × LEDGERA. Answer naturally and directly. You can reason about current app context: LEDGERA stories, magazine issues, The Last Shot Podcast, creators, and live public culture prediction-market signals. Clearly distinguish reported facts from changing market prices. Never claim a market price guarantees an outcome. For political or electoral questions, remain neutral and factual and do not recommend a candidate, rank political choices, or predict an election winner. Do not tell users what cash wager to place or promise profit. Keep most answers under 220 words unless the user asks for detail.`;
export default async function(req){
  if(req.method!=="POST")return Response.json({error:"POST required"},{status:405});
  try{
    const body=await req.json();const messages=Array.isArray(body.messages)?body.messages.slice(-12):[];
    const context=body.context||{};
    const base=process.env.OPENAI_BASE_URL, key=process.env.OPENAI_API_KEY;
    if(!base||!key)return Response.json({error:"AI Gateway unavailable"},{status:503});
    const input=[{role:"system",content:SYSTEM+"\nLIVE APP CONTEXT:\n"+JSON.stringify(context).slice(0,28000)},...messages.map(m=>({role:m.role==="assistant"?"assistant":"user",content:String(m.content||"").slice(0,5000)}))];
    const r=await fetch(base.replace(/\/$/,"")+"/v1/chat/completions",{method:"POST",headers:{"content-type":"application/json","authorization":"Bearer "+key},body:JSON.stringify({model:"gpt-5",messages:input,max_completion_tokens:700})});
    const data=await r.json();if(!r.ok)throw new Error(data?.error?.message||"Model request failed");
    const text=data?.choices?.[0]?.message?.content?.trim();if(!text)throw new Error("Empty model response");
    return Response.json({ok:true,text,model:data.model||"gpt-5"});
  }catch(e){return Response.json({error:String(e)},{status:500})}
}
export const config={path:"/api/ai",method:"POST"};