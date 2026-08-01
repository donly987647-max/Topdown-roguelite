class_name RunSceneCoordinator
extends Node

signal room_transition_started(room_id: StringName)
signal room_transition_finished(room_id: StringName, template_id: StringName)
signal reward_panel_requested(choices: Array[RewardOffer])
signal route_panel_requested(room_ids: Array[StringName])
signal map_state_changed(state: Dictionary)

@export var difficulty_multiplier: float = 1.0

var run_state: RunStateController
var room_runtime: RoomSceneRuntime
var template_registry: RoomTemplateRegistry
var player: Node2D
var camera: Camera2D
var entry_camera := RoomEntryCameraController.new()
var _transitioning := false

func configure(state: RunStateController, runtime: RoomSceneRuntime, registry: RoomTemplateRegistry, player_node: Node2D = null, camera_node: Camera2D = null) -> bool:
	if state == null or runtime == null or registry == null:
		return false
	run_state = state
	room_runtime = runtime
	template_registry = registry
	player = player_node
	camera = camera_node
	_bind_signals()
	return true

func _bind_signals() -> void:
	if not run_state.room_entered.is_connected(_on_room_entered):
		run_state.room_entered.connect(_on_room_entered)
	if not run_state.reward_choices_ready.is_connected(_on_reward_choices_ready):
		run_state.reward_choices_ready.connect(_on_reward_choices_ready)
	if not run_state.route_choices_ready.is_connected(_on_route_choices_ready):
		run_state.route_choices_ready.connect(_on_route_choices_ready)
	if not room_runtime.room_scene_cleared.is_connected(_on_room_scene_cleared):
		room_runtime.room_scene_cleared.connect(_on_room_scene_cleared)

func _on_room_entered(room_id: StringName, room_type: StringName) -> void:
	if _transitioning:
		return
	_transitioning = true
	room_transition_started.emit(room_id)
	var template := run_state.current_template()
	if template == null:
		template = _select_and_bind_template(room_id, room_type)
	if template == null:
		_transitioning = false
		push_warning("No room template available for %s" % String(room_id))
		return
	_broadcast_room_entered(room_id, room_type)
	if not room_runtime.load_room(template, difficulty_multiplier):
		_transitioning = false
		push_warning("Failed to load room template %s" % String(template.id))
		return
	_apply_room_entry_and_camera(template)
	_transitioning = false
	room_transition_finished.emit(room_id, template.id)
	_emit_map_state()

func _apply_room_entry_and_camera(template: RoomTemplateDefinition) -> void:
	if room_runtime.room_root == null:
		return
	if player != null:
		entry_camera.place_player(player, room_runtime.room_root, template)
	if camera != null:
		entry_camera.apply_camera_bounds(camera, room_runtime.room_root, template)

func _select_and_bind_template(room_id: StringName, room_type: StringName) -> RoomTemplateDefinition:
	var node := run_state.current_node()
	if node == null:
		return null
	var zone_id := StringName(node.metadata.get("zone_id", "zone_1"))
	var target_threat := maxi(0, int(node.metadata.get("recommended_threat", node.difficulty + 4)))
	var template := template_registry.select(zone_id, room_type, target_threat)
	if template != null:
		run_state.register_room_template(template)
		run_state.bind_node_template(room_id, template.id)
	return template

func _on_room_scene_cleared(_template_id: StringName) -> void:
	if run_state == null:
		return
	room_runtime.set_exits_locked(true)
	_broadcast_room_cleared(run_state.current_room_id)
	var node := run_state.current_node()
	var major_reward := node != null and node.room_type in [&"combat", &"elite", &"boss"]
	run_state.clear_current_room(major_reward)
	_emit_map_state()

func choose_reward(index: int) -> bool:
	if run_state == null:
		return false
	var result := run_state.claim_reward(index)
	if result:
		_emit_map_state()
	return result

func choose_route(room_id: StringName) -> bool:
	if run_state == null or room_id not in run_state.available_routes():
		return false
	var result := run_state.enter_room(room_id)
	if result:
		_emit_map_state()
	return result

func _on_reward_choices_ready(choices: Array[RewardOffer]) -> void:
	room_runtime.set_exits_locked(true)
	reward_panel_requested.emit(choices)

func _on_route_choices_ready(room_ids: Array[StringName]) -> void:
	_bind_exit_targets(room_ids)
	room_runtime.set_exits_locked(room_ids.is_empty())
	route_panel_requested.emit(room_ids)
	_emit_map_state()

func _bind_exit_targets(room_ids: Array[StringName]) -> void:
	if room_runtime.room_root == null or room_runtime.template == null:
		return
	var exits: Array[Node] = []
	for node in get_tree().get_nodes_in_group(room_runtime.template.exit_group):
		if room_runtime.room_root.is_ancestor_of(node):
			exits.append(node)
	for index in range(exits.size()):
		var gate := exits[index]
		if index < room_ids.size() and gate.has_method("set_target_room"):
			gate.call("set_target_room", room_ids[index])
		if gate.has_signal("exit_requested"):
			var callable := Callable(self, "_on_exit_requested")
			if not gate.is_connected("exit_requested", callable):
				gate.connect("exit_requested", callable)

func _on_exit_requested(target_room_id: StringName) -> void:
	if target_room_id != &"":
		choose_route(target_room_id)

func _broadcast_room_entered(room_id: StringName, room_type: StringName) -> void:
	get_tree().call_group(&"room_lifecycle_listener", &"on_room_entered", room_id, room_type)

func _broadcast_room_cleared(room_id: StringName) -> void:
	get_tree().call_group(&"room_lifecycle_listener", &"on_room_cleared", room_id)

func _emit_map_state() -> void:
	if run_state == null:
		return
	map_state_changed.emit({
		"current": run_state.current_room_id,
		"visited": run_state.visited_rooms.duplicate(),
		"cleared": run_state.cleared_rooms.duplicate(),
		"routes": run_state.available_routes(),
		"finished": run_state.finished,
	})
