class_name CharacterCatalog
extends RefCounted

func all() -> Array[CharacterDefinition]:
	return [mara(), kane(), nova(), rex(), shell07()]

func selectable(unlocks: Dictionary = {}) -> Array[CharacterDefinition]:
	var result: Array[CharacterDefinition] = []
	for character in all():
		if not character.secret or bool(unlocks.get(character.unlock_key, false)):
			result.append(character)
	return result

func get_by_id(id: StringName) -> CharacterDefinition:
	for character in all():
		if character.id == id:
			return character
	return null

func mara() -> CharacterDefinition:
	return _make(&"mara", "정비공 마라", "균형형, 초보자 추천", 100.0, 1.0, 1, 0.0, 1.0, 1.0, 0, 0.80, &"service_pistol", &"field_modification", &"emergency_repair",
		"구역마다 부품 1회 무료 분해, 제작실 비용 20% 감소, 비호환 부품 전력 페널티 감소.",
		"방어판 1개 복구. 방어판이 없으면 생명력 15 회복. 적 처치로 충전.",
		["다양한 조합", "안정적 자원 운영", "부품 실험"])

func kane() -> CharacterDefinition:
	return _make(&"kane", "탈주병 케인", "연속 처치와 공격적 운영", 90.0, 1.05, 0, 0.08, 1.0, 1.0, 0, 1.0, &"burst_carbine", &"combat_focus", &"tactical_reload",
		"빠른 연속 처치로 집중 중첩을 얻어 발사·재장전·이동 속도가 증가하며 피격 또는 시간 경과로 감소.",
		"현재 무기를 즉시 재장전하고 다음 탄창의 탄약 소비를 제거.",
		["빠른 방 클리어", "공격 유지", "피격 손실 큼"])

func nova() -> CharacterDefinition:
	return _make(&"nova", "실험체 노바", "상태 이상과 고위험 빌드", 80.0, 1.0, 0, 0.0, 1.25, 0.70, 0, 1.0, &"arc_projector", &"unstable_cells", &"forced_mutation",
		"서로 다른 상태 이상 두 종류를 같은 적에게 적용하면 변이 반응을 일으킴.",
		"주변 적에게 무작위 상태 이상 2종을 즉시 부여.",
		["상태 조합", "높은 폭발력", "낮은 생존력"])

func rex() -> CharacterDefinition:
	return _make(&"rex", "밀수업자 렉스", "경제와 위험 거래", 95.0, 1.0, 0, 0.0, 1.0, 1.0, 60, 0.85, &"sawblade_caster", &"backroom_deal", &"price_manipulation",
		"상점마다 결함 상품 1개 추가, 판매 가격 증가, 빚 구매 가능.",
		"현재 방의 보상 하나를 다시 생성. 새 보상은 결함 확률 증가.",
		["상점 중심", "결함 빌드", "자원 계획"])

func shell07() -> CharacterDefinition:
	var character := _make(&"shell07", "셸-07", "생명력 대신 에너지로 생존하는 비밀 기계 캐릭터", 100.0, 1.0, 0, 0.0, 1.0, 0.0, 0, 1.0, &"beam_cutter", &"machine_body", &"system_override",
		"일반 회복 아이템 사용 불가. 방어판·에너지 중심 생존, 과열 효과 강화, 일부 기계 적 해킹.",
		"기계 시스템을 일시적으로 과부하시켜 해킹/과열 계열 효과를 강화.",
		["에너지 생존", "과열", "기계 해킹"])
	character.secret = true
	character.unlock_key = &"true_ending_shell07"
	return character

func _make(id: StringName, title: String, role: String, hp: float, speed: float, guard: int, crit: float, status_mult: float, heal_mult: float, scrap: int, shop_mult: float, frame: StringName, passive: StringName, active: StringName, passive_text: String, active_text: String, playstyle: Array) -> CharacterDefinition:
	var c := CharacterDefinition.new()
	c.id=id; c.display_name=title; c.role=role; c.max_health=hp; c.move_speed_multiplier=speed; c.starting_guard=guard
	c.crit_bonus=crit; c.status_buildup_multiplier=status_mult; c.healing_multiplier=heal_mult; c.starting_scrap=scrap; c.shop_price_multiplier=shop_mult
	c.starting_frame_id=frame; c.passive_id=passive; c.active_id=active; c.passive_description=passive_text; c.active_description=active_text; c.playstyle=PackedStringArray(playstyle)
	return c
