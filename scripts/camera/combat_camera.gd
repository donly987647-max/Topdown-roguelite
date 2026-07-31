class_name CombatCamera
extends Camera2D

const AIM_LEAD_MAX := 80.0
const FOLLOW_SPEED := 10.0
const SHAKE_MAX := 18.0

var target: PlayerController
var room_bounds := Rect2(Vector2(-320, -192), Vector2(640, 384))
var shake_strength := 0.0
var shake_setting := 1.0

func _ready() -> void:
	position_smoothing_enabled = false
	EventBus.screen_shake.connect(_on_screen_shake)

func setup(player_target: PlayerController, bounds: Rect2) -> void:
	target = player_target
	room_bounds = bounds
	global_position = target.global_position

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var desired := target.global_position + target.aim_direction * AIM_LEAD_MAX
	var half_view := get_viewport_rect().size * 0.5
	var min_position := room_bounds.position + half_view
	var max_position := room_bounds.end - half_view
	if min_position.x <= max_position.x:
		desired.x = clampf(desired.x, min_position.x, max_position.x)
	else:
		desired.x = room_bounds.get_center().x
	if min_position.y <= max_position.y:
		desired.y = clampf(desired.y, min_position.y, max_position.y)
	else:
		desired.y = room_bounds.get_center().y
	global_position = global_position.lerp(desired, 1.0 - exp(-FOLLOW_SPEED * delta))
	shake_strength = move_toward(shake_strength, 0.0, 25.0 * delta)
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * shake_setting

func _on_screen_shake(strength: float, source_position: Vector2) -> void:
	if target == null:
		return
	var distance_factor := 1.0 - clampf(target.global_position.distance_to(source_position) / 700.0, 0.0, 0.85)
	shake_strength = minf(SHAKE_MAX, shake_strength + strength * 6.0 * distance_factor)
