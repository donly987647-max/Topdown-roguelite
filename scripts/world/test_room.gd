class_name TestCombatRoom
extends Node2D

signal reward_requested(options: Array)
signal room_cleared(room_snapshot: Dictionary)

const ROOM_RECT := Rect2(Vector2(-320.0, -192.0), Vector2(640.0, 384.0))
const SAFE_RECT := Rect2(Vector2(-294.0, -166.0), Vector2(588.0, 332.0))
const PLAYER_SPAWN := Vector2(-220.0, 0.0)
const ENEMY_SPAWNS := [
	Vector2(170.0, -95.0), Vector2(215.0, 80.0), Vector2(75.0, 125.0),
	Vector2(70.0, -130.0), Vector2(245.0, -20.0), Vector2(145.0, 130.0)
]
const OBSTACLES := [
	Rect2(Vector2(-38.0, -72.0), Vector2(76.0, 144.0)),
	Rect2(Vector2(105.0, -18.0), Vector2(64.0, 36.0))
]
const HAZARD_A := Rect2(Vector2(-150.0, 82.0), Vector2(70.0, 62.0))
const HAZARD_B := Rect2(Vector2(178.0, -150.0), Vector2(72.0, 58.0))

var player: PlayerController
var route_room: RouteRoomData
var carried_player: PlayerController
var _reward_offered := false
var _room_clear_emitted := false
var _last_enemy_count := -1
var _active_hazards: Array[Rect2] = []

func configure(profile: RouteRoomData, existing_player: PlayerController = null) -> void:
	route_room = profile.duplicate_room() if profile != null else null
	carried_player = existing_player

func _ready() -> void:
	if route_room == null:
		route_room = _default_route_room()
	add_to_group("room_controller")
	_build_walls()
	for rect in OBSTACLES:
		_build_static_rect(rect, Color("27343a"))
	_configure_hazards()
	_spawn_player()
	_spawn_enemies()
	queue_redraw()

func _spawn_player() -> void:
	if is_instance_valid(carried_player):
		player = carried_player
		if player.get_parent() != self:
			player.reparent(self, true)
		player.global_position = PLAYER_SPAWN
		player.velocity = Vector2.ZERO
		player.room_controller = self
		player.set_physics_process(true)
		return
	player = PlayerController.new()
	player.name = "Player"
	player.global_position = PLAYER_SPAWN
	player.room_controller = self
	add_child(player)

func _spawn_enemies() -> void:
	var count := clampi(route_room.enemy_count, 1, ENEMY_SPAWNS.size())
	for index in range(count):
		var enemy := TrainingGunner.new()
		enemy.name = "TrainingGunner%02d" % index
		enemy.spawn_index = index
		enemy.global_position = ENEMY_SPAWNS[index]
		enemy.health_multiplier = route_room.enemy_health_multiplier
		enemy.damage_multiplier = route_room.enemy_damage_multiplier
		if route_room.room_type == RouteRoomData.RoomType.ELITE:
			enemy.elite_rank = 1 if index < 2 else 0
		elif route_room.room_type == RouteRoomData.RoomType.BOSS_GATE:
			enemy.elite_rank = 2 if index == 0 else 1 if index < 3 else 0
		add_child(enemy)
	_update_enemy_count.call_deferred()

func _process(_delta: float) -> void:
	_update_enemy_count()

func _update_enemy_count() -> void:
	var count := _active_enemy_count()
	if count != _last_enemy_count:
		_last_enemy_count = count
		_emit_event(&"enemy_count_changed", [count])
	if count == 0 and not _room_clear_emitted and is_instance_valid(player):
		_room_clear_emitted = true
		room_cleared.emit(route_room.get_snapshot())
	if count == 0 and not _reward_offered and is_instance_valid(player):
		_reward_offered = true
		_offer_reward.call_deferred()

func _active_enemy_count() -> int:
	var count := 0
	for child in get_children():
		if child.is_in_group("enemy") and not child.is_queued_for_deletion():
			count += 1
	return count

func can_open_inventory() -> bool:
	return _reward_offered and _active_enemy_count() == 0

func _offer_reward() -> void:
	if not is_instance_valid(player) or player.weapon == null:
		return
	var excluded := WeaponPartRewardPicker.equipped_ids(player.weapon.equipped_parts)
	var options := WeaponPartRewardPicker.roll_options(3, excluded)
	if options.size() < 3:
		options = WeaponPartRewardPicker.roll_options(3)
	reward_requested.emit(options)

func get_route_snapshot() -> Dictionary:
	return route_room.get_snapshot() if route_room != null else {}

func correct_dash_direction(start: Vector2, desired_direction: Vector2, distance: float) -> Vector2:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and bool(game_state.get("high_difficulty_hazard_correction_disabled")):
		return desired_direction.normalized()
	var desired_end := start + desired_direction.normalized() * distance
	var safe_end := Vector2(
		clampf(desired_end.x, SAFE_RECT.position.x, SAFE_RECT.end.x),
		clampf(desired_end.y, SAFE_RECT.position.y, SAFE_RECT.end.y)
	)
	for hazard in _active_hazards:
		if hazard.grow(14.0).has_point(safe_end):
			safe_end = start
	for obstacle in OBSTACLES:
		if obstacle.grow(16.0).has_point(safe_end):
			safe_end = start
	var corrected := safe_end - start
	return corrected.normalized() if corrected.length_squared() > 1.0 else desired_direction.normalized()

func get_camera_limits() -> Rect2:
	return ROOM_RECT

func _configure_hazards() -> void:
	_active_hazards.clear()
	if route_room.hazard_level >= 1:
		_active_hazards.append(HAZARD_A)
	if route_room.hazard_level >= 2:
		_active_hazards.append(HAZARD_B)

func _build_walls() -> void:
	_build_static_rect(Rect2(Vector2(-336, -208), Vector2(672, 16)), Color("40535d"))
	_build_static_rect(Rect2(Vector2(-336, 192), Vector2(672, 16)), Color("40535d"))
	_build_static_rect(Rect2(Vector2(-336, -192), Vector2(16, 384)), Color("40535d"))
	_build_static_rect(Rect2(Vector2(320, -192), Vector2(16, 384)), Color("40535d"))

func _build_static_rect(rect: Rect2, _color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = GameConstants.LAYER_WORLD
	body.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func _default_route_room() -> RouteRoomData:
	var data := RouteRoomData.new()
	data.room_id = &"test_room"
	data.stage_index = 0
	data.display_name = "TEST ROOM"
	data.description = "Standalone combat test room."
	data.enemy_count = 3
	return data

func _emit_event(signal_name: StringName, arguments: Array = []) -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal(signal_name):
		var call_arguments: Array = [signal_name]
		call_arguments.append_array(arguments)
		event_bus.callv("emit_signal", call_arguments)

func _draw() -> void:
	var room_tint := Color("0b1014")
	if route_room != null and route_room.is_dangerous():
		room_tint = Color("120c12")
	draw_rect(ROOM_RECT, room_tint, true)
	for x in range(int(ROOM_RECT.position.x), int(ROOM_RECT.end.x) + 1, GameConstants.TILE_SIZE):
		draw_line(Vector2(x, ROOM_RECT.position.y), Vector2(x, ROOM_RECT.end.y), Color(0.2, 0.3, 0.34, 0.17), 1.0)
	for y in range(int(ROOM_RECT.position.y), int(ROOM_RECT.end.y) + 1, GameConstants.TILE_SIZE):
		draw_line(Vector2(ROOM_RECT.position.x, y), Vector2(ROOM_RECT.end.x, y), Color(0.2, 0.3, 0.34, 0.17), 1.0)
	draw_rect(ROOM_RECT, Color("40535d"), false, 5.0)
	for obstacle in OBSTACLES:
		draw_rect(obstacle, Color("27343a"), true)
		draw_rect(obstacle, Color("607783"), false, 2.0)
	for hazard in _active_hazards:
		draw_rect(hazard, Color("260d16"), true)
		draw_rect(hazard, Color("ff536d"), false, 2.0)
		for offset in range(-40, 90, 18):
			draw_line(hazard.position + Vector2(offset, 0), hazard.position + Vector2(offset + 62, hazard.size.y), Color(1.0, 0.32, 0.42, 0.35), 2.0)
	draw_rect(Rect2(Vector2(-320, -35), Vector2(12, 70)), Color("69e79a"), true)
	draw_rect(Rect2(Vector2(308, -35), Vector2(12, 70)), Color("ffbd55"), true)
