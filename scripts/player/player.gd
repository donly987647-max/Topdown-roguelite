class_name Player
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal guard_changed(current: int, maximum: int)
signal temporary_shield_changed(current: float, maximum: float)
signal damaged(amount: float)
signal died

@export_category("Movement")
@export var max_speed: float = 260.0
@export var acceleration: float = 3250.0
@export var deceleration: float = 4300.0

@export_category("Dash")
@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.55
@export var dash_invulnerability: float = 0.18

@export_category("Health")
@export var max_health: float = 100.0
@export var max_guard: int = 3
@export var max_temporary_shield: float = 50.0
@export var temporary_shield_duration: float = 6.0

var health: float
var guard: int = 0
var temporary_shield := 0.0
var aim_direction := Vector2.RIGHT
var input_enabled := true
var _last_move_direction := Vector2.RIGHT
var _dash_direction := Vector2.ZERO
var _dash_time_left := 0.0
var _dash_cooldown_left := 0.0
var _invulnerability_left := 0.0
var _temporary_shield_left := 0.0
var _dead := false
var _mobile_move := Vector2.ZERO
var _mobile_aim := Vector2.ZERO
var _mobile_aim_active := false

@onready var body_visual: Polygon2D = $BodyVisual
@onready var aim_pivot: Node2D = $AimPivot

func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	guard_changed.emit(guard, max_guard)
	temporary_shield_changed.emit(temporary_shield, max_temporary_shield)
	MagazineRuntime.attach_to_player(self)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	if input_enabled:
		_update_aim()
	if _dead or not input_enabled:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		move_and_slide()
		return
	var keyboard_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_direction := _mobile_move if _mobile_move.length_squared() > 0.0001 else keyboard_direction
	if input_direction.length_squared() > 1.0:
		input_direction = input_direction.normalized()
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
	if _mobile_aim_active and _mobile_aim.length_squared() > 0.0001:
		aim_direction = _mobile_aim.normalized()
	else:
		var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down") if InputMap.has_action("aim_left") else Vector2.ZERO
		if stick.length_squared() > 0.04:
			aim_direction = stick.normalized()
		else:
			var mouse_vector := get_global_mouse_position() - global_position
			if mouse_vector.length_squared() > 1.0:
				aim_direction = mouse_vector.normalized()
	aim_pivot.rotation = aim_direction.angle()

func set_input_enabled(value: bool) -> void:
	input_enabled = value
	if not value:
		_mobile_move = Vector2.ZERO
		_mobile_aim = Vector2.ZERO
		_mobile_aim_active = false

func set_mobile_move(value: Vector2) -> void:
	_mobile_move = value.limit_length(1.0)

func set_mobile_aim(value: Vector2, active: bool = true) -> void:
	_mobile_aim = value.limit_length(1.0)
	_mobile_aim_active = active

func clear_mobile_aim() -> void:
	_mobile_aim = Vector2.ZERO
	_mobile_aim_active = false

func set_guard(value: int) -> void:
	guard = clampi(value, 0, max_guard)
	guard_changed.emit(guard, max_guard)

func add_guard(amount: int = 1) -> int:
	if amount <= 0 or _dead:
		return 0
	var before := guard
	guard = clampi(guard + amount, 0, max_guard)
	guard_changed.emit(guard, max_guard)
	return guard - before

func heal(amount: float) -> float:
	if amount <= 0.0 or _dead:
		return 0.0
	var multiplier := float(get_meta("healing_multiplier", 1.0))
	var before := health
	health = minf(max_health, health + amount * multiplier)
	if health != before:
		health_changed.emit(health, max_health)
	return health - before

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
	if temporary_shield > 0.0:
		_temporary_shield_left = maxf(0.0, _temporary_shield_left - delta)
		if _temporary_shield_left <= 0.0:
			temporary_shield = 0.0
			temporary_shield_changed.emit(temporary_shield, max_temporary_shield)

func add_temporary_shield(amount: float) -> float:
	if amount <= 0.0 or _dead:
		return 0.0
	var before := temporary_shield
	temporary_shield = minf(max_temporary_shield, temporary_shield + amount)
	var gained := temporary_shield - before
	if gained > 0.0:
		_temporary_shield_left = temporary_shield_duration
		temporary_shield_changed.emit(temporary_shield, max_temporary_shield)
	return gained

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> bool:
	if _dead or _invulnerability_left > 0.0 or amount <= 0.0:
		return false
	var remaining := amount
	if temporary_shield > 0.0:
		var absorbed := minf(temporary_shield, remaining)
		temporary_shield -= absorbed
		remaining -= absorbed
		temporary_shield_changed.emit(temporary_shield, max_temporary_shield)
	if remaining > 0.0 and guard > 0:
		guard -= 1
		guard_changed.emit(guard, max_guard)
		remaining = 0.0
	if remaining > 0.0:
		health = maxf(0.0, health - remaining)
		health_changed.emit(health, max_health)
	velocity += knockback
	_invulnerability_left = 0.35
	damaged.emit(amount)
	body_visual.modulate = Color(1.0, 0.35, 0.35, 1.0)
	get_tree().create_timer(0.09).timeout.connect(_restore_visual)
	if health <= 0.0:
		_die()
	return true

func _restore_visual() -> void:
	if is_instance_valid(body_visual) and not _dead:
		body_visual.modulate = Color.WHITE

func is_invulnerable() -> bool:
	return _invulnerability_left > 0.0

func is_dead() -> bool:
	return _dead

func dash_cooldown_remaining() -> float:
	return _dash_cooldown_left

func invulnerability_remaining() -> float:
	return _invulnerability_left

func mobile_input_active() -> bool:
	return _mobile_move.length_squared() > 0.0001 or _mobile_aim_active

func _die() -> void:
	if _dead:
		return
	_dead = true
	body_visual.modulate = Color(0.45, 0.45, 0.45, 1.0)
	died.emit()
