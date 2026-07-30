class_name TestCombatRoom
extends Node2D

const ROOM_RECT := Rect2(Vector2(-320.0, -192.0), Vector2(640.0, 384.0))
const SAFE_RECT := Rect2(Vector2(-294.0, -166.0), Vector2(588.0, 332.0))
const PLAYER_SPAWN := Vector2(-220.0, 0.0)
const ENEMY_SPAWNS := [Vector2(170.0, -95.0), Vector2(215.0, 80.0), Vector2(75.0, 125.0)]
const OBSTACLES := [Rect2(Vector2(-38.0, -72.0), Vector2(76.0, 144.0)), Rect2(Vector2(105.0, -18.0), Vector2(64.0, 36.0))]
const HAZARDS := [Rect2(Vector2(-150.0, 82.0), Vector2(70.0, 62.0))]

var player: PlayerController

func _ready() -> void:
	add_to_group("room_controller")
	_build_walls()
	for rect in OBSTACLES:
		_build_static_rect(rect, Color("27343a"))
	_spawn_player()
	_spawn_enemies()
	queue_redraw()

func _spawn_player() -> void:
	player = PlayerController.new()
	player.name = "Player"
	player.global_position = PLAYER_SPAWN
	player.room_controller = self
	add_child(player)

func _spawn_enemies() -> void:
	for index in range(ENEMY_SPAWNS.size()):
		var enemy := TrainingGunner.new()
		enemy.name = "TrainingGunner%02d" % index
		enemy.spawn_index = index
		enemy.global_position = ENEMY_SPAWNS[index]
		add_child(enemy)
	_update_enemy_count.call_deferred()

func _process(_delta: float) -> void:
	_update_enemy_count()

func _update_enemy_count() -> void:
	EventBus.enemy_count_changed.emit(get_tree().get_nodes_in_group("enemy").size())

func correct_dash_direction(start: Vector2, desired_direction: Vector2, distance: float) -> Vector2:
	if GameState.high_difficulty_hazard_correction_disabled:
		return desired_direction.normalized()
	var desired_end := start + desired_direction.normalized() * distance
	var safe_end := Vector2(
		clampf(desired_end.x, SAFE_RECT.position.x, SAFE_RECT.end.x),
		clampf(desired_end.y, SAFE_RECT.position.y, SAFE_RECT.end.y)
	)
	for hazard in HAZARDS:
		if hazard.grow(14.0).has_point(safe_end):
			safe_end = start
	for obstacle in OBSTACLES:
		if obstacle.grow(16.0).has_point(safe_end):
			safe_end = start
	var corrected := safe_end - start
	return corrected.normalized() if corrected.length_squared() > 1.0 else desired_direction.normalized()

func get_camera_limits() -> Rect2:
	return ROOM_RECT

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

func _draw() -> void:
	draw_rect(ROOM_RECT, Color("0b1014"), true)
	for x in range(int(ROOM_RECT.position.x), int(ROOM_RECT.end.x) + 1, GameConstants.TILE_SIZE):
		draw_line(Vector2(x, ROOM_RECT.position.y), Vector2(x, ROOM_RECT.end.y), Color(0.2, 0.3, 0.34, 0.17), 1.0)
	for y in range(int(ROOM_RECT.position.y), int(ROOM_RECT.end.y) + 1, GameConstants.TILE_SIZE):
		draw_line(Vector2(ROOM_RECT.position.x, y), Vector2(ROOM_RECT.end.x, y), Color(0.2, 0.3, 0.34, 0.17), 1.0)
	draw_rect(ROOM_RECT, Color("40535d"), false, 5.0)
	for obstacle in OBSTACLES:
		draw_rect(obstacle, Color("27343a"), true)
		draw_rect(obstacle, Color("607783"), false, 2.0)
	for hazard in HAZARDS:
		draw_rect(hazard, Color("260d16"), true)
		draw_rect(hazard, Color("ff536d"), false, 2.0)
		for offset in range(-40, 90, 18):
			draw_line(hazard.position + Vector2(offset, 0), hazard.position + Vector2(offset + 62, hazard.size.y), Color(1.0, 0.32, 0.42, 0.35), 2.0)
	# Entrance and exit markers.
	draw_rect(Rect2(Vector2(-320, -35), Vector2(12, 70)), Color("69e79a"), true)
	draw_rect(Rect2(Vector2(308, -35), Vector2(12, 70)), Color("ffbd55"), true)
