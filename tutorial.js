'use strict';
(()=>{
const VERSION=1;
const coarse=()=>matchMedia('(pointer:coarse)').matches;
const steps=[
 {id:'move',title:'이동',text:()=>coarse()?'왼쪽 스틱을 밀어 이동하십시오. 짧게 방향을 바꾸며 정지 반응도 확인합니다.':'WASD로 이동하십시오. 짧게 방향을 바꾸며 정지 반응도 확인합니다.'},
 {id:'fire',title:'조준과 발사',text:()=>coarse()?'오른쪽 스틱을 적 방향으로 밀면 조준과 발사가 동시에 진행됩니다.':'마우스로 조준하고 왼쪽 버튼으로 발사하십시오.'},
 {id:'reload',title:'재장전',text:()=>coarse()?'몇 발을 사용한 뒤 R 버튼을 누르십시오. 게이지의 밝은 구간에 맞추면 완벽 재장전이 됩니다.':'몇 발을 사용한 뒤 R을 누르십시오. 게이지의 밝은 구간에 맞추면 완벽 재장전이 됩니다.'},
 {id:'dash',title:'회피 구르기',text:()=>coarse()?'DASH를 눌러 공격을 통과하십시오. 구르기 중 일부 구간에는 무적 판정이 있습니다.':'Space를 눌러 공격을 통과하십시오. 구르기 중 일부 구간에는 무적 판정이 있습니다.'},
 {id:'telegraph',title:'적 공격 예고',text:()=> '붉은 탄환, 바닥 원형 표시, 충전선이 공격 예고입니다. 피해가 발생한 원인을 화면에서 먼저 찾으십시오.'},
 {id:'clear',title:'방 클리어',text:()=> '남은 적을 모두 제거하십시오. 전투가 끝나면 드롭된 고철과 자원이 자동으로 정리됩니다.'},
 {id:'reward',title:'부품 획득',text:()=> 'ROOM CLEAR 화면에서 세 보상 중 하나를 선택하십시오. 현재 빌드와 맞는 보상, 범용 보상, 새 방향의 보상이 섞여 나옵니다.'},
 {id:'assembly',title:'무기 조립',text:()=> '보상으로 받은 총열·탄창·코어는 무기 성격을 바꿉니다. 장착 전 피해, 탄창, 재장전, 과열 변화를 비교하십시오.'},
 {id:'grid',title:'장비 격자 배치',text:()=> '6×5 가방에서 모듈을 선택하고 회전·자동 배치를 사용하십시오. 전력·탄약·냉각·신호 연결이 활성 효과를 결정합니다.'},
 {id:'shop',title:'상점과 경로',text:()=> '다음 경로의 위험과 보상을 비교하십시오. 상점에서는 구매뿐 아니라 판매·새로고침·빌드 보정이 중요합니다.'},
 {id:'miniboss',title:'첫 미니보스',text:()=> '미니보스는 공격 예고와 반복 패턴을 학습하는 시험입니다. 패턴을 확인한 뒤 안전한 공격 시간을 확보하십시오.'}
];
const state={active:false,index:0,baseline:null,rewardSeen:false,inventorySeen:false,bossSeen:false,stepStarted:0,raf:0};
let root,titleEl,textEl,stepEl,progressEl,nextBtn,skipBtn;
function ensureTutorialSave(){
 if(!save.settings)save.settings={};
 if(save.settings.tutorialMessages===undefined)save.settings.tutorialMessages=true;
 const old=save.tutorial||{};
 save.tutorial={version:VERSION,completed:!!old.completed,step:Number.isFinite(old.step)?old.step:0,completedAt:old.completedAt||null};
 store();
}
function buildUI(){
 if(document.querySelector('#tutorialCoach'))return;
 root=document.createElement('aside');root.id='tutorialCoach';root.className='hidden';root.setAttribute('aria-live','polite');
 root.innerHTML='<div class="tutorial-card"><div class="tutorial-head"><span class="tutorial-kicker">FIELD TRAINING</span><span class="tutorial-step"></span></div><h3></h3><p></p><div class="tutorial-progress"></div><div class="tutorial-actions"><button type="button" data-tutorial-skip>튜토리얼 종료</button><button type="button" class="primary" data-tutorial-next>다음</button></div></div>';
 document.body.appendChild(root);
 titleEl=root.querySelector('h3');textEl=root.querySelector('p');stepEl=root.querySelector('.tutorial-step');progressEl=root.querySelector('.tutorial-progress');nextBtn=root.querySelector('[data-tutorial-next]');skipBtn=root.querySelector('[data-tutorial-skip]');
 nextBtn.onclick=()=>advance('manual');
 skipBtn.onclick=()=>finish(false);
}
function addTitleButton(){
 const box=document.querySelector('#titleScreen .title-actions');if(!box||document.querySelector('#tutorialStartBtn'))return;
 const b=document.createElement('button');b.id='tutorialStartBtn';b.textContent='튜토리얼';
 if(!save.tutorial.completed)b.classList.add('tutorial-pulse');
 b.onclick=()=>launchTutorial();box.prepend(b);
}
function patchSettings(){
 if(typeof renderSettings!=='function'||renderSettings.__tutorialPatched)return;
 const base=renderSettings;
 renderSettings=function(modal){
  base(modal);
  const list=modal.querySelector('.scroll-list');if(!list)return;
  const wrap=document.createElement('div');wrap.className='stat-box';
  wrap.innerHTML=`<label class="contract"><input type="checkbox" data-setting="tutorialMessages" ${save.settings.tutorialMessages?'checked':''}> 튜토리얼 안내 표시</label><button id="replayTutorial">튜토리얼 다시 시작</button>`;
  list.insertBefore(wrap,list.lastElementChild);
  wrap.querySelector('#replayTutorial').onclick=()=>{save.tutorial.completed=false;save.tutorial.step=0;save.settings.tutorialMessages=true;store();show('title');launchTutorial()};
 };
 renderSettings.__tutorialPatched=true;
}
function launchTutorial(){
 ensureTutorialSave();
 save.settings.tutorialMessages=true;save.tutorial.completed=false;save.tutorial.step=0;store();
 selectedChar='mara';selectedMode='quick';selectedThreat=0;selectedContracts.clear();
 setupUI();startRun();begin(true);
}
function begin(force=false){
 ensureTutorialSave();buildUI();
 if(!force&&(!save.settings.tutorialMessages||save.tutorial.completed))return;
 state.active=true;state.index=force?0:Math.max(0,Math.min(steps.length-1,save.tutorial.step||0));state.rewardSeen=false;state.inventorySeen=false;state.bossSeen=false;
 enterStep();cancelAnimationFrame(state.raf);state.raf=requestAnimationFrame(tick);
}
function enterStep(){
 if(!state.active)return;
 state.stepStarted=performance.now();state.baseline=null;
 if(run?.player)state.baseline={x:run.player.x,y:run.player.y,ammo:run.player.ammo,bullets:run.bullets?.length||0};
 const id=steps[state.index].id;
 if(id==='reward'&&isActiveScreen('reward'))state.rewardSeen=true;
 if(id==='assembly'&&isActiveScreen('inventory'))state.inventorySeen=true;
 render();save.tutorial.step=state.index;store();
}
function render(){
 buildUI();const s=steps[state.index];
 root.classList.remove('hidden');root.querySelector('.tutorial-card').classList.toggle('bottom',['fire','reload','dash'].includes(s.id));
 titleEl.textContent=s.title;textEl.innerHTML=s.text();stepEl.textContent=`${state.index+1} / ${steps.length}`;
 progressEl.innerHTML=steps.map((_,i)=>`<i class="${i<state.index?'done':i===state.index?'current':''}"></i>`).join('');
 nextBtn.hidden=!['telegraph','assembly','shop','miniboss'].includes(s.id);
 nextBtn.textContent=s.id==='miniboss'?'훈련 완료':'다음';
}
function advance(reason='auto'){
 if(!state.active)return;
 if(state.index>=steps.length-1){finish(true);return}
 state.index++;enterStep();
}
function finish(completed){
 state.active=false;cancelAnimationFrame(state.raf);if(root)root.classList.add('hidden');
 save.tutorial.completed=!!completed;save.tutorial.step=completed?steps.length:state.index;save.tutorial.completedAt=completed?new Date().toISOString():save.tutorial.completedAt;store();
 const b=document.querySelector('#tutorialStartBtn');if(b)b.classList.toggle('tutorial-pulse',!completed);
 toast(completed?'기초 훈련을 완료했습니다. 설정에서 다시 실행할 수 있습니다.':'튜토리얼을 종료했습니다. 설정에서 다시 시작할 수 있습니다.',2800);
}
function elapsed(ms){return performance.now()-state.stepStarted>=ms}
function isActiveScreen(name){return screen===name||document.querySelector(`#${name}Screen`)?.classList.contains('active')}
function tick(){
 if(!state.active)return;
 const s=steps[state.index],p=run?.player;
 if(!run&&s.id!=='miniboss'){finish(false);return}
 if(s.id==='move'&&p&&state.baseline&&Math.hypot(p.x-state.baseline.x,p.y-state.baseline.y)>48)advance();
 else if(s.id==='fire'&&p&&state.baseline&&((run.bullets?.length||0)>state.baseline.bullets||p.ammo<state.baseline.ammo))advance();
 else if(s.id==='reload'&&p&&(p.reloading||(state.baseline&&p.ammo>state.baseline.ammo)))advance();
 else if(s.id==='dash'&&p&&(p.roll>0||p.rollCd>0))advance();
 else if(s.id==='telegraph'&&((run.enemyBullets?.length||0)>0||(run.hazards?.length||0)>0)&&elapsed(1300))advance();
 else if(s.id==='clear'&&(run.roomClear||isActiveScreen('reward')))advance();
 else if(s.id==='reward'){
  if(isActiveScreen('reward'))state.rewardSeen=true;
  if(state.rewardSeen&&!isActiveScreen('reward'))advance();
 }
 else if(s.id==='assembly'){
  if(isActiveScreen('inventory'))state.inventorySeen=true;
  if(state.inventorySeen&&elapsed(1800)&&document.querySelector('#moduleTray .selected, #moduleTray [aria-selected="true"]'))advance();
 }
 else if(s.id==='grid'&&state.inventorySeen&&!isActiveScreen('inventory')&&elapsed(500))advance();
 else if(s.id==='shop'&&isActiveScreen('route')&&elapsed(1500)){
  nextBtn.hidden=false;
 }
 else if(s.id==='miniboss'){
  const boss=(run.enemies||[]).some(e=>!e.dead&&(e.boss||/보스|감독관|수호자|집행자/.test(e.name||'')));
  if(boss)state.bossSeen=true;
  if(state.bossSeen&&!boss&&run.roomClear)finish(true);
 }
 state.raf=requestAnimationFrame(tick);
}
document.addEventListener('pointerdown',e=>{
 if(!state.active)return;const s=steps[state.index].id,t=e.target;
 if(s==='assembly'&&t.closest('#moduleTray'))setTimeout(()=>advance('module'),100);
 if(s==='grid'&&t.closest('#applyBag'))setTimeout(()=>advance('apply'),120);
 if(s==='shop'&&t.closest('#routeCards'))setTimeout(()=>advance('route'),120);
},true);
ensureTutorialSave();buildUI();addTitleButton();patchSettings();
window.LM_TUTORIAL={start:launchTutorial,begin,stop:()=>finish(false),next:()=>advance('api'),state:()=>({active:state.active,index:state.index,id:steps[state.index]?.id,completed:save.tutorial.completed})};
if(!save.tutorial.completed&&save.settings.tutorialMessages)setTimeout(()=>toast('첫 플레이는 제목 화면의 튜토리얼을 권장합니다.',3200),500);
})();
