class_name GR01Boss
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal phase_changed(phase: int)
signal pattern_telegraph(pattern_id: StringName, duration: float)
signal arena_compression_requested(factor: float, duration: float)
signal center_press_requested(duration: float, angular_speed: float)
signal conveyor_direction_changed(direction: Vector2)
signal falling_block_warning(position: Vector2, delay: float)
signal safe_zone_changed(index: int)
signal core_exposure_changed(exposed: bool)
signal defeated

@export var max_health := 1800.0
@export var projectile_scene: PackedScene
@export var minion_scene: PackedScene
@export var arena_radius := 480.0
@export var projectile_damage := 16.0
@export var max_active_minions := 4

var health := 1800.0
var phase := 1
var core_exposed := false
var _attack_timer := 1.2
var _pattern_index := 0
var _core_timer := 0.0
var _safe_zone_index := 0
var _dead := false
var _active_minions: Array[Node] = []

@onready var health_bar: ProgressBar = get_node_or_null("HealthBar") as ProgressBar
@onready var core_visual: CanvasItem = get_node_or_null("Core") as CanvasItem

func _ready() -> void:
	add_to_group(&"enemy")
	add_to_group(&"boss")
	health = max_health
	_update_health_bar()
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_attack_timer -= delta
	if _core_timer > 0.0:
		_core_timer -= delta
		if _core_timer <= 0.0 and core_exposed:
			_set_core_exposed(false)
	if _attack_timer <= 0.0:
		_execute_pattern()

func take_damage(amount: float, _knockback: Vector2 = Vector2.ZERO) -> bool:
	if _dead or amount <= 0.0:
		return false
	var multiplier := 1.75 if phase == 3 and core_exposed else 1.0
	health = maxf(0.0, health - amount * multiplier)
	_update_health_bar()
	health_changed.emit(health, max_health)
	_update_phase()
	if health <= 0.0:
		_die()
	return true

func _update_health_bar() -> void:
	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = health

func _update_phase() -> void:
	var ratio := health / maxf(1.0, max_health)
	var target := 3 if ratio <= 0.25 else 2 if ratio <= 0.60 else 1
	if target == phase:
		return
	phase = target
	phase_changed.emit(phase)
	if phase == 2:
		pattern_telegraph.emit(&"phase_2_area_reduction", 1.2)
		arena_compression_requested.emit(0.82, 1.4)
		_attack_timer = maxf(_attack_timer, 1.0)
	elif phase == 3:
		pattern_telegraph.emit(&"phase_3_safe_zone", 1.0)
		arena_compression_requested.emit(0.68, 1.0)
		_safe_zone_index = 0
		safe_zone_changed.emit(_safe_zone_index)
		_set_core_exposed(true, 2.2)
		_attack_timer = maxf(_attack_timer, 0.9)

func _execute_pattern() -> void:
	_pattern_index += 1
	match phase:
		1:
			match _pattern_index % 4:
				0: _wall_compress_pulse()
				1: _fire_metal_shards(7, 0.20, 560.0)
				2: _change_conveyor()
				_: _warn_falling_blocks(3)
			_attack_timer = 1.45
		2:
			match _pattern_index % 4:
				0: _activate_center_press()
				1: _fire_tracking_saws(4)
				2: _spawn_minions(2)
				_: _fire_metal_shards(9, 0.16, 620.0)
			_attack_timer = 1.05
		3:
			_safe_zone_index = (_safe_zone_index + 1) % 4
			safe_zone_changed.emit(_safe_zone_index)
			if _pattern_index % 3 == 0:
				pattern_telegraph.emit(&"core_exposure", 0.45)
				_set_core_exposed(true, 1.65)
			elif _pattern_index % 3 == 1:
				_fire_tracking_saws(6)
			else:
				_fire_metal_shards(12, 0.12, 700.0)
			_attack_timer = 0.72

func _wall_compress_pulse() -> void:
	pattern_telegraph.emit(&"wall_compression", 0.55)
	arena_compression_requested.emit(0.92, 0.8)

func _change_conveyor() -> void:
	var directions := [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	var next_direction: Vector2 = directions[_pattern_index % directions.size()]
	pattern_telegraph.emit(&"conveyor_change", 0.35)
	conveyor_direction_changed.emit(next_direction)

func _warn_falling_blocks(count: int) -> void:
	pattern_telegraph.emit(&"falling_blocks", 0.65)
	for i in range(count):
		var angle := TAU * float(i) / float(maxi(1, count)) + randf_range(-0.35, 0.35)
		var pos := global_position + Vector2.RIGHT.rotated(angle) * randf_range(120.0, arena_radius * 0.75)
		falling_block_warning.emit(pos, 0.75 + i * 0.12)

func _activate_center_press() -> void:
	pattern_telegraph.emit(&"center_press", 0.7)
	center_press_requested.emit(2.5, 2.8)
	falling_block_warning.emit(global_position, 0.65)
	arena_compression_requested.emit(0.78, 0.6)

func _fire_metal_shards(count: int, arc_fraction: float, speed: float) -> void:
	pattern_telegraph.emit(&"metal_shards", 0.25)
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	var base := global_position.direction_to(player.global_position) if player != null else Vector2.RIGHT
	for i in range(count):
		var t := 0.5 if count <= 1 else float(i) / float(count - 1)
		var angle := lerpf(-PI * arc_fraction, PI * arc_fraction, t)
		_spawn_projectile(base.rotated(angle), speed, projectile_damage, false)

func _fire_tracking_saws(count: int) -> void:
	pattern_telegraph.emit(&"tracking_saws", 0.4)
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	var base := global_position.direction_to(player.global_position) if player != null else Vector2.RIGHT
	for i in range(count):
		var angle := deg_to_rad((float(i) - float(count - 1) * 0.5) * 8.0)
		_spawn_projectile(base.rotated(angle), 430.0, projectile_damage * 1.15, true)

func _spawn_projectile(direction: Vector2, projectile_speed: float, projectile_damage_value: float, homing: bool) -> void:
	if projectile_scene == null:
		return
	var projectile := projectile_scene.instantiate()
	if projectile == null:
		return
	get_tree().current_scene.add_child(projectile)
	if projectile is Node2D:
		(projectile as Node2D).global_position = global_position
	if projectile.has_method("configure"):
		projectile.call("configure", direction.normalized(), projectile_damage_value, projectile_speed)
	if homing and _has_property(projectile, &"homing_strength"):
		projectile.set("homing_strength", 2.2)

func _spawn_minions(count: int) -> void:
	if minion_scene == null:
		return
	_active_minions = _active_minions.filter(func(node): return is_instance_valid(node) and not node.is_queued_for_deletion())
	var allowed := maxi(0, max_active_minions - _active_minions.size())
	for i in range(mini(count, allowed)):
		var minion := minion_scene.instantiate()
		if minion == null:
			continue
		get_parent().add_child(minion)
		_active_minions.append(minion)
		if minion is Node2D:
			(minion as Node2D).global_position = global_position + Vector2.RIGHT.rotated(TAU * i / maxf(1.0, count)) * 150.0

func _set_core_exposed(value: bool, duration: float = 0.0) -> void:
	core_exposed = value
	_core_timer = duration if value else 0.0
	if core_visual != null:
		core_visual.modulate = Color(1.0,0.95,0.35,1.0) if value else Color.WHITE
	core_exposure_changed.emit(value)

func _has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false

func _die() -> void:
	if _dead:
		return
	_dead = true
	collision_layer = 0
	collision_mask = 0
	defeated.emit()
	queue_free()
