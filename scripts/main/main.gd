extends Node2D

var room: TestCombatRoom
var camera: CombatCamera
var hud: CombatHUD
var touch_layer: CanvasLayer
var touch_controls: MobileTouchControls
var reward_panel: WeaponRewardPanel
var backpack_panel: BackpackPanel
var route_panel: RouteChoicePanel
var route_status: RouteStatusPanel
var route_run: PrototypeRouteRun
var backpack := BackpackGrid.new()
var _room_clear_pending := false
var _transitioning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.reset_run()
	_build_prototype()
	EventBus.run_reset_requested.connect(_reset_prototype)
	EventBus.inventory_requested.connect(_on_inventory_requested)
	print("[LAST MAGAZINE] P2 eight-room route prototype booted.")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_on_inventory_requested()
		get_viewport().set_input_as_handled()

func _build_prototype() -> void:
	route_run = PrototypeRouteRun.new(GameState.run_seed)
	var first_room := route_run.start()
	room = TestCombatRoom.new()
	room.name = "RouteRoom01"
	room.configure(first_room)
	add_child(room)
	_connect_room(room)

	camera = CombatCamera.new()
	camera.name = "CombatCamera"
	add_child(camera)
	camera.setup(room.player, room.get_camera_limits())
	camera.make_current()

	hud = CombatHUD.new()
	hud.name = "CombatHUD"
	add_child(hud)

	route_status = RouteStatusPanel.new()
	route_status.name = "RouteStatusPanel"
	add_child(route_status)
	route_status.update_progress(route_run.get_progress_snapshot())

	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		touch_layer = CanvasLayer.new()
		touch_layer.name = "MobileTouchLayer"
		touch_layer.layer = 30
		add_child(touch_layer)
		touch_controls = MobileTouchControls.new()
		touch_controls.name = "MobileTouchControls"
		touch_layer.add_child(touch_controls)

func _connect_room(target_room: TestCombatRoom) -> void:
	target_room.reward_requested.connect(_on_reward_requested)
	target_room.room_cleared.connect(_on_room_cleared)

func _on_room_cleared(_room_snapshot: Dictionary) -> void:
	_room_clear_pending = true

func _on_reward_requested(options: Array) -> void:
	if is_instance_valid(reward_panel) or is_instance_valid(backpack_panel) or is_instance_valid(route_panel):
		return
	var typed_options: Array[WeaponPartData] = []
	for option in options:
		if option is WeaponPartData:
			typed_options.append(option as WeaponPartData)
	if typed_options.is_empty():
		_show_route_choice()
		return
	reward_panel = WeaponRewardPanel.new()
	reward_panel.name = "WeaponRewardPanel"
	reward_panel.configure(typed_options)
	reward_panel.part_selected.connect(_on_reward_part_selected)
	add_child(reward_panel)

func _on_reward_part_selected(part: WeaponPartData) -> void:
	if not _has_active_player():
		return
	var replaced_part := _find_equipped_part(part.slot)
	var next_parts := WeaponPartRewardPicker.replace_slot(room.player.weapon.equipped_parts, part)
	room.player.weapon.equip_parts(next_parts)
	if replaced_part != null:
		backpack.add_and_auto_place(replaced_part)
	var finished_panel := reward_panel
	reward_panel = null
	if is_instance_valid(finished_panel):
		await finished_panel.tree_exited
	_open_backpack_panel()

func _on_inventory_requested() -> void:
	if is_instance_valid(reward_panel) or is_instance_valid(backpack_panel) or is_instance_valid(route_panel):
		return
	_open_backpack_panel()

func _open_backpack_panel() -> void:
	if not _has_active_player() or not room.can_open_inventory():
		return
	backpack_panel = BackpackPanel.new()
	backpack_panel.name = "BackpackPanel"
	backpack_panel.configure(backpack, room.player)
	backpack_panel.equip_requested.connect(_on_backpack_equip_requested)
	backpack_panel.loadout_restore_requested.connect(_on_backpack_loadout_restore_requested)
	backpack_panel.closed.connect(_on_backpack_closed)
	add_child(backpack_panel)

func _on_backpack_equip_requested(item_id: StringName) -> void:
	if not _has_active_player():
		return
	var item := backpack.get_item(item_id)
	if item == null or item.part == null:
		return
	var grid_snapshot := backpack.create_snapshot()
	var previous_parts := _duplicate_parts(room.player.weapon.equipped_parts)
	var old_placement := backpack.get_placement(item_id)
	var selected_part := backpack.remove_item(item_id)
	if selected_part == null:
		return
	var replaced_part := _find_equipped_part(selected_part.slot)
	var next_parts := WeaponPartRewardPicker.replace_slot(room.player.weapon.equipped_parts, selected_part)
	room.player.weapon.equip_parts(next_parts)
	if replaced_part != null:
		var returned_id := backpack.add_part(replaced_part)
		var placed := false
		if not old_placement.is_empty():
			placed = backpack.place_item(
				returned_id,
				old_placement.get("origin", Vector2i.ZERO),
				int(old_placement.get("rotation", 0))
			)
		if not placed:
			placed = backpack.auto_place(returned_id)
		if not placed:
			backpack.restore_snapshot(grid_snapshot)
			room.player.weapon.equip_parts(previous_parts)
			return

func _on_backpack_loadout_restore_requested(parts: Array[WeaponPartData]) -> void:
	if _has_active_player():
		room.player.weapon.equip_parts(parts)

func _on_backpack_closed() -> void:
	backpack_panel = null
	if _room_clear_pending:
		call_deferred("_show_route_choice")

func _show_route_choice() -> void:
	if not _room_clear_pending or is_instance_valid(route_panel) or is_instance_valid(reward_panel) or is_instance_valid(backpack_panel):
		return
	route_panel = RouteChoicePanel.new()
	route_panel.name = "RouteChoicePanel"
	route_panel.configure(route_run.get_next_options(), route_run.get_progress_snapshot())
	route_panel.route_selected.connect(_on_route_selected)
	add_child(route_panel)

func _on_route_selected(room_id: StringName) -> void:
	route_panel = null
	if room_id == RouteChoicePanel.RESTART_ID:
		_reset_prototype()
		return
	var next_room := route_run.choose_next(room_id)
	if next_room == null:
		_show_route_choice()
		return
	_transition_to_room(next_room)

func _transition_to_room(next_profile: RouteRoomData) -> void:
	if _transitioning or next_profile == null or not _has_active_player():
		return
	_transitioning = true
	_room_clear_pending = false
	_clear_projectiles()
	var previous_room := room
	var carried_player := previous_room.player
	var next_room := TestCombatRoom.new()
	next_room.name = "RouteRoom%02d" % (next_profile.stage_index + 1)
	next_room.configure(next_profile, carried_player)
	add_child(next_room)
	_connect_room(next_room)
	room = next_room
	if is_instance_valid(camera):
		camera.setup(room.player, room.get_camera_limits())
		camera.make_current()
	if is_instance_valid(route_status):
		route_status.update_progress(route_run.get_progress_snapshot())
	if is_instance_valid(previous_room):
		previous_room.queue_free()
	_transitioning = false

func _clear_projectiles() -> void:
	for child in get_children():
		if child is CombatProjectile:
			child.queue_free()

func _find_equipped_part(slot: WeaponPartData.Slot) -> WeaponPartData:
	if not _has_active_player():
		return null
	for equipped_part in room.player.weapon.equipped_parts:
		if equipped_part != null and equipped_part.slot == slot:
			return equipped_part.duplicate_part()
	return null

func _duplicate_parts(parts: Array[WeaponPartData]) -> Array[WeaponPartData]:
	var result: Array[WeaponPartData] = []
	for part in parts:
		if part != null:
			result.append(part.duplicate_part())
	return result

func _has_active_player() -> bool:
	return is_instance_valid(room) and is_instance_valid(room.player) and room.player.weapon != null

func _reset_prototype() -> void:
	if _transitioning:
		return
	_transitioning = true
	if is_instance_valid(reward_panel):
		reward_panel.queue_free()
	if is_instance_valid(backpack_panel):
		backpack_panel.queue_free()
	if is_instance_valid(route_panel):
		route_panel.queue_free()
	if is_instance_valid(room):
		room.queue_free()
	if is_instance_valid(camera):
		camera.queue_free()
	if is_instance_valid(hud):
		hud.queue_free()
	if is_instance_valid(route_status):
		route_status.queue_free()
	if is_instance_valid(touch_layer):
		touch_layer.queue_free()
	await get_tree().process_frame
	GameState.reset_run()
	backpack = BackpackGrid.new()
	reward_panel = null
	backpack_panel = null
	route_panel = null
	room = null
	camera = null
	hud = null
	route_status = null
	touch_layer = null
	touch_controls = null
	_room_clear_pending = false
	_transitioning = false
	_build_prototype()
