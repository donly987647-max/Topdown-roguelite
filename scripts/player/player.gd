extends CharacterBody2D

const WeaponControllerScript = preload("res://scripts/combat/weapon_controller.gd")

const MOVE_SPEED := 260.0
const ACCEL_TIME := 0.08
const DECEL_TIME := 0.06
const MAX_HP := 100.0
const HIT_INVULN := 0.75
const DODGE_DURATION := 0.52
const DODGE_DISTANCE := 150.0
const DODGE_IFRAME_START := 0.12
const DODGE_IFRAME_END := 0.34
const DODGE_COOLDOWN := 0.35

var hp := MAX_HP
var aim_direction := Vector2.RIGHT
var weapon: Node
var invulnerable := false
var hit_invuln_left := 0.0
var dodge_active := false
var dodge_elapsed := 0.0
var dodge_cooldown_left := 0.0
var dodge_direction := Vector2.ZERO

var mobile_move_input := Vector2.ZERO
var mobile_aim_input := Vector2.ZERO
var mobile_fire_held := false

func _ready() -> void:
    collision_layer = 1
    collision_mask = 2 | 4

    var collider := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 14.0
    collider.shape = shape
    add_child(collider)

    weapon = WeaponControllerScript.new()
    add_child(weapon)
    weapon.configure(self)
    queue_redraw()

func _physics_process(delta: float) -> void:
    _update_timers(delta)
    _update_aim()

    if dodge_active:
        _tick_dodge(delta)
    else:
        _tick_movement(delta)

    weapon.tick(delta, aim_direction, mobile_fire_held)
    move_and_slide()
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_SPACE:
            request_dodge()
        elif event.keycode == KEY_R:
            weapon.request_reload()
    elif event is InputEventJoypadButton and event.pressed:
        if event.button_index == JOY_BUTTON_B:
            request_dodge()
        elif event.button_index == JOY_BUTTON_X:
            weapon.request_reload()

func set_mobile_move(value: Vector2) -> void:
    mobile_move_input = value.limit_length(1.0)

func set_mobile_aim(value: Vector2, firing: bool) -> void:
    mobile_aim_input = value.limit_length(1.0)
    mobile_fire_held = firing

func clear_mobile_input() -> void:
    mobile_move_input = Vector2.ZERO
    mobile_aim_input = Vector2.ZERO
    mobile_fire_held = false

func _tick_movement(delta: float) -> void:
    var input_vector := _movement_input()
    var speed_multiplier := weapon.get_movement_multiplier() if weapon != null and weapon.has_method("get_movement_multiplier") else 1.0
    var effective_speed := MOVE_SPEED * speed_multiplier
    var target := input_vector * effective_speed
    var time_constant := ACCEL_TIME if input_vector.length_squared() > 0.0 else DECEL_TIME
    var rate := MOVE_SPEED / time_constant
    velocity = velocity.move_toward(target, rate * delta)

func _tick_dodge(delta: float) -> void:
    dodge_elapsed += delta
    var distance_multiplier := weapon.get_dodge_distance_multiplier() if weapon != null and weapon.has_method("get_dodge_distance_multiplier") else 1.0
    velocity = dodge_direction * (DODGE_DISTANCE * distance_multiplier / DODGE_DURATION)
    invulnerable = dodge_elapsed >= DODGE_IFRAME_START and dodge_elapsed <= DODGE_IFRAME_END

    if dodge_elapsed >= DODGE_DURATION:
        dodge_active = false
        dodge_cooldown_left = DODGE_COOLDOWN
        invulnerable = hit_invuln_left > 0.0
        velocity = Vector2.ZERO

func _update_timers(delta: float) -> void:
    hit_invuln_left = maxf(0.0, hit_invuln_left - delta)
    dodge_cooldown_left = maxf(0.0, dodge_cooldown_left - delta)
    if not dodge_active:
        invulnerable = hit_invuln_left > 0.0

func _movement_input() -> Vector2:
    if mobile_move_input.length_squared() > 0.0025:
        return mobile_move_input

    var result := Vector2.ZERO
    if Input.is_key_pressed(KEY_A): result.x -= 1.0
    if Input.is_key_pressed(KEY_D): result.x += 1.0
    if Input.is_key_pressed(KEY_W): result.y -= 1.0
    if Input.is_key_pressed(KEY_S): result.y += 1.0

    var pad := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
    if pad.length() > 0.22:
        result = pad
    return result.normalized() if result.length_squared() > 1.0 else result

func _update_aim() -> void:
    if mobile_aim_input.length_squared() > 0.01:
        aim_direction = mobile_aim_input.normalized()
        return

    var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
    if stick.length() > 0.25:
        aim_direction = stick.normalized()
    elif not OS.has_feature("mobile"):
        var mouse_delta := get_global_mouse_position() - global_position
        if mouse_delta.length_squared() > 1.0:
            aim_direction = mouse_delta.normalized()

func request_dodge() -> void:
    if dodge_active or dodge_cooldown_left > 0.0:
        return
    var direction := _movement_input()
    if direction.length_squared() <= 0.01:
        direction = aim_direction
    dodge_direction = direction.normalized()
    dodge_active = true
    dodge_elapsed = 0.0
    weapon.cancel_reload()

func take_damage(amount: float, source: Node = null) -> bool:
    if invulnerable or hp <= 0.0:
        return false
    hp = maxf(0.0, hp - amount)
    hit_invuln_left = HIT_INVULN
    invulnerable = true
    EventBus.player_damaged.emit({"amount": amount, "hp": hp, "source": source})
    if hp <= 0.0:
        GameManager.end_run()
        EventBus.player_died.emit({"source": source})
        set_physics_process(false)
    queue_redraw()
    return true

func _draw() -> void:
    var body_color := Color("78d5ff") if not invulnerable else Color("d6f4ff")
    draw_circle(Vector2.ZERO, 15.0, body_color)
    draw_circle(Vector2.ZERO, 7.0, Color("17212b"))
    draw_line(Vector2.ZERO, aim_direction * 27.0, Color("f4f7ff"), 4.0, true)
    if dodge_cooldown_left <= 0.0 and not dodge_active:
        draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, Color(0.47, 0.84, 1.0, 0.35), 2.0)
