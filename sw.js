const CACHE='last-magazine-1.0.5-tutorial';
const ASSETS=['./','./index.html','./style.css','./responsive.css','./tutorial.css','./viewport-fix.js','./tutorial.js','./data.js','./game-1.js','./game-2-v1.js','./game-2-v2.js','./game-2-v3.js','./game-2-v4.js','./game-3-1.js','./game-3-2.js','./game-3-3.js','./game-4-1.js','./game-4-2.js','./manifest.json'];
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)).then(()=>self.skipWaiting())));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request).then(res=>{const copy=res.clone();caches.open(CACHE).then(c=>c.put(e.request,copy));return res}).catch(()=>caches.match('./index.html')))));
