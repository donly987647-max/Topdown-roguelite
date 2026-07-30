'use strict';
(async()=>{
  const files=['pkg-01.dat','pkg-02.dat','pkg-03.dat','pkg-04a.dat','pkg-04b.dat','pkg-05.dat','pkg-06.dat','pkg-07.dat','pkg-08.dat'];
  const status=document.getElementById('loading');
  const setStatus=(title,detail='')=>{
    if(status) status.innerHTML=`<b>${title}</b><span>${detail}</span>`;
  };
  const loadPako=()=>new Promise((resolve,reject)=>{
    if(window.pako){ resolve(window.pako); return; }
    const script=document.createElement('script');
    script.src='https://cdn.jsdelivr.net/npm/pako@2.1.0/dist/pako.min.js';
    script.crossOrigin='anonymous';
    script.onload=()=>window.pako?resolve(window.pako):reject(new Error('pako load failed'));
    script.onerror=()=>reject(new Error('pako network load failed'));
    document.head.appendChild(script);
  });
  try{
    setStatus('LOADING','패키지 파일 확인 중');
    const chunks=await Promise.all(files.map(async f=>{
      const r=await fetch(f,{cache:'no-store'});
      if(!r.ok) throw new Error(`${f}: HTTP ${r.status}`);
      return (await r.text()).replace(/\s+/g,'');
    }));
    const joined=chunks.join('');
    const binary=atob(joined);
    const compressed=Uint8Array.from(binary,c=>c.charCodeAt(0));
    let jsonText='';
    setStatus('LOADING','게임 데이터 압축 해제 중');
    try{
      const pako=await loadPako();
      jsonText=pako.ungzip(compressed,{to:'string'});
    }catch(pakoError){
      if(typeof DecompressionStream!=='function') throw pakoError;
      const stream=new Blob([compressed]).stream().pipeThrough(new DecompressionStream('gzip'));
      jsonText=new TextDecoder('utf-8').decode(await new Response(stream).arrayBuffer());
    }
    const pkg=JSON.parse(jsonText);
    if(!pkg.html||!pkg.css||!pkg.js) throw new Error('패키지 구성 요소가 누락되었습니다.');
    const html=pkg.html
      .replace('<link rel="manifest" href="manifest.json">','')
      .replace('<link rel="stylesheet" href="style.css">',`<style>${pkg.css}</style>`)
      .replace('<script src="game.js"></script>',`<script>${pkg.js}<\/script>`);
    document.open();
    document.write(html);
    document.close();
  }catch(error){
    console.error(error);
    setStatus('LOAD ERROR',String(error&&error.message?error.message:error));
  }
})();
