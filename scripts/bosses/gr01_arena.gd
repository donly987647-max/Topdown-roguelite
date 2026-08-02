class_name GR01Arena
extends Node2D

@export var arena_center := Vector2(544, 352)
@export var base_half_size := Vector2(512, 320)

var boss: GR01Boss

@onready var left_wall: StaticBody2D = $CompressionWalls/Left
@onready var right_wall: StaticBody2D = $CompressionWalls/Right
@onready var top_wall: StaticBody2D = $CompressionWalls/Top
@onready var bottom_wall: StaticBody2D = $CompressionWalls/Bottom
@onready var conveyor: Polygon2D = $Conveyor
@onready var warning_layer: Node2D = $Warnings

var compression_factor := 1.0
var conveyor_direction := Vector2.RIGHT
var safe_zone_index := 0
var _phase_three_active := false
var _unsafe_damage_left := 0.5
var _press_left := 0.0
var _press_angular_speed := 0.0
var _press_visual: Line2D
var _banner: Label

func _ready() -> void:
	_create_phase_banner()

func on_enemy_spawned(enemy: Node, enemy_id: StringName) -> void:
	if enemy_id == &"gr01_proto" and enemy is GR01Boss:
		bind_boss(enemy as GR01Boss)

func bind_boss(value: GR01Boss) -> void:
	if value == null or boss == value:
		return
	boss = value
	boss.arena_compression_requested.connect(_on_compression_requested)
	boss.center_press_requested.connect(_on_center_press_requested)
	boss.conveyor_direction_changed.connect(_on_conveyor_direction_changed)
	boss.falling_block_warning.connect(_on_falling_block_warning)
	boss.safe_zone_changed.connect(_on_safe_zone_changed)
	boss.core_exposure_changed.connect(_on_core_exposure_changed)
	boss.phase_changed.connect(_on_phase_changed)
	boss.pattern_telegraph.connect_nodes(_on_pattern_telegraph)

func _physics_process(delta: float) -> void:
	if conveyor_direction != Vector2.ZERO:
		for body in $ConveyorArea.get_overlapping_bodies():
			if body is Player:
				body.velocity += conveyor_direction * 110.0 * delta * 60.0
	_update_center_press(delta)
	_update_phase_three_hazard(delta)

func _on_compression_requested(factor: float, duration: float) -> void:
	compression_factor = minf(compression_factor, clampf(factor, 0.55, 1.0))
	var half := base_half_size * compression_factor
	var tween := create_tween().set_parallel(true)
	tween.tween_property(left_wall, "position:x", arena_center.x - half.x, duration)
	tween.tween_property(right_wall, "position:x", arena_center.x + half.x, duration)
	tween.tween_property(top_wall, "position:y", arena_center.y - half.y, duration)
	tween.tween_property(bottom_wall, "position:y", arena_center.y + half.y, duration)

func _on_center_press_requested(duration: float, angular_speed: float) -> void:
	_press_left = maxf(_press_left, duration)
	_press_angular_speed = angular_speed
	if _press_visual == null or not is_instance_valid(_press_visual):
		_press_visual = Line2D.new()
		_press_visual.width = 18.0
		_press_visual.default_color = Color(0.95, 0.30, 0.12, 0.9)
		_press_visual.points = PackedVector2Array([Vector2(-145, 0), Vector2(145, 0)])
		_press_visual.position = arena_center
		warning_layer.add_child(_press_visual)
	_press_visual.visible = true

func _update_center_press(delta: float) -> void:
	if _press_left <= 0.0:
		if _press_visual != null:
			_press_visual.visible = false
		return
	_press_left = maxf(0.0, _press_left - delta)
	if _press_visual == null:
		return
	_press_visual.rotation += _press_angular_speed * delta
	for node in get_tree().get_nodes_in_group(&"player"):
		if not (node is Player):
			continue
		var player := node as Player
		var local := player.global_position - _press_visual.global_position
		var rotated := local.rotated(-_press_visual.global_rotation)
		if absf(rotated.y) <= 20.0 and absf(rotated.x) <= 155.0:
			player.take_damage(18.0, _press_visual.global_position.direction_to(player.global_position) * 220.0)

func _on_conveyor_direction_changed(direction: Vector2) -> void:
	conveyor_direction = direction.normalized()
	conveyor.rotation = conveyor_direction.angle()

func _on_falling_block_warning(world_position: Vector2, delay: float) -> void:
	var warning := Polygon2D.new()
	warning.polygon = PackedVector2Array([Vector2(-26,-26),Vector2(26,-26),Vector2(26,26),Vector2(-26,26)])
	warning.color = Color(1.0,0.18,0.08,0.35)
	warning.global_position = world_position
	warning_layer.add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate:a", 1.0, maxf(0.05, delay))
	tween.tween_callback(func(): _drop_block(warning))

func _drop_block(warning: Polygon2D) -> void:
	if warning == null or not is_instance_valid(warning):
		return
	var area := Area2D.new()
	area.global_position = warning.global_position
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(52,52)
	shape.shape = rect
	area.add_child(shape)
	warning_layer.add_child(area)
	for body in get_tree().get_nodes_in_group(&"player"):
		if body is Player and (body as Player).global_position.distance_to(area.global_position) < 48.0:
			(body as Player).take_damage(24.0, area.global_position.direction_to((body as Player).global_position) * 280.0)
	warning.color = Color(0.32,0.29,0.26,0.9)
	get_tree().create_timer(1.2).timeout.connect(func():
		if is_instance_valid(area): area.queue_free()
		if is_instance_valid(warning): warning.queue_free())

func _on_safe_zone_changed(index: int) -> void:
	safe_zone_index = index
	for i in range(4):
		var zone := get_node_or_null("SafeZones/Zone%d" % i) as Polygon2D
		if zone != null:
			zone.visible = i == safe_zone_index
	_unsafe_damage_left = 0.45

func _update_phase_three_hazard(delta: float) -> void:
	if not _phase_three_active:
		return
	_unsafe_damage_left -= delta
	if _unsafe_damage_left > 0.0:
		return
	_unsafe_damage_left = 0.55
	var safe_zone := get_node_or_null("SafeZones/Zone%d" % safe_zone_index) as Polygon2D
	if safe_zone == null:
		return
	for node in get_tree().get_nodes_in_group(&"player"):
		if node is Player and not _point_inside_polygon((node as Player).global_position, safe_zone):
			(node as Player).take_damage(8.0, Vector2.ZERO)

func _point_inside_polygon(world_point: Vector2, polygon_node: Polygon2D) -> bool:
	var local := polygon_node.to_local(world_point)
	return Geometry2D.is_point_in_polygon(local, polygon_node.polygon)

func _on_core_exposure_changed(exposed: bool) -> void:
	if boss != null and boss.has_node("Core"):
		var core := boss.get_node("Core") as CanvasItem
		core.modulate = Color(1.0,0.95,0.35,1.0) if exposed else Color.WHITE
	if exposed:
		_show_banner("CORE EXPOSED", 0.7)

func _on_phase_changed(phase: int) -> void:
	_phase_three_active = phase >= 3
	_show_banner("GR-01 · PHASE %d" % phase, 1.1)

func _on_pattern_telegraph(pattern_id: StringName, duration: float) -> void:
	var text := String(pattern_id).replace("_", " ").capitalize()
	_show_banner(text, duration)

func _create_phase_banner() -> void:
	_banner = Label.new()
	_banner.position = Vector2(arena_center.x - 210.0, 54.0)
	_banner.size = Vector2(420.0, 50.0)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 24)
	_banner.visible = false
	add_child(_banner)

func _show_banner(text: String, duration: float) -> void:
	if _banner == null:
		return
	_banner.text = text
	_banner.modulate = Color.WHITE
	_banner.visible = true
	var tween := _banner.create_tween()
	tween.tween_interval(maxf(0.15, duration))
	tween.tween_property(_banner, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		if is_instance_valid(_banner): _banner.visible = false)
