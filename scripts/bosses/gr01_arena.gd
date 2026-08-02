class_name GR01Arena
extends Node2D

@export var boss_path: NodePath = NodePath("GR01Boss")
@export var arena_center := Vector2(1088, 704)
@export var base_half_size := Vector2(960, 576)

@onready var boss: GR01Boss = get_node_or_null(boss_path) as GR01Boss
@onready var left_wall: StaticBody2D = $CompressionWalls/Left
@onready var right_wall: StaticBody2D = $CompressionWalls/Right
@onready var top_wall: StaticBody2D = $CompressionWalls/Top
@onready var bottom_wall: StaticBody2D = $CompressionWalls/Bottom
@onready var conveyor: Polygon2D = $Conveyor
@onready var warning_layer: Node2D = $Warnings

var compression_factor := 1.0
var conveyor_direction := Vector2.RIGHT
var safe_zone_index := 0

func _ready() -> void:
	if boss == null:
		return
	boss.arena_compression_requested.connect(_on_compression_requested)
	boss.conveyor_direction_changed.connect(_on_conveyor_direction_changed)
	boss.falling_block_warning.connect(_on_falling_block_warning)
	boss.safe_zone_changed.connect(_on_safe_zone_changed)
	boss.core_exposure_changed.connect(_on_core_exposure_changed)

func _physics_process(delta: float) -> void:
	if conveyor_direction == Vector2.ZERO:
		return
	for body in $ConveyorArea.get_overlapping_bodies():
		if body is Player:
			body.velocity += conveyor_direction * 110.0 * delta * 60.0

func _on_compression_requested(factor: float, duration: float) -> void:
	compression_factor = minf(compression_factor, clampf(factor, 0.55, 1.0))
	var half := base_half_size * compression_factor
	var tween := create_tween().set_parallel(true)
	tween.tween_property(left_wall, "position:x", arena_center.x - half.x, duration)
	tween.tween_property(right_wall, "position:x", arena_center.x + half.x, duration)
	tween.tween_property(top_wall, "position:y", arena_center.y - half.y, duration)
	tween.tween_property(bottom_wall, "position:y", arena_center.y + half.y, duration)

func _on_conveyor_direction_changed(direction: Vector2) -> void:
	conveyor_direction = direction.normalized()
	conveyor.rotation = conveyor_direction.angle()

func _on_falling_block_warning(world_position: Vector2, delay: float) -> void:
	var warning := Polygon2D.new()
	warning.polygon = PackedVector2Array([Vector2(-36,-36),Vector2(36,-36),Vector2(36,36),Vector2(-36,36)])
	warning.color = Color(1.0,0.18,0.08,0.35)
	warning.global_position = world_position
	warning_layer.add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate:a", 1.0, maxf(0.05, delay))
	tween.tween_callback(func(): _drop_block(warning))

func _drop_block(warning: Polygon2D) -> void:
	if warning == null or not is_instance_valid(warning): return
	var area := Area2D.new()
	area.global_position = warning.global_position
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new(); rect.size = Vector2(72,72); shape.shape = rect
	area.add_child(shape)
	warning_layer.add_child(area)
	for body in get_tree().get_nodes_in_group(&"player"):
		if body is Player and (body as Player).global_position.distance_to(area.global_position) < 62.0:
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

func _on_core_exposure_changed(exposed: bool) -> void:
	if boss != null and boss.has_node("Core"):
		var core := boss.get_node("Core") as CanvasItem
		core.modulate = Color(1.0,0.95,0.35,1.0) if exposed else Color.WHITE
