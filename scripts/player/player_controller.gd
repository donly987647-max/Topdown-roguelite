class_name PlayerController
extends CharacterBody2D

const MOVE_SPEED := 260.0
const ACCELERATION_TIME := 0.08
const DECELERATION_TIME := 0.06
const DASH_DURATION := 0.52
const DASH_INVULN_START := 0.12
const DASH_INVULN_END := 0.34
const DASH_DISTANCE := 150.0
const DASH_RECOVERY := 0.08
const DASH_COOLDOWN := 0.35

var aim_direction := Vector2.RIGHT
var room_controller: Node
var health_component: HealthComponent
var weapon: PrototypeWeapon
var weapon_frames: Array[WeaponFrameData] = []
var weapon_index := 0
var _dash_elapsed := 0.0
var _dash_recovery_remaining := 0.0
var _dash_cooldown_remaining := 0.0
var _dash_direction := Vector2.RIGHT
var _dash_speed := DASH_DISTANCE / DASH_DURATION
var _precision_dodge_ids: Dictionary = {}
var _flash_remaining := 0.0

func _ready() -> void:
	add_to_group("player")
	collision_layer = GameConstants.LAYER_PLAYER
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_ENEMY
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 11.0
	collider.shape = shape
	add_child(collider)
	health_component = HealthComponent.new()
	health_component.name = "HealthComponent"
	add_child(health_component)
	health_component.changed.connect(_on_health_changed)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	weapon_frames = WeaponFrameCatalog.all_frames()
	weapon = PrototypeWeapon.new()
	weapon.name = "PrototypeWeapon"
	add_child(weapon)
	weapon.ammo_state_changed.connect(_on_ammo_state_changed)
	weapon.frame_changed.connect(_on_weapon_frame_changed)
	weapon.setup(self, weapon_frames[weapon_index])
	EventBus.player_spawned.emit(self)
	_on_health_changed(health_component.get_snapshot())
	queue_redraw()

func _physics_process(delta: float) -> void:
	_dash_cooldown_remaining = maxf(0.0, _dash_cooldown_remaining - delta)
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	var command := InputRouter.get_command_snapshot(global_position)
	_handle_weapon_selection(command)
	aim_direction = command.aim
	weapon.set_aim(aim_direction)
	if _dash_elapsed > 0.0:
		_process_dash(delta)
	elif _dash_recovery_remaining > 0.0:
		_dash_recovery_remaining -= delta
		velocity = velocity.move_toward(Vector2.ZERO, MOVE_SPEED / DECELERATION_TIME * delta)
		move_and_slide()
	else:
		_process_normal_movement(command.move, delta)
		if command.dash_pressed:
			_start_dash(command.move)
		if command.fire_pressed or (command.device == &"touch" and command.fire_held):
			weapon.try_fire()
		if command.reload_pressed:
			weapon.start_reload()
	if Input.is_action_just_pressed("reset_room"):
		EventBus.run_reset_requested.emit()
	queue_redraw()

func _handle_weapon_selection(command: Dictionary) -> void:
	var requested_slot := int(command.get("weapon_slot", -1))
	if requested_slot >= 0:
		_equip_weapon_index(requested_slot)
	elif bool(command.get("weapon_next", false)):
		_equip_weapon_index(weapon_index + 1)

func _equip_weapon_index(next_index: int) -> void:
	if weapon_frames.is_empty():
		return
	var wrapped_index := posmod(next_index, weapon_frames.size())
	if wrapped_index == weapon_index and weapon.frame != null:
		return
	weapon_index = wrapped_index
	weapon.equip_frame(weapon_frames[weapon_index])
	queue_redraw()

func _process_normal_movement(input_vector: Vector2, delta: float) -> void:
	var target_velocity := input_vector.normalized() * MOVE_SPEED if input_vector.length_squared() > 0.001 else Vector2.ZERO
	if target_velocity != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, MOVE_SPEED / ACCELERATION_TIME * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, MOVE_SPEED / DECELERATION_TIME * delta)
	move_and_slide()

func _start_dash(move_input: Vector2) -> void:
	if _dash_cooldown_remaining > 0.0:
		return
	_dash_direction = move_input.normalized() if move_input.length_squared() > 0.001 else aim_direction
	if room_controller != null and room_controller.has_method("correct_dash_direction"):
		_dash_direction = room_controller.correct_dash_direction(global_position, _dash_direction, DASH_DISTANCE)
	_dash_elapsed = 0.0001
	_dash_recovery_remaining = 0.0
	AudioManager.play_cue(&"dash", -8.0)

func _process_dash(delta: float) -> void:
	_dash_elapsed += delta
	velocity = _dash_direction * _dash_speed
	move_and_slide()
	if _dash_elapsed >= DASH_DURATION:
		_dash_elapsed = 0.0
		_dash_recovery_remaining = DASH_RECOVERY
		_dash_cooldown_remaining = DASH_COOLDOWN
		velocity *= 0.25

func is_dashing() -> bool:
	return _dash_elapsed > 0.0

func is_dash_invulnerable() -> bool:
	return _dash_elapsed >= DASH_INVULN_START and _dash_elapsed <= DASH_INVULN_END

func register_precision_dodge(projectile_id: int) -> void:
	if _precision_dodge_ids.has(projectile_id):
		return
	_precision_dodge_ids[projectile_id] = true
	EventBus.precision_dodge.emit(global_position)
	EventBus.screen_shake.emit(0.6, global_position)

func receive_projectile(packet: DamagePacket, _direction: Vector2) -> bool:
	if is_dash_invulnerable():
		return false
	var result := health_component.apply_damage(packet)
	if bool(result.accepted):
		GameState.damage_taken += packet.amount
		return true
	return false

func get_weapon_snapshot() -> Dictionary:
	return weapon.get_snapshot() if weapon != null else {}

func _on_health_changed(snapshot: Dictionary) -> void:
	var merged := snapshot.duplicate()
	merged["dash_ready"] = _dash_cooldown_remaining <= 0.0 and not is_dashing()
	EventBus.player_stats_changed.emit(merged)

func _on_ammo_state_changed(current: int, capacity: int, reloading: bool) -> void:
	var display_name := weapon.get_display_name() if weapon != null else "NO WEAPON"
	EventBus.ammo_changed.emit(current, capacity, reloading, display_name)

func _on_weapon_frame_changed(_frame_id: StringName, _display_name: String) -> void:
	queue_redraw()

func _on_damaged(health_damage: float, source_position: Vector2) -> void:
	_flash_remaining = 0.16
	AudioManager.play_cue(&"hurt", -7.0, 0.08)
	EventBus.player_damaged.emit(health_damage, source_position)
	EventBus.screen_shake.emit(1.0, source_position)

func _on_died(_packet: DamagePacket) -> void:
	set_physics_process(false)
	velocity = Vector2.ZERO
	await get_tree().create_timer(1.0).timeout
	EventBus.run_reset_requested.emit()

func _draw() -> void:
	var body_color := Color("ffffff") if _flash_remaining > 0.0 else Color("69e79a")
	if is_dashing():
		body_color = Color("6de7ef")
	var weapon_colors := [Color("ffbd55"), Color("8bd8ff"), Color("ff8b72")]
	var weapon_color: Color = weapon_colors[clampi(weapon_index, 0, weapon_colors.size() - 1)]
	draw_circle(Vector2.ZERO, 15.0, Color(0.05, 0.08, 0.1, 0.9))
	draw_circle(Vector2.ZERO, 11.0, body_color)
	draw_line(Vector2.ZERO, aim_direction * 25.0, weapon_color, 3.0)
	draw_circle(aim_direction * 25.0, 3.0, weapon_color)
	if is_dash_invulnerable():
		draw_arc(Vector2.ZERO, 19.0, 0.0, TAU, 32, Color("6de7ef"), 2.0)
