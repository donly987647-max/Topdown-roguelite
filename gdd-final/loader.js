'use strict';
(async()=>{
 const files=['pack-01.dat','pack-02.dat','pack-03.dat','pack-04.dat','pack-05.dat','pack-06.dat','pack-07.dat','pack-08.dat'];
 try{
  const chunks=await Promise.all(files.map(f=>fetch(f,{cache:'no-store'}).then(r=>{if(!r.ok)throw new Error(`${f} ${r.status}`);return r.text()})));
  const bin=atob(chunks.join('').replace(/\s+/g,''));
  const compressed=Uint8Array.from(bin,c=>c.charCodeAt(0));
  const stream=new Blob([compressed]).stream().pipeThrough(new DecompressionStream('gzip'));
  const bytes=new Uint8Array(await new Response(stream).arrayBuffer());
  const pkg=JSON.parse(new TextDecoder('utf-8').decode(bytes));
  const style=document.createElement('style');
  style.textContent=pkg.css;
  document.head.appendChild(style);
  (0,eval)(pkg.js);
 }catch(error){
  console.error(error);
  document.body.innerHTML='<main style="padding:24px;color:white;background:#090b0d;font-family:sans-serif"><h1>LOAD ERROR</h1><p>'+String(error)+'</p></main>';
 }
})();
