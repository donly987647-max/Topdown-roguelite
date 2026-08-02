class_name RunStateController
extends RefCounted

signal run_started(seed_value: int, start_room: StringName)
signal room_entered(room_id: StringName, room_type: StringName)
signal room_cleared(room_id: StringName)
signal reward_choices_ready(choices: Array[RewardOffer])
signal reward_claimed(offer: RewardOffer)
signal route_choices_ready(room_ids: Array[StringName])
signal boss_settlement_started(mandatory_rewards: Array[RewardOffer], choices: Array[RewardOffer])
signal run_finished(success: bool)

var graph: RunGraph
var reward_selector := RewardSelector.new()
var reward_grant_resolver := RewardGrantResolver.new()
var room_templates: Dictionary = {}
var node_to_template: Dictionary = {}
var current_room_id: StringName = &""
var visited_rooms: Array[StringName] = []
var cleared_rooms: Dictionary = {}
var active_reward_choices: Array[RewardOffer] = []
var build_tags: PackedStringArray = []
var selected_character_id: StringName = &""
var seed_value := 0
var finished := false
var run_context: Dictionary = {}
var boss_settlement_pending := false

func register_room_template(template: RoomTemplateDefinition) -> void:
	if template != null and template.id != &"":
		room_templates[template.id] = template

func bind_node_template(node_id: StringName, template_id: StringName) -> void:
	if node_id != &"" and template_id != &"":
		node_to_template[node_id] = template_id

func restore_registered_templates(registry: RoomTemplateRegistry) -> void:
	if registry == null:
		return
	for template_id in node_to_template.values():
		var template := registry.get_template(StringName(template_id))
		if template != null:
			register_room_template(template)

func start_run(new_graph: RunGraph, seed: int = 0, context: Dictionary = {}) -> bool:
	if new_graph == null or new_graph.start_id == &"" or not new_graph.nodes.has(new_graph.start_id):
		return false
	graph = new_graph
	seed_value = seed
	run_context = context
	current_room_id = graph.start_id
	visited_rooms = [current_room_id]
	cleared_rooms.clear()
	node_to_template.clear()
	active_reward_choices.clear()
	boss_settlement_pending = false
	finished = false
	run_started.emit(seed_value, current_room_id)
	_emit_room_entered(current_room_id)
	return true

func enter_room(room_id: StringName) -> bool:
	if finished or boss_settlement_pending or graph == null or not graph.nodes.has(room_id):
		return false
	if current_room_id != &"" and room_id not in graph.edges.get(current_room_id, []):
		return false
	current_room_id = room_id
	if room_id not in visited_rooms:
		visited_rooms.append(room_id)
	active_reward_choices.clear()
	_emit_room_entered(room_id)
	return true

func current_node() -> RoomNodeDefinition:
	if graph == null:
		return null
	return graph.nodes.get(current_room_id)

func current_template() -> RoomTemplateDefinition:
	var template_id: StringName = node_to_template.get(current_room_id, &"")
	return room_templates.get(template_id)

func clear_current_room(grant_combat_reward: bool = true) -> bool:
	if finished or current_room_id == &"" or cleared_rooms.has(current_room_id):
		return false
	cleared_rooms[current_room_id] = true
	room_cleared.emit(current_room_id)
	if graph != null and current_room_id == graph.boss_id:
		return _begin_boss_settlement()
	if grant_combat_reward:
		active_reward_choices = reward_selector.generate_major_choices(build_tags)
		if not active_reward_choices.is_empty():
			reward_choices_ready.emit(active_reward_choices)
			return true
	active_reward_choices.clear()
	_emit_routes()
	return true

func claim_reward(index: int) -> bool:
	if index < 0 or index >= active_reward_choices.size():
		return false
	var offer := active_reward_choices[index]
	if not _grant_offer(offer):
		return false
	reward_selector.claim(offer, build_tags)
	active_reward_choices.clear()
	reward_claimed.emit(offer)
	if boss_settlement_pending:
		boss_settlement_pending = false
		finished = true
		run_finished.emit(true)
	else:
		_emit_routes()
	return true

func available_routes() -> Array[StringName]:
	var result: Array[StringName] = []
	if boss_settlement_pending or graph == null or current_room_id == &"":
		return result
	for id in graph.edges.get(current_room_id, []):
		result.append(id)
	return result

func fail_run() -> void:
	if finished:
		return
	boss_settlement_pending = false
	active_reward_choices.clear()
	finished = true
	run_finished.emit(false)

func set_build_tags(tags: PackedStringArray) -> void:
	build_tags = tags

func set_character(id: StringName) -> void:
	selected_character_id = id

func resume_pending_flow() -> void:
	if finished:
		return
	if not active_reward_choices.is_empty():
		reward_choices_ready.emit(active_reward_choices)
	else:
		_emit_routes()

func _begin_boss_settlement() -> bool:
	var mandatory := _boss_mandatory_rewards()
	for offer in mandatory:
		if not _grant_offer(offer):
			push_warning("Failed to grant mandatory boss reward: %s" % String(offer.id))
	active_reward_choices = _boss_choice_rewards()
	boss_settlement_pending = true
	boss_settlement_started.emit(mandatory, active_reward_choices)
	if active_reward_choices.is_empty():
		boss_settlement_pending = false
		finished = true
		run_finished.emit(true)
	else:
		reward_choices_ready.emit(active_reward_choices)
	return true

func _boss_mandatory_rewards() -> Array[RewardOffer]:
	var rewards: Array[RewardOffer] = [
		RewardOffer.new(&"gr01_compressor_core", &"boss_part", &"rare", {"display_name":"GR-01 압축 코어", "description":"폐기물 압축기 GR-01 전용 부품.", "tags":["boss","impact","factory"]}, 0.0),
		RewardOffer.new(&"zone2_access_key", &"zone_key", &"rare", {"display_name":"생화학 처리시설 접근 키", "description":"다음 구역 진입 권한.", "zone_id":"zone_2"}, 0.0),
	]
	# The GDD defines only that the record is probabilistic. 35% is provisional balance tuning.
	if randf() < 0.35:
		rewards.append(RewardOffer.new(&"gr01_factory_record", &"record", &"rare", {"display_name":"GR-01 유지보수 기록", "description":"영구 기록 항목.", "permanent":true}, 0.0))
	return rewards

func _boss_choice_rewards() -> Array[RewardOffer]:
	return [
		RewardOffer.new(&"gr01_backpack_expansion", &"backpack_expansion", &"rare", {"display_name":"가방 확장", "description":"가방 외곽 셀 1칸을 확장한다.", "cell":[6,0], "tags":["backpack"]}, 0.0),
		RewardOffer.new(&"gr01_max_health", &"max_health", &"rare", {"display_name":"생존 구조 강화", "description":"최대 생명력을 15 증가시키고 같은 양을 회복한다.", "amount":15, "tags":["survival"]}, 0.0),
	]

func _grant_offer(offer: RewardOffer) -> bool:
	var grant_context := run_context.duplicate(false)
	grant_context["offer"] = offer
	return reward_grant_resolver.grant(offer, grant_context)

func serialize() -> Dictionary:
	var visited: Array[String] = []
	for id in visited_rooms:
		visited.append(String(id))
	var cleared: Array[String] = []
	for id in cleared_rooms.keys():
		cleared.append(String(id))
	var bindings: Dictionary = {}
	for node_id in node_to_template.keys():
		bindings[String(node_id)] = String(node_to_template[node_id])
	var choices: Array = []
	for offer in active_reward_choices:
		choices.append(offer.to_dictionary())
	return {
		"seed": seed_value,
		"current_room_id": String(current_room_id),
		"visited_rooms": visited,
		"cleared_rooms": cleared,
		"node_to_template": bindings,
		"reward_history": reward_selector.serialize_history(),
		"build_tags": Array(build_tags),
		"selected_character_id": String(selected_character_id),
		"active_reward_choices": choices,
		"boss_settlement_pending": boss_settlement_pending,
		"finished": finished,
	}

func restore(data: Dictionary, restored_graph: RunGraph, context: Dictionary = {}) -> bool:
	if restored_graph == null:
		return false
	var room_id := StringName(data.get("current_room_id", ""))
	if room_id == &"" or not restored_graph.nodes.has(room_id):
		return false
	graph = restored_graph
	run_context = context
	seed_value = int(data.get("seed", 0))
	current_room_id = room_id
	visited_rooms.clear()
	for raw in data.get("visited_rooms", []):
		visited_rooms.append(StringName(raw))
	cleared_rooms.clear()
	for raw in data.get("cleared_rooms", []):
		cleared_rooms[StringName(raw)] = true
	node_to_template.clear()
	for raw_node_id in data.get("node_to_template", {}).keys():
		node_to_template[StringName(raw_node_id)] = StringName(data["node_to_template"][raw_node_id])
	reward_selector.restore_history(data.get("reward_history", {}))
	build_tags = PackedStringArray(data.get("build_tags", []))
	selected_character_id = StringName(data.get("selected_character_id", ""))
	active_reward_choices.clear()
	for raw_offer in data.get("active_reward_choices", []):
		if raw_offer is Dictionary:
			active_reward_choices.append(RewardOffer.new(
				StringName(raw_offer.get("id", "")),
				StringName(raw_offer.get("category", "")),
				StringName(raw_offer.get("rarity", "common")),
				raw_offer.get("payload"),
				float(raw_offer.get("weight", 1.0))
			))
	boss_settlement_pending = bool(data.get("boss_settlement_pending", false))
	finished = bool(data.get("finished", false))
	return true

func _emit_room_entered(room_id: StringName) -> void:
	var node: RoomNodeDefinition = graph.nodes.get(room_id) if graph != null else null
	room_entered.emit(room_id, node.room_type if node != null else &"")

func _emit_routes() -> void:
	route_choices_ready.emit(available_routes())
