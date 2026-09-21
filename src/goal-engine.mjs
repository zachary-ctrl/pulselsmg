const ROLE_TEMPLATES={
  app:{
    category:"Software / Product",
    roles:[
      {title:"Product Manager",skills:["Product Management","Roadmapping","User Research"],required:true},
      {title:"Product Engineer",skills:["JavaScript","TypeScript","Product Architecture"],required:true},
      {title:"UI Designer",skills:["UI Design","Figma","Design Systems"],required:true},
      {title:"Growth Marketer",skills:["Growth Marketing","Analytics","Launch Strategy"],required:false}
    ],
    resources:["product requirements","design system","development environment","analytics","app distribution"],
    milestones:["Scope and product definition","UX and interface system","Core build","QA and beta","Launch and measurement"]
  },
  fashion:{
    category:"Fashion / Brand",
    roles:[
      {title:"Fashion Designer",skills:["Fashion Design","Tech Packs","Product Development"],required:true},
      {title:"Brand Designer",skills:["Brand Design","Creative Direction","Typography"],required:true},
      {title:"E-commerce Developer",skills:["Shopify","E-commerce Development","Conversion Optimization"],required:true},
      {title:"Photographer",skills:["Photography","Lighting","Retouching"],required:true},
      {title:"Growth Marketer",skills:["Growth Marketing","Paid Social","Launch Strategy"],required:true},
      {title:"Copywriter",skills:["Copywriting","Brand Strategy","Content Strategy"],required:false}
    ],
    resources:["manufacturer or supplier","product samples","storefront","payment processing","studio/location","launch content"],
    milestones:["Brand and product direction","Samples and sourcing","Storefront build","Campaign production","Launch preparation","Launch"]
  },
  film:{
    category:"Film / Video",
    roles:[
      {title:"Producer",skills:["Producing","Budgeting","Scheduling"],required:true},
      {title:"Director",skills:["Directing","Storyboarding","Cinematography"],required:true},
      {title:"DP",skills:["Cinematography","Lighting"],required:true},
      {title:"Editor",skills:["Editing","Color Grading"],required:true},
      {title:"Photographer",skills:["Photography","Lighting"],required:false}
    ],
    resources:["camera package","locations","crew","talent","production insurance","post-production"],
    milestones:["Treatment and scope","Pre-production","Production","Edit","Color/sound","Delivery"]
  },
  event:{
    category:"Events",
    roles:[
      {title:"Event Producer",skills:["Event Production","Run of Show","Vendor Management"],required:true},
      {title:"Producer",skills:["Producing","Budgeting","Scheduling"],required:true},
      {title:"Growth Marketer",skills:["Growth Marketing","Launch Strategy"],required:false},
      {title:"Partnerships Lead",skills:["Partnerships","Sales","Negotiation"],required:false}
    ],
    resources:["venue","vendors","ticketing/registration","run of show","staffing","AV"],
    milestones:["Concept and budget","Venue/vendors","Programming and partners","Promotion","Production plan","Event execution"]
  },
  podcast:{
    category:"Podcast / Audio",
    roles:[
      {title:"Podcast Producer",skills:["Podcast Production","Audio Production","Recording"],required:true},
      {title:"Writer",skills:["Copywriting","Research","Scriptwriting"],required:true},
      {title:"Growth Marketer",skills:["Growth Marketing","Content Strategy"],required:false}
    ],
    resources:["recording setup","hosting/RSS","show identity","guest pipeline","editing workflow"],
    milestones:["Format and identity","Pilot production","Distribution setup","Launch episodes","Growth loop"]
  },
  startup:{
    category:"Startup",
    roles:[
      {title:"Product Manager",skills:["Product Management","Roadmapping","User Research"],required:true},
      {title:"Product Engineer",skills:["JavaScript","TypeScript","Product Architecture"],required:true},
      {title:"UI Designer",skills:["UI Design","Figma","Design Systems"],required:true},
      {title:"Growth Marketer",skills:["Growth Marketing","Analytics","Launch Strategy"],required:true},
      {title:"Finance Lead",skills:["Financial Modeling","Budgeting","Forecasting"],required:false},
      {title:"Sales Lead",skills:["Sales","Outbound","Partnerships"],required:false}
    ],
    resources:["product scope","customer discovery","MVP","analytics","go-to-market plan"],
    milestones:["Problem validation","MVP scope","Design/build","Pilot users","Launch","Learning loop"]
  },
  campaign:{
    category:"Marketing / Campaign",
    roles:[
      {title:"Creative Director",skills:["Creative Direction","Brand Design"],required:true},
      {title:"Copywriter",skills:["Copywriting","Brand Strategy","Content Strategy"],required:true},
      {title:"Photographer",skills:["Photography","Lighting"],required:false},
      {title:"Growth Marketer",skills:["Growth Marketing","Paid Social","Analytics"],required:true}
    ],
    resources:["campaign brief","creative assets","media budget","landing page","analytics"],
    milestones:["Strategy","Creative concept","Production","Launch","Optimization","Reporting"]
  },
  band:{
    category:"Music",
    roles:[
      {title:"Music Producer",skills:["Music Production","Artist Development","Recording"],required:true},
      {title:"Audio Producer",skills:["Audio Production","Mixing","Recording"],required:true},
      {title:"Creative Director",skills:["Creative Direction","Brand Design"],required:false},
      {title:"Growth Marketer",skills:["Growth Marketing","Content Strategy"],required:false}
    ],
    resources:["rehearsal/studio","recording workflow","artist identity","distribution","live plan"],
    milestones:["Sound and positioning","Demo/rehearsal","Recording","Identity/content","Release/live plan"]
  },
  food:{
    category:"Food / Hospitality",
    roles:[
      {title:"Food Consultant",skills:["Food Operations","Menu Costing","Permitting"],required:true},
      {title:"Finance Lead",skills:["Financial Modeling","Budgeting","Forecasting"],required:true},
      {title:"Brand Designer",skills:["Brand Design","Creative Direction"],required:true},
      {title:"Growth Marketer",skills:["Growth Marketing","Launch Strategy"],required:false}
    ],
    resources:["permits","vehicle/equipment","suppliers","menu","payments/POS","launch location"],
    milestones:["Concept and economics","Permits and sourcing","Brand/menu","Operations setup","Soft launch","Launch"]
  }
};

const cityNames=["Dallas","Fort Worth","Austin","Houston","Atlanta","New York","Los Angeles","Chicago","Miami","Seattle","Denver","San Francisco"];
const uid=()=>crypto?.randomUUID?.()||"p_"+Math.random().toString(36).slice(2);

function pickTemplate(goal){
  const q=goal.toLowerCase();
  if(/streetwear|clothing|fashion|apparel|collection/.test(q))return ROLE_TEMPLATES.fashion;
  if(/music video|short film|film|video shoot|commercial shoot/.test(q))return ROLE_TEMPLATES.film;
  if(/event|conference|festival|party|activation|300-person/.test(q))return ROLE_TEMPLATES.event;
  if(/podcast|show|audio series/.test(q))return ROLE_TEMPLATES.podcast;
  if(/food truck|restaurant|food concept|catering/.test(q))return ROLE_TEMPLATES.food;
  if(/band|album|ep |single|music project/.test(q))return ROLE_TEMPLATES.band;
  if(/campaign|marketing campaign|launch campaign/.test(q))return ROLE_TEMPLATES.campaign;
  if(/startup|company|business/.test(q)&&!/clothing|fashion/.test(q))return ROLE_TEMPLATES.startup;
  if(/app|software|website|platform|saas|ios|android/.test(q))return ROLE_TEMPLATES.app;
  return ROLE_TEMPLATES.startup;
}
function parseMoney(goal){
  const m=goal.match(/\$\s?([\d,.]+)\s*(k)?/i);if(!m)return null;
  let n=Number(m[1].replace(/,/g,""));if(m[2])n*=1000;return Number.isFinite(n)?n:null;
}
function parseDeadline(goal){
  const now=new Date();
  let days=goal.match(/(\d+)\s*(day|days|week|weeks|month|months)/i);
  if(days){
    const n=Number(days[1]);const unit=days[2].toLowerCase();
    const mult=unit.startsWith("week")?7:unit.startsWith("month")?30:1;
    return new Date(now.getTime()+n*mult*86400000).toISOString().slice(0,10);
  }
  if(/next month/i.test(goal)){return new Date(now.getFullYear(),now.getMonth()+2,0).toISOString().slice(0,10)}
  return new Date(now.getTime()+45*86400000).toISOString().slice(0,10);
}
function inferTitle(goal,category){
  const clean=goal.replace(/^i\s+(want|need|am trying)\s+to\s+/i,"").replace(/[.!?]+$/,"").trim();
  return clean.length<72?clean.replace(/^./,c=>c.toUpperCase()):category+" Project";
}
function roleBudget(total,roles){
  if(!total)return null;
  const required=roles.filter(r=>r.required).length||roles.length;
  return Math.round(total/required);
}
export function parseGoalFallback(rawGoal){
  const tpl=pickTemplate(rawGoal);
  const budget=parseMoney(rawGoal);
  const location=cityNames.find(c=>new RegExp("\\b"+c.replace(" ","\\s+")+"\\b","i").test(rawGoal))||"Remote";
  const remoteAllowed=/remote|anywhere|online/i.test(rawGoal)||location==="Remote"||["Software / Product","Fashion / Brand","Startup","Marketing / Campaign","Podcast / Audio","Music"].includes(tpl.category);
  const deadline=parseDeadline(rawGoal);
  const startDate=new Date().toISOString().slice(0,10);
  const roles=tpl.roles.map((r,i)=>({
    id:"role-"+(i+1)+"-"+uid().slice(0,6),title:r.title,required:r.required,skills:r.skills.map(s=>({name:s,required:true,weight:1})),
    budgetCap:roleBudget(budget,tpl.roles),estimatedHours:r.title.match(/Developer|Engineer/)?45:r.title.match(/Producer|Manager/)?28:22,
    requiredLanguages:["English"],certifications:[],notes:""
  }));
  return {
    id:uid(),creatorId:null,rawGoal,title:inferTitle(rawGoal,tpl.category),objective:inferTitle(rawGoal,tpl.category),category:tpl.category,
    location,remoteAllowed,budgetMin:budget?Math.round(budget*.75):null,budgetMax:budget,startDate,deadline,
    requiredSkills:[...new Set(roles.filter(r=>r.required).flatMap(r=>r.skills.map(s=>s.name)))],
    requiredRoles:roles.filter(r=>r.required),optionalRoles:roles.filter(r=>!r.required),resourcesNeeded:[...tpl.resources],
    milestones:tpl.milestones.map((title,i)=>({id:"ms-"+uid().slice(0,8),title,status:"todo",order:i+1,dueDate:null})),
    constraints:[],preferredExperience:[],preferredWorkingStyle:["collaborative","structured"],teamSizeMin:Math.max(2,roles.filter(r=>r.required).length-1),
    teamSizeMax:roles.length,status:"blueprint",createdAt:new Date().toISOString(),updatedAt:new Date().toISOString(),source:"fallback"
  };
}
export function normalizeBlueprint(input,rawGoal){
  const fallback=parseGoalFallback(rawGoal);
  const b={...fallback,...input};
  b.rawGoal=rawGoal;b.id=b.id||fallback.id;b.createdAt=b.createdAt||fallback.createdAt;b.updatedAt=new Date().toISOString();
  const normalizeRole=(r,i,required)=>({
    id:r.id||"role-"+(i+1)+"-"+uid().slice(0,6),title:String(r.title||"Specialist"),required,
    skills:(r.skills||[]).map(s=>typeof s==="string"?{name:s,required:true,weight:1}:{name:String(s.name||""),required:s.required!==false,weight:Number(s.weight||1)}).filter(s=>s.name),
    budgetCap:r.budgetCap==null?roleBudget(b.budgetMax,[...(b.requiredRoles||[]),...(b.optionalRoles||[])]):Number(r.budgetCap),
    estimatedHours:Number(r.estimatedHours||24),requiredLanguages:r.requiredLanguages||["English"],certifications:r.certifications||[],notes:r.notes||""
  });
  b.requiredRoles=(b.requiredRoles||fallback.requiredRoles).map((r,i)=>normalizeRole(r,i,true));
  b.optionalRoles=(b.optionalRoles||fallback.optionalRoles).map((r,i)=>normalizeRole(r,i,false));
  b.milestones=(b.milestones||fallback.milestones).map((m,i)=>typeof m==="string"?{id:"ms-"+uid().slice(0,8),title:m,status:"todo",order:i+1,dueDate:null}:{id:m.id||"ms-"+uid().slice(0,8),title:m.title||"Milestone",status:m.status||"todo",order:m.order||i+1,dueDate:m.dueDate||null});
  b.resourcesNeeded=(b.resourcesNeeded||[]).map(String);b.constraints=(b.constraints||[]).map(String);return b;
}
