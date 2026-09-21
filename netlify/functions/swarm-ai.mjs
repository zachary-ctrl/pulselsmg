const MODEL="gpt-5-mini";
const baseUrl=()=>Netlify.env.get("OPENAI_BASE_URL")||Netlify.env.get("NETLIFY_AI_GATEWAY_BASE_URL")||Netlify.env.get("NETLIFY_AI_GATEWAY_URL");
const apiKey=()=>Netlify.env.get("OPENAI_API_KEY")||Netlify.env.get("NETLIFY_AI_GATEWAY_KEY");
const stripJson=s=>String(s||"").trim().replace(/^\`\`\`(?:json)?/i,"").replace(/\`\`\`$/,"").trim();

const GOAL_SYSTEM=`You are the Goal Intelligence Engine for SWARM, an LSMG product.
Convert a user's natural-language goal into a structured Project Blueprint.
You may propose roles, resources, milestones and constraints, but NEVER produce match percentages, trust scores, candidate rankings, team scores, or invented people.
Return ONLY valid JSON, no markdown and no commentary.
Schema:
{
  "title": string,
  "objective": string,
  "category": string,
  "location": string,
  "remoteAllowed": boolean,
  "budgetMin": number|null,
  "budgetMax": number|null,
  "startDate": "YYYY-MM-DD"|null,
  "deadline": "YYYY-MM-DD"|null,
  "requiredSkills": string[],
  "requiredRoles": [{"title":string,"skills":string[],"budgetCap":number|null,"estimatedHours":number,"requiredLanguages":string[]}],
  "optionalRoles": [{"title":string,"skills":string[],"budgetCap":number|null,"estimatedHours":number,"requiredLanguages":string[]}],
  "resourcesNeeded": string[],
  "milestones": string[],
  "constraints": string[],
  "preferredExperience": string[],
  "preferredWorkingStyle": string[],
  "teamSizeMin": number,
  "teamSizeMax": number
}
Use practical assumptions. If budget or dates are absent, return null rather than inventing exact numbers. Keep roles proportional to the goal.`;

const COORDINATOR_SYSTEM=`You are the SWARM AI Coordinator for an LSMG project workspace.
Analyze only the supplied blueprint and Swarm Room state.
You can identify schedule risk, budget risk, unassigned work, missing decisions, stalled milestones, and coordination options.
Do not send messages, invite or remove people, spend money, change assignments, or make irreversible decisions.
Do not invent activity that is not in the supplied data.
Be concise: 3 to 6 short sentences, followed by at most 3 suggested next actions.`;

async function callModel(messages,max=650){
  const base=baseUrl(),key=apiKey();
  if(!base||!key)throw new Error("AI Gateway unavailable");
  const controller=new AbortController();const timer=setTimeout(()=>controller.abort(),8500);
  try{
    const r=await fetch(base.replace(/\/$/,"")+"/v1/chat/completions",{
      method:"POST",
      headers:{"content-type":"application/json","authorization":"Bearer "+key},
      body:JSON.stringify({model:MODEL,store:false,messages,max_completion_tokens:max}),
      signal:controller.signal
    });
    const data=await r.json().catch(()=>null);
    if(!r.ok)throw new Error(data?.error?.message||"Model request failed");
    const text=data?.choices?.[0]?.message?.content?.trim();
    if(!text)throw new Error("Empty model response");
    return {text,model:data.model||MODEL};
  }finally{clearTimeout(timer)}
}

export default async function(req){
  if(req.method==="GET"){
    return Response.json({ok:true,service:"SWARM AI",model:MODEL,gatewayReady:Boolean(baseUrl()&&apiKey())},{headers:{"cache-control":"no-store"}});
  }
  if(req.method!=="POST")return Response.json({error:"POST required"},{status:405});
  let body;try{body=await req.json()}catch{return Response.json({error:"Invalid JSON"},{status:400})}
  try{
    const action=String(body?.action||"");
    if(action==="parse_goal"){
      const rawGoal=String(body?.rawGoal||"").trim();
      if(rawGoal.length<8)return Response.json({error:"Goal too short"},{status:400});
      const {text,model}=await callModel([{role:"system",content:GOAL_SYSTEM},{role:"user",content:rawGoal}],850);
      let blueprint;try{blueprint=JSON.parse(stripJson(text))}catch{return Response.json({error:"Model returned invalid blueprint JSON"},{status:502})}
      return Response.json({ok:true,blueprint,model},{headers:{"cache-control":"no-store"}});
    }
    if(action==="coordinate"){
      const payload={project:body?.project||null,swarm:body?.swarm||null};
      const {text,model}=await callModel([{role:"system",content:COORDINATOR_SYSTEM},{role:"user",content:JSON.stringify(payload).slice(0,22000)}],420);
      return Response.json({ok:true,text,model},{headers:{"cache-control":"no-store"}});
    }
    return Response.json({error:"Unsupported AI action"},{status:400});
  }catch(e){
    const msg=String(e?.name==="AbortError"?"AI request timed out":e?.message||e);
    return Response.json({error:msg},{status:503,headers:{"cache-control":"no-store"}});
  }
}
export const config={path:"/api/ai",rateLimit:{windowLimit:20,windowSize:60,aggregateBy:["ip","domain"]}};