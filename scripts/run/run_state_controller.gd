class_name RunStateController
extends RefCounted

signal run_started(seed_value: int, start_room: StringName)
signal room_entered(room_id: StringName, room_type: StringName)
signal room_cleared(room_id: StringName)
signal reward_choices_ready(choices: Array[RewardOffer])
signal reward_claimed(offer: RewardOffer)
signal route_choices_ready(room_ids: Array[StringName])
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
var seed_value := 0
var finished := false
var run_context: Dictionary = {}

func register_room_template(template: RoomTemplateDefinition) -> void:
	if template != null and template.id != &"":
		room_templates[template.id] = template

func bind_node_template(node_id: StringName, template_id: StringName) -> void:
	if node_id != &"" and template_id != &"":
		node_to_template[node_id] = template_id

func start_run(new_graph: RunGraph, seed: int = 0, context: Dictionary = {}) -> bool:
	if new_graph == null or new_graph.start_id == &"" or not new_graph.nodes.has(new_graph.start_id):
		return false
	graph = new_graph
	seed_value = seed
	run_context = context
	current_room_id = graph.start_id
	visited_rooms = [current_room_id]
	cleared_rooms.clear()
	active_reward_choices.clear()
	finished = false
	run_started.emit(seed_value, current_room_id)
	_emit_room_entered(current_room_id)
	return true

func enter_room(room_id: StringName) -> bool:
	if finished or graph == null or not graph.nodes.has(room_id):
		return false
	if current_room_id != &"":
		var allowed := graph.edges.get(current_room_id, [])
		if room_id not in allowed:
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

func clear_current_room(major_reward: bool = true) -> bool:
	if finished or current_room_id == &"" or cleared_rooms.has(current_room_id):
		return false
	cleared_rooms[current_room_id] = true
	room_cleared.emit(current_room_id)
	if graph != null and current_room_id == graph.boss_id:
		finished = true
		run_finished.emit(true)
		return true
	if major_reward:
		active_reward_choices = reward_selector.generate_major_choices(build_tags)
	else:
		active_reward_choices = reward_selector.generate_choices()
	if not active_reward_choices.is_empty():
		reward_choices_ready.emit(active_reward_choices)
	else:
		_emit_routes()
	return true

func claim_reward(index: int) -> bool:
	if index < 0 or index >= active_reward_choices.size():
		return false
	var offer := active_reward_choices[index]
	var grant_context := run_context.duplicate(false)
	grant_context["offer"] = offer
	if not reward_grant_resolver.grant(offer, grant_context):
		return false
	reward_selector.claim(offer, build_tags)
	active_reward_choices.clear()
	reward_claimed.emit(offer)
	_emit_routes()
	return true

func available_routes() -> Array[StringName]:
	var result: Array[StringName] = []
	if graph == null or current_room_id == &"":
		return result
	for id in graph.edges.get(current_room_id, []):
		result.append(id)
	return result

func fail_run() -> void:
	if finished:
		return
	finished = true
	run_finished.emit(false)

func set_build_tags(tags: PackedStringArray) -> void:
	build_tags = tags

func serialize() -> Dictionary:
	var visited: Array[String] = []
	for id in visited_rooms:
		visited.append(String(id))
	var cleared: Array[String] = []
	for id in cleared_rooms.keys():
		cleared.append(String(id))
	return {
		"seed": seed_value,
		"current_room_id": String(current_room_id),
		"visited_rooms": visited,
		"cleared_rooms": cleared,
		"reward_history": reward_selector.serialize_history(),
		"build_tags": Array(build_tags),
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
	reward_selector.restore_history(data.get("reward_history", {}))
	build_tags = PackedStringArray(data.get("build_tags", []))
	finished = bool(data.get("finished", false))
	active_reward_choices.clear()
	return true

func _emit_room_entered(room_id: StringName) -> void:
	var node: RoomNodeDefinition = graph.nodes.get(room_id) if graph != null else null
	room_entered.emit(room_id, node.room_type if node != null else &"")

func _emit_routes() -> void:
	route_choices_ready.emit(available_routes())
