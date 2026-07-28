extends Node

var zones=[]; var characters=[]; var weapons=[]; var barrels=[]; var magazines=[]; var cores=[]
var modules=[]; var active_items=[]; var enemies=[]; var bosses=[]; var room_templates=[]; var events=[]; var synergies=[]; var achievements=[]

func _ready():
    zones=[
        _zone("assembly","폐기 조립라인","#82715a","#ffb75a"), _zone("bio","생화학 처리시설","#36584c","#73ff9e"),
        _zone("ammo","중앙 탄약저장고","#4c4141","#ff6d5d"), _zone("command","지휘 제어망","#303650","#77a8ff"),
        _zone("memory","기억 보관소","#483b62","#cf8cff")]
    characters=[
        _character("mara","정비공 마라","균형형",100,260,1,"pistol","#63d7ff","repair_drone"),
        _character("kane","탈주병 케인","연속 처치 공격형",90,273,0,"carbine","#ffb45f","tactical_reload"),
        _character("nova","실험체 노바","상태 이상 고위험",80,260,0,"arc","#d287ff","mutation"),
        _character("rex","밀수업자 렉스","경제·결함 거래",95,260,0,"saw","#ffdd62","reroll"),
        _character("shell","셸-07","에너지 생존 비밀 캐릭터",70,281,3,"beam","#a9f5ea","hack")]
    var weapon_rows=[
        ["pistol","서비스 피스톨","semi",18,.24,10,1.15,760,1,"균형형"],["carbine","버스트 카빈","burst",11,.32,24,1.45,780,3,"3점사"],
        ["smg","체인 SMG","auto",7,.075,36,1.7,720,1,"연속 명중"],["shotgun","브리치 샷건","spread",7,.75,5,1.8,560,8,"근거리 산탄"],
        ["rail","레일 랜서","charge",90,1.05,4,1.9,1100,1,"충전 관통"],["rotary","로터리 캐논","spin",9,.07,80,2.7,760,1,"회전 과열"],
        ["grenade","파편 발사기","grenade",48,.82,4,2.1,430,1,"범위 폭발"],["arc","아크 프로젝터","chain",8,.13,60,1.9,520,1,"전기 연쇄"],
        ["beam","빔 커터","beam",16,.08,100,2.2,900,1,"지속 열"],["saw","톱날 캐스터","ricochet",24,.38,8,1.5,600,1,"벽 도탄"],
        ["drone","드론 컨트롤러","drone",13,.42,12,1.7,650,2,"지원 드론"],["hammer","압축 해머","melee",65,.72,1,.5,170,1,"근접 반사"]]
    for row in weapon_rows: weapons.append(_weapon(row))
    _build_parts(); _build_modules(); _build_enemies(); _build_meta()

func _build_parts():
    var bn=["표준","장거리","확산","관통","도탄","과열","저소음","중량","분열","부식","빙결","전기"]
    var mn=["표준","확장","속사","마지막","폭발","재생","결함","쌍열","정밀","냉각","흡혈","무한"]
    var cn=["균형","화염","냉각","전도","부식","출혈","중력","시간","분열","유도","과부하","기억"]
    var status=["none","burn","freeze","shock","corrode","bleed","gravity","slow","split","homing","overload","memory"]
    for i in 12:
        barrels.append({"id":"barrel_%02d"%i,"name":bn[i]+" 총열","damage":.9+i*.025,"speed":.9+(i%4)*.08,"spread":max(.35,1.15-i*.055)})
        magazines.append({"id":"mag_%02d"%i,"name":mn[i]+" 탄창","capacity":.82+(i%6)*.1,"reload":1.16-(i%5)*.06})
        cores.append({"id":"core_%02d"%i,"name":cn[i]+" 코어","damage":.92+(i%5)*.05,"status":status[i]})

func _build_modules():
    var roots=[["반동 흡수기","accuracy",.1],["고속 급탄기","fire_rate",.08],["압축 냉각판","cooling",.12],["충격 장갑","armor",1.0],["증폭 렌즈","critical",.05],["자기 탄도계","homing",.1],["정밀 회피 회로","dodge",.08],["고철 압축기","economy",.1],["상태 증폭 셀","status",.12],["보스 분석기","boss",.1],["관통 보조기","pierce",1.0],["도탄 제어기","ricochet",1.0]]
    for tier in 5:
        for root in roots:
            modules.append({"id":"module_%02d"%modules.size(),"name":"%s Mk.%d"%[root[0],tier+1],"effect":root[1],"value":float(root[2])*(1+tier*.28),"tier":tier+1,"size":Vector2i(1+tier%2,1+(tier+modules.size())%2),"connector":["power","ammo","cooling","signal"][modules.size()%4]})
    var active_names=["수리 드론","전술 재장전","돌연변이 주입","시장 재협상","공장 해킹","중력 폭탄","시간 정지기","탄막 삭제기","자동 포탑","방어 장벽","EMP 펄스","응급 주사","탄약 복제기","과열 방출기","정밀 조준기","도탄 증폭기","부식 살포기","냉각 폭발","전력 과부하","기억 복원기"]
    for i in 20: active_items.append({"id":"active_%02d"%i,"name":active_names[i],"cooldown":8+(i%5)*2,"effect":["heal","reload","status","reroll","hack","gravity","time","clear","turret","barrier"][i%10]})

func _build_enemies():
    var names=["폐기 드론","용접 벌레","운반기","절단기","프레스 경비","불량 조립체","탐지기","고철 투척기","배양체","산성 포자","정화 로봇","독성 주입기","증식 세포","냉각 표본","변이 추적자","봉합체","탄약 운반차","점화 병사","폭발 상자","기관포 포대","유도탄 발사기","장갑 수송기","탄피 포식자","불발탄 군집","감시 노드","레이저 격자","명령 복제체","방화벽 수호자","신호 절단기","기억 사냥꾼","위상 경비","삭제 프로토콜"]
    var types=["chaser","shooter","orbiter","tank","dasher","miner"]
    for i in 32:
        var zone=min(3,int(i/8)); enemies.append({"id":"enemy_%02d"%i,"name":names[i],"zone":zone,"archetype":types[i%6],"hp":18+i*4.2,"speed":72+(i%7)*9,"damage":7+(i%6)*2,"cooldown":.85+(i%5)*.22,"color":zones[zone].accent.lerp(Color.WHITE,(i%4)*.09)})
    var rows=[["gr01","폐기 감독관 GR-01",0,2400,80,16,"#ffb45f"],["eve09","배양 관리자 EVE-09",1,3000,92,18,"#75ff9d"],["atlas","탄약 수호자 ATLAS",2,3700,75,20,"#ff6f62"],["motherline","MOTHERLINE",3,5200,64,22,"#7aaeff"],["archive","기억 원형체",4,4400,84,21,"#d38cff"]]
    for r in rows: bosses.append({"id":r[0],"name":r[1],"zone":r[2],"hp":r[3],"speed":r[4],"damage":r[5],"color":Color(r[6])})

func _build_meta():
    for i in 120: room_templates.append({"id":"room_%03d"%i,"zone":i%4,"layout":i%12,"hazard":i%5,"waves":2+i%3,"elite":i%11==0})
    for i in 35: events.append({"id":"event_%02d"%i,"name":"공장 사건 기록 %02d"%(i+1),"risk":i%4,"reward":1+i%5})
    for i in 50: synergies.append({"id":"synergy_%02d"%i,"name":"조립 시너지 %02d"%(i+1),"tags":["tag_%d"%(i%12),"tag_%d"%((i+3)%12)]})
    for i in 45: achievements.append({"id":"ACH_%02d"%i,"name":"회수 기록 %02d"%(i+1),"hidden":i>=36})

func _zone(id,name,color,accent): return {"id":id,"name":name,"color":Color(color),"accent":Color(accent)}
func _character(id,name,role,hp,speed,shield,weapon,color,active): return {"id":id,"name":name,"role":role,"hp":float(hp),"speed":float(speed),"shield":shield,"weapon":weapon,"color":Color(color),"active":active}
func _weapon(r): return {"id":r[0],"name":r[1],"kind":r[2],"damage":float(r[3]),"rate":float(r[4]),"magazine":r[5],"reload":float(r[6]),"projectile_speed":float(r[7]),"projectiles":r[8],"description":r[9]}
func get_character(id):
    for e in characters:
        if e.id==id:return e
    return characters[0]
func get_weapon(id):
    for e in weapons:
        if e.id==id:return e
    return weapons[0]
func content_counts(): return {"characters":characters.size(),"zones":zones.size(),"weapons":weapons.size(),"barrels":barrels.size(),"magazines":magazines.size(),"cores":cores.size(),"modules":modules.size(),"active_items":active_items.size(),"enemies":enemies.size(),"bosses":bosses.size(),"rooms":room_templates.size(),"events":events.size(),"synergies":synergies.size(),"achievements":achievements.size()}
