class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var max_speed: float = 360.0
@export var acceleration: float = 2400.0
@export var deceleration: float = 3000.0

@export_category("Dash")
@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.55
@export var dash_invulnerability: float = 0.18

@export_category("Health")
@export var max_health: float = 100.0

var health: float
var aim_direction := Vector2.RIGHT
var _last_move_direction := Vector2.RIGHT
var _dash_direction := Vector2.ZERO
var _dash_time_left := 0.0
var _dash_cooldown_left := 0.0
var _invulnerability_left := 0.0
var _dead := false

@onready var body_visual: Polygon2D = $BodyVisual
@onready var aim_pivot: Node2D = $AimPivot

func _ready() -> void:
	health = max_health

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_aim()

	if _dead:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		move_and_slide()
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction.length_squared() > 0.0:
		_last_move_direction = input_direction.normalized()

	if Input.is_action_just_pressed("dash"):
		_try_start_dash(input_direction)

	if _dash_time_left > 0.0:
		velocity = _dash_direction * dash_speed
	else:
		var target_velocity := input_direction * max_speed
		var rate := acceleration if input_direction.length_squared() > 0.0 else deceleration
		velocity = velocity.move_toward(target_velocity, rate * delta)

	move_and_slide()

func _update_aim() -> void:
	var mouse_vector := get_global_mouse_position() - global_position
	if mouse_vector.length_squared() > 1.0:
		aim_direction = mouse_vector.normalized()
		aim_pivot.rotation = aim_direction.angle()

func _try_start_dash(input_direction: Vector2) -> void:
	if _dash_cooldown_left > 0.0 or _dash_time_left > 0.0:
		return

	_dash_direction = input_direction.normalized() if input_direction.length_squared() > 0.0 else _last_move_direction
	if _dash_direction == Vector2.ZERO:
		_dash_direction = aim_direction

	_dash_time_left = dash_duration
	_dash_cooldown_left = dash_cooldown
	_invulnerability_left = maxf(_invulnerability_left, dash_invulnerability)

func _update_timers(delta: float) -> void:
	_dash_time_left = maxf(0.0, _dash_time_left - delta)
	_dash_cooldown_left = maxf(0.0, _dash_cooldown_left - delta)
	_invulnerability_left = maxf(0.0, _invulnerability_left - delta)

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> bool:
	if _dead or _invulnerability_left > 0.0 or amount <= 0.0:
		return false

	health = maxf(0.0, health - amount)
	velocity += knockback
	_invulnerability_left = 0.35

	if health <= 0.0:
		_die()
	return true

func is_invulnerable() -> bool:
	return _invulnerability_left > 0.0

func _die() -> void:
	_dead = true
	body_visual.modulate = Color(0.45, 0.45, 0.45, 1.0)
