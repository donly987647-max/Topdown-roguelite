class_name PrototypeWeapon
extends Node2D

signal ammo_state_changed(current: int, capacity: int, reloading: bool)
signal frame_changed(frame_id: StringName, display_name: String)

var wielder: Node2D
var frame: WeaponFrameData
var current_ammo := 0
var fire_cooldown := 0.0
var reload_remaining := 0.0
var aim_direction := Vector2.RIGHT
var _burst_remaining := 0
var _burst_timer := 0.0
var _ammo_by_frame: Dictionary = {}

func setup(owner_actor: Node2D, initial_frame: WeaponFrameData) -> void:
	wielder = owner_actor
	equip_frame(initial_frame)

func _process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if reload_remaining > 0.0:
		reload_remaining -= delta
		if reload_remaining <= 0.0:
			current_ammo = frame.magazine_capacity
			_ammo_by_frame[frame.frame_id] = current_ammo
			ammo_state_changed.emit(current_ammo, frame.magazine_capacity, false)
	if _burst_remaining > 0:
		_process_burst(delta)

func equip_frame(next_frame: WeaponFrameData) -> void:
	if next_frame == null:
		return
	if frame != null:
		_ammo_by_frame[frame.frame_id] = current_ammo
	frame = next_frame.duplicate_frame()
	current_ammo = clampi(int(_ammo_by_frame.get(frame.frame_id, frame.magazine_capacity)), 0, frame.magazine_capacity)
	fire_cooldown = 0.0
	reload_remaining = 0.0
	_burst_remaining = 0
	_burst_timer = 0.0
	frame_changed.emit(frame.frame_id, frame.display_name)
	ammo_state_changed.emit(current_ammo, frame.magazine_capacity, false)

func set_aim(direction: Vector2) -> void:
	if direction.length_squared() > 0.001:
		aim_direction = direction.normalized()
	rotation = aim_direction.angle()

func try_fire() -> bool:
	if wielder == null or frame == null or fire_cooldown > 0.0 or reload_remaining > 0.0 or _burst_remaining > 0:
		return false
	if current_ammo <= 0:
		start_reload()
		return false
	if frame.fire_mode == WeaponFrameData.FireMode.BURST:
		_burst_remaining = mini(frame.burst_count, current_ammo)
		_fire_burst_round()
		return true
	_consume_round()
	_spawn_volley()
	fire_cooldown = frame.fire_interval
	_emit_ammo()
	return true

func start_reload() -> bool:
	if frame == null or reload_remaining > 0.0 or current_ammo >= frame.magazine_capacity or _burst_remaining > 0:
		return false
	reload_remaining = frame.reload_time
	AudioManager.play_cue(&"reload", -8.0)
	ammo_state_changed.emit(current_ammo, frame.magazine_capacity, true)
	return true

func _process_burst(delta: float) -> void:
	_burst_timer -= delta
	while _burst_remaining > 0 and _burst_timer <= 0.0:
		_fire_burst_round()

func _fire_burst_round() -> void:
	if _burst_remaining <= 0 or current_ammo <= 0:
		_burst_remaining = 0
		fire_cooldown = frame.burst_recovery
		return
	_consume_round()
	_spawn_volley()
	_burst_remaining -= 1
	if _burst_remaining > 0 and current_ammo > 0:
		_burst_timer += frame.burst_interval
	else:
		_burst_remaining = 0
		fire_cooldown = frame.burst_recovery
	_emit_ammo()

func _consume_round() -> void:
	current_ammo = maxi(0, current_ammo - 1)
	_ammo_by_frame[frame.frame_id] = current_ammo

func _spawn_volley() -> void:
	var pellet_total := maxi(1, frame.pellet_count)
	for pellet_index in pellet_total:
		var shot_direction := aim_direction
		if pellet_total > 1:
			var ratio := float(pellet_index) / float(pellet_total - 1)
			var angle_degrees := lerpf(-frame.spread_degrees * 0.5, frame.spread_degrees * 0.5, ratio)
			shot_direction = aim_direction.rotated(deg_to_rad(angle_degrees))
		_spawn_projectile(shot_direction)
	var volume := -4.5 if frame.fire_mode == WeaponFrameData.FireMode.SHOTGUN else -7.0
	AudioManager.play_cue(&"fire", volume, 0.03)

func _spawn_projectile(direction: Vector2) -> void:
	var projectile_data := ProjectileData.new()
	projectile_data.damage = frame.base_damage
	projectile_data.speed = frame.projectile_speed
	projectile_data.lifetime = frame.projectile_lifetime
	projectile_data.radius = frame.projectile_radius
	projectile_data.knockback = frame.knockback
	projectile_data.critical_chance = frame.critical_chance
	projectile_data.faction = &"player"
	projectile_data.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_ENEMY
	var projectile := CombatProjectile.new()
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(projectile)
	projectile.setup(projectile_data, wielder.global_position + direction * 24.0, direction, wielder)

func _emit_ammo() -> void:
	ammo_state_changed.emit(current_ammo, frame.magazine_capacity, reload_remaining > 0.0)

func get_snapshot() -> Dictionary:
	if frame == null:
		return {}
	return {
		"frame_id": frame.frame_id,
		"display_name": frame.display_name,
		"current": current_ammo,
		"capacity": frame.magazine_capacity,
		"reloading": reload_remaining > 0.0,
		"reload_progress": 1.0 - clampf(reload_remaining / frame.reload_time, 0.0, 1.0),
		"fire_mode": frame.fire_mode
	}

func get_display_name() -> String:
	return frame.display_name if frame != null else "NO WEAPON"
