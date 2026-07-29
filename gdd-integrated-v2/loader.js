'use strict';
(async()=>{
  const files=['pkg-01.dat','pkg-02.dat','pkg-03.dat','pkg-04.dat','pkg-05.dat','pkg-06.dat','pkg-07.dat','pkg-08.dat'];
  try{
    const chunks=await Promise.all(files.map(f=>fetch(f,{cache:'no-store'}).then(r=>{if(!r.ok)throw new Error(`${f}: ${r.status}`);return r.text();})));
    const binary=atob(chunks.join('').replace(/\s+/g,''));
    const compressed=Uint8Array.from(binary,c=>c.charCodeAt(0));
    const stream=new Blob([compressed]).stream().pipeThrough(new DecompressionStream('gzip'));
    const pkg=JSON.parse(new TextDecoder('utf-8').decode(await new Response(stream).arrayBuffer()));
    let html=pkg.html
      .replace('<link rel="manifest" href="manifest.json">','')
      .replace('<link rel="stylesheet" href="style.css">',`<style>${pkg.css}</style>`)
      .replace('<script src="game.js"></script>',`<script>${pkg.js}<\/script>`);
    document.open();
    document.write(html);
    document.close();
  }catch(error){
    console.error(error);
    document.getElementById('loading').innerHTML=`<b>LOAD ERROR</b><span>${String(error)}</span>`;
  }
})();
