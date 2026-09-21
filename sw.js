const CACHE="swarm-v1";
const CORE=["/","/index.html","/styles.css","/src/app.mjs","/src/store.mjs","/src/demo-data.mjs","/src/goal-engine.mjs","/src/match-engine.mjs","/src/services.mjs","/manifest.webmanifest","/assets/swarm-mark.svg"];
self.addEventListener("install",e=>{self.skipWaiting();e.waitUntil(caches.open(CACHE).then(c=>c.addAll(CORE)))});
self.addEventListener("activate",e=>{e.waitUntil(Promise.all([self.clients.claim(),caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k))))]))});
self.addEventListener("fetch",e=>{
  if(e.request.method!=="GET")return;
  const u=new URL(e.request.url);
  if(u.origin!==location.origin)return;
  if(u.pathname.startsWith("/api/")){e.respondWith(fetch(e.request));return}
  e.respondWith(fetch(e.request).then(r=>{if(r.ok){const clone=r.clone();caches.open(CACHE).then(c=>c.put(e.request,clone))}return r}).catch(()=>caches.match(e.request)));
});