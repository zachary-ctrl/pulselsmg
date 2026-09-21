import test from "node:test";
import assert from "node:assert/strict";
import {scoreRoleCandidate,rankCandidates,optimizeTeams,replacementForRole,scoreTeam,DEFAULT_MATCH_WEIGHTS} from "../src/match-engine.mjs";
import {parseGoalFallback} from "../src/goal-engine.mjs";

const baseProject={id:"p",title:"Test",objective:"Build",category:"Technology",location:"Dallas",remoteAllowed:true,budgetMax:5000,startDate:"2026-10-01",deadline:"2026-11-15",preferredWorkingStyle:["structured"],teamSizeMin:1,teamSizeMax:3,requiredRoles:[]};
const role=(id,title,skills,budgetCap=2500)=>({id,title,required:true,skills:skills.map(name=>({name,required:true,weight:1})),budgetCap,estimatedHours:20,requiredLanguages:["English"],certifications:[]});
const profile=(id,skills,extra={})=>({id,name:id,bio:"",skills:skills.map(([n,l])=>[n,l,true]),experience:[{title:"Specialist",years:5}],verifiedExperience:[],industries:["Technology"],interests:["technology"],goals:["build"],desiredRoles:["Developer","Designer"],location:{city:"Dallas",state:"TX",country:"US"},remoteAllowed:true,travelRadius:30,availability:{start:"2026-09-01",end:"2026-12-31",hoursPerWeek:20},timezone:"America/Chicago",hourlyRate:50,projectRate:1000,minimumBudget:100,languages:["English"],workingStyle:["structured"],communicationPreferences:["Email"],reliabilityScore:.9,completionRate:.9,responseRate:.9,projectsCompleted:10,previousCollaborators:[],blockedUsers:[],...extra});

test("hard constraints reject blocked users",()=>{
  const r=role("r","Developer",["JavaScript"]);
  const p=profile("a",[["JavaScript",1]],{blockedUsers:["b"]});
  assert.equal(scoreRoleCandidate(p,r,baseProject,DEFAULT_MATCH_WEIGHTS,["b"]).eligible,false);
});
test("unavailable candidates are rejected",()=>{
  const r=role("r","Developer",["JavaScript"]);
  const p=profile("a",[["JavaScript",1]],{availability:{start:"2027-01-01",end:"2027-02-01"}});
  assert.equal(scoreRoleCandidate(p,r,baseProject).eligible,false);
});
test("higher skill fit improves ranking",()=>{
  const r=role("r","Developer",["JavaScript"]);
  const hi=profile("hi",[["JavaScript",1]]),lo=profile("lo",[["JavaScript",.65]]);
  assert.equal(rankCandidates(baseProject,r,[lo,hi])[0].profile.id,"hi");
});
test("reliability affects ranking",()=>{
  const r=role("r","Developer",["JavaScript"]);
  const hi=profile("hi",[["JavaScript",.9]],{reliabilityScore:.99,completionRate:.99,responseRate:.99});
  const lo=profile("lo",[["JavaScript",.9]],{reliabilityScore:.6,completionRate:.6,responseRate:.6});
  assert.equal(rankCandidates(baseProject,r,[lo,hi])[0].profile.id,"hi");
});
test("extreme over-budget teams are pruned",()=>{
  const p={...baseProject,budgetMax:500,requiredRoles:[role("r","Developer",["JavaScript"],500)]};
  const expensive=profile("x",[["JavaScript",1]],{projectRate:2000,minimumBudget:100});
  assert.equal(optimizeTeams(p,[expensive]).length,0);
});
test("missing required roles lowers team coverage score",()=>{
  const r1=role("r1","Developer",["JavaScript"]),r2=role("r2","Designer",["Design"]);
  const p={...baseProject,requiredRoles:[r1,r2]};
  const dev=profile("dev",[["JavaScript",1]]);
  const match=scoreRoleCandidate(dev,r1,p);
  const fullish=scoreTeam(p,[{roleId:"r1",profileId:"dev",match,incrementalCost:1000}],[dev]);
  assert.equal(fullish.roleCoverage,.5);
});
test("one candidate may cover two roles when eligible",()=>{
  const r1=role("r1","Developer",["JavaScript"]),r2=role("r2","Designer",["Design"]);
  const p={...baseProject,teamSizeMin:1,requiredRoles:[r1,r2]};
  const multi=profile("multi",[["JavaScript",1],["Design",1]],{desiredRoles:["Developer","Designer"],projectRate:800});
  const teams=optimizeTeams(p,[multi]);
  assert.ok(teams.length>0);
  assert.equal(teams[0].metrics.memberCount,1);
});
test("blocked users are never combined by optimizer",()=>{
  const r1=role("r1","Developer",["JavaScript"]),r2=role("r2","Designer",["Design"]);
  const p={...baseProject,requiredRoles:[r1,r2]};
  const a=profile("a",[["JavaScript",1]],{blockedUsers:["b"],desiredRoles:["Developer"]});
  const b=profile("b",[["Design",1]],{blockedUsers:["a"],desiredRoles:["Designer"]});
  assert.equal(optimizeTeams(p,[a,b]).length,0);
});
test("replacement matching excludes current members",()=>{
  const r=role("r","Developer",["JavaScript"]);const p={...baseProject,requiredRoles:[r]};
  const a=profile("a",[["JavaScript",1]]),b=profile("b",[["JavaScript",.9]]);
  const rep=replacementForRole(p,"r",[{roleId:"r",profileId:"a"}],[a,b]);
  assert.equal(rep.profile.id,"b");
});
test("different goals produce different role structures",()=>{
  const a=parseGoalFallback("Build an iOS fitness app");
  const b=parseGoalFallback("Produce a short film");
  assert.notDeepEqual(a.requiredRoles.map(x=>x.title),b.requiredRoles.map(x=>x.title));
});
test("same inputs produce deterministic ranking",()=>{
  const r=role("r","Developer",["JavaScript"]);const a=profile("a",[["JavaScript",.9]]),b=profile("b",[["JavaScript",.8]]);
  const one=rankCandidates(baseProject,r,[a,b]).map(x=>x.profile.id);
  const two=rankCandidates(baseProject,r,[a,b]).map(x=>x.profile.id);
  assert.deepEqual(one,two);
});
test("score components combine to configured weighted score",()=>{
  const r=role("r","Developer",["JavaScript"]);const p=profile("a",[["JavaScript",.9]]);
  const m=scoreRoleCandidate(p,r,baseProject);
  const total=Object.entries(DEFAULT_MATCH_WEIGHTS).reduce((s,[k,w])=>s+m.breakdown[k]*w,0);
  assert.ok(Math.abs(total-m.score)<1e-9);
});