'use strict';
(async()=>{
 const files=['payload-01.txt', 'payload-02.txt', 'payload-03.txt', 'payload-04.txt', 'payload-05.txt', 'payload-06.txt', 'payload-07.txt', 'payload-08.txt'];
 try{
  const chunks=await Promise.all(files.map(f=>fetch(f,{cache:'no-store'}).then(r=>{if(!r.ok)throw new Error(`${f} ${r.status}`);return r.text()})));
  const bin=atob(chunks.join('').replace(/\s+/g,''));
  const bytes=Uint8Array.from(bin,c=>c.charCodeAt(0));
  const pkg=JSON.parse(new TextDecoder('utf-8').decode(bytes));
  const style=document.createElement('style');style.textContent=pkg.css;document.head.appendChild(style);
  (0,eval)(pkg.js);
 }catch(error){console.error(error);document.body.innerHTML='<main style="padding:24px;color:white;background:#090b0d;font-family:sans-serif"><h1>LOAD ERROR</h1><p>'+String(error)+'</p></main>'}
})();
