const PREFIX="swarm.";
const parse=(k,fallback)=>{try{const v=localStorage.getItem(PREFIX+k);return v==null?fallback:JSON.parse(v)}catch{return fallback}};
const put=(k,v)=>{localStorage.setItem(PREFIX+k,JSON.stringify(v));return v};
const uid=(p="id")=>p+"_"+(crypto?.randomUUID?.()||Math.random().toString(36).slice(2));

export const Store={
  getSession(){return parse("session.v1",null)},
  setSession(v){return put("session.v1",v)},
  clearSession(){localStorage.removeItem(PREFIX+"session.v1")},
  getAccounts(){return parse("accounts.v1",{})},
  setAccounts(v){return put("accounts.v1",v)},
  getProfile(){return parse("profile.v1",null)},
  setProfile(v){return put("profile.v1",v)},
  getProjects(){return parse("projects.v1",[])},
  setProjects(v){return put("projects.v1",v)},
  upsertProject(project){const list=this.getProjects();const i=list.findIndex(x=>x.id===project.id);if(i>=0)list[i]=project;else list.unshift(project);this.setProjects(list);return project},
  getSwarms(){return parse("swarms.v1",[])},
  setSwarms(v){return put("swarms.v1",v)},
  upsertSwarm(swarm){const list=this.getSwarms();const i=list.findIndex(x=>x.id===swarm.id);if(i>=0)list[i]=swarm;else list.unshift(swarm);this.setSwarms(list);return swarm},
  getInvitations(){return parse("invitations.v1",[])},
  setInvitations(v){return put("invitations.v1",v)},
  getNotifications(){return parse("notifications.v1",[])},
  pushNotification(n){const list=this.getNotifications();list.unshift({id:uid("n"),read:false,createdAt:new Date().toISOString(),...n});put("notifications.v1",list.slice(0,100))},
  getActivity(){return parse("activity.v1",[])},
  activity(type,data={}){const list=this.getActivity();list.unshift({id:uid("evt"),type,createdAt:new Date().toISOString(),...data});put("activity.v1",list.slice(0,300));this.analytics(type,data)},
  getAnalytics(){return parse("analytics.v1",[])},
  analytics(name,props={}){const list=this.getAnalytics();list.push({id:uid("a"),name,at:new Date().toISOString(),props});put("analytics.v1",list.slice(-1000))},
  getOutcomes(){return parse("outcomes.v1",[])},
  addOutcome(o){const list=this.getOutcomes();list.unshift({id:uid("out"),createdAt:new Date().toISOString(),...o});put("outcomes.v1",list);return list[0]},
  resetDemo(){["projects.v1","swarms.v1","invitations.v1","notifications.v1","activity.v1","analytics.v1","outcomes.v1"].forEach(k=>localStorage.removeItem(PREFIX+k))}
};
export const makeId=uid;

export function migratePulseSession(){
  try{
    const currentAccounts=Store.getAccounts();
    if(!Object.keys(currentAccounts).length){
      const legacyAccounts=JSON.parse(localStorage.getItem("pulse.accounts.v1")||"{}");
      if(legacyAccounts&&typeof legacyAccounts==="object"&&Object.keys(legacyAccounts).length)Store.setAccounts(legacyAccounts);
    }
  }catch{}
  if(Store.getSession())return;
  try{
    const old=JSON.parse(localStorage.getItem("pulse.session.v1")||"null");
    if(old?.email)Store.setSession({name:old.name||"SWARM User",email:old.email,migratedFrom:"PULSE",createdAt:new Date().toISOString()});
  }catch{}
}
