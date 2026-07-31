class_name PrototypeWeapon
extends Node2D

signal ammo_state_changed(current: int, capacity: int, reloading: bool)
signal frame_changed(frame_id: StringName, display_name: String)
signal build_changed(snapshot: Dictionary)

var wielder: Node2D
var frame: WeaponFrameData
var equipped_parts: Array[WeaponPartData] = []
var build: Dictionary = {}
var current_ammo := 0
var fire_cooldown := 0.0
var reload_remaining := 0.0
var aim_direction := Vector2.RIGHT
var _burst_remaining := 0
var _burst_timer := 0.0
var _ammo_by_frame: Dictionary = {}
var _last_round_index := 0

func setup(owner_actor: Node2D, initial_frame: WeaponFrameData) -> void:
	wielder = owner_actor
	equip_frame(initial_frame)

func _process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if reload_remaining > 0.0:
		reload_remaining -= delta
		if reload_remaining <= 0.0:
			current_ammo = _capacity()
			_ammo_by_frame[frame.frame_id] = current_ammo
			ammo_state_changed.emit(current_ammo, _capacity(), false)
	if _burst_remaining > 0:
		_process_burst(delta)

func equip_frame(next_frame: WeaponFrameData) -> void:
	if next_frame == null:
		return
	equip_frame_with_parts(next_frame, WeaponPartCatalog.prototype_loadout_for(next_frame.frame_id))

func equip_frame_with_parts(next_frame: WeaponFrameData, parts: Array[WeaponPartData]) -> void:
	if next_frame == null:
		return
	if frame != null:
		_ammo_by_frame[frame.frame_id] = current_ammo
	frame = next_frame.duplicate_frame()
	equipped_parts.clear()
	for part in parts:
		if part != null:
			equipped_parts.append(part.duplicate_part())
	build = WeaponBuildCalculator.compile(frame, equipped_parts)
	current_ammo = clampi(int(_ammo_by_frame.get(frame.frame_id, _capacity())), 0, _capacity())
	fire_cooldown = 0.0
	reload_remaining = 0.0
	_burst_remaining = 0
	_burst_timer = 0.0
	frame_changed.emit(frame.frame_id, frame.display_name)
	ammo_state_changed.emit(current_ammo, _capacity(), false)
	build_changed.emit(get_build_snapshot())

func equip_parts(parts: Array[WeaponPartData]) -> void:
	if frame == null:
		return
	equip_frame_with_parts(frame, parts)

func set_aim(direction: Vector2) -> void:
	if direction.length_squared() > 0.001:
		aim_direction = direction.normalized()
	rotation = aim_direction.angle()

func try_fire() -> bool:
	if wielder == null or frame == null or fire_cooldown > 0.0 or reload_remaining > 0.0 or _burst_remaining > 0:
		return false
	if current_ammo < _ammo_cost():
		start_reload()
		return false
	if frame.fire_mode == WeaponFrameData.FireMode.BURST:
		var available_rounds := floori(float(current_ammo) / float(_ammo_cost()))
		_burst_remaining = mini(frame.burst_count, available_rounds)
		_fire_burst_round()
		return true
	_consume_round()
	_spawn_volley()
	fire_cooldown = _statf("fire_interval", frame.fire_interval)
	_emit_ammo()
	return true

func start_reload() -> bool:
	if frame == null or reload_remaining > 0.0 or current_ammo >= _capacity() or _burst_remaining > 0:
		return false
	reload_remaining = _statf("reload_time", frame.reload_time)
	AudioManager.play_cue(&"reload", -8.0)
	ammo_state_changed.emit(current_ammo, _capacity(), true)
	return true

func _process_burst(delta: float) -> void:
	_burst_timer -= delta
	while _burst_remaining > 0 and _burst_timer <= 0.0:
		_fire_burst_round()

func _fire_burst_round() -> void:
	if _burst_remaining <= 0 or current_ammo < _ammo_cost():
		_burst_remaining = 0
		fire_cooldown = frame.burst_recovery
		return
	_consume_round()
	_spawn_volley()
	_burst_remaining -= 1
	if _burst_remaining > 0 and current_ammo >= _ammo_cost():
		_burst_timer += frame.burst_interval
	else:
		_burst_remaining = 0
		fire_cooldown = frame.burst_recovery
	_emit_ammo()

func _consume_round() -> void:
	_last_round_index = maxi(0, _capacity() - current_ammo)
	current_ammo = maxi(0, current_ammo - _ammo_cost())
	_ammo_by_frame[frame.frame_id] = current_ammo

func _spawn_volley() -> void:
	var pellet_total := _stati("pellet_count", frame.pellet_count)
	var spread_degrees := _statf("spread_degrees", frame.spread_degrees)
	var round_damage_multiplier := _round_damage_multiplier()
	for pellet_index in pellet_total:
		var shot_direction := aim_direction
		if pellet_total > 1:
			var ratio := float(pellet_index) / float(pellet_total - 1)
			var angle_degrees := lerpf(-spread_degrees * 0.5, spread_degrees * 0.5, ratio)
			shot_direction = aim_direction.rotated(deg_to_rad(angle_degrees))
		_spawn_projectile(shot_direction, round_damage_multiplier, true)
	var volume := -4.5 if frame.fire_mode == WeaponFrameData.FireMode.SHOTGUN else -7.0
	AudioManager.play_cue(&"fire", volume, 0.03)

func _spawn_projectile(direction: Vector2, damage_multiplier: float, allow_clone: bool) -> void:
	_create_projectile(direction, damage_multiplier)
	if not allow_clone:
		return
	var clone_chance := float(_effects().get("clone_chance", 0.0))
	if clone_chance <= 0.0 or randf() >= clone_chance:
		return
	var clone_multiplier := float(_effects().get("clone_damage_multiplier", 0.55))
	var clone_direction := direction.rotated(deg_to_rad(randf_range(-2.0, 2.0)))
	_create_projectile(clone_direction, damage_multiplier * clone_multiplier)

func _create_projectile(direction: Vector2, damage_multiplier: float) -> void:
	var projectile_data := ProjectileData.new()
	projectile_data.damage = _statf("damage", frame.base_damage) * damage_multiplier
	projectile_data.speed = _statf("projectile_speed", frame.projectile_speed)
	projectile_data.lifetime = _statf("projectile_lifetime", frame.projectile_lifetime)
	projectile_data.radius = _statf("projectile_radius", frame.projectile_radius)
	projectile_data.pierce_count = _stati("pierce_count", 0)
	projectile_data.pierce_damage_decay = float(_effects().get("pierce_damage_decay", 0.0))
	projectile_data.ricochet_count = _stati("ricochet_count", 0)
	projectile_data.ricochet_damage_multiplier = float(_effects().get("ricochet_damage_multiplier", 1.0))
	projectile_data.knockback = _statf("knockback", frame.knockback)
	projectile_data.critical_chance = _statf("critical_chance", frame.critical_chance)
	projectile_data.status_type = StringName(_effects().get("status_type", &""))
	projectile_data.status_buildup = _statf("status_buildup", 0.0)
	projectile_data.faction = &"player"
	projectile_data.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_ENEMY
	var projectile := CombatProjectile.new()
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(projectile)
	projectile.setup(projectile_data, wielder.global_position + direction * 24.0, direction, wielder)

func _round_damage_multiplier() -> float:
	var decay := float(_effects().get("reverse_round_damage_decay", 0.0))
	if decay <= 0.0:
		return 1.0
	return maxf(0.10, 1.0 - float(_last_round_index) * decay)

func _capacity() -> int:
	return _stati("magazine_capacity", frame.magazine_capacity if frame != null else 1)

func _ammo_cost() -> int:
	return maxi(1, int(_effects().get("ammo_cost", 1)))

func _stats() -> Dictionary:
	return build.get("stats", {}) as Dictionary

func _effects() -> Dictionary:
	return build.get("effects", {}) as Dictionary

func _statf(key: String, fallback: float) -> float:
	return float(_stats().get(key, fallback))

func _stati(key: String, fallback: int) -> int:
	return int(_stats().get(key, fallback))

func _emit_ammo() -> void:
	ammo_state_changed.emit(current_ammo, _capacity(), reload_remaining > 0.0)

func get_snapshot() -> Dictionary:
	if frame == null:
		return {}
	var reload_time := _statf("reload_time", frame.reload_time)
	return {
		"frame_id": frame.frame_id,
		"display_name": frame.display_name,
		"current": current_ammo,
		"capacity": _capacity(),
		"reloading": reload_remaining > 0.0,
		"reload_progress": 1.0 - clampf(reload_remaining / reload_time, 0.0, 1.0),
		"fire_mode": frame.fire_mode,
		"parts": get_build_snapshot().get("part_ids", PackedStringArray())
	}

func get_build_snapshot() -> Dictionary:
	var part_ids := PackedStringArray()
	var part_names := PackedStringArray()
	for part in equipped_parts:
		part_ids.append(String(part.part_id))
		part_names.append(part.display_name)
	return {
		"frame_id": frame.frame_id if frame != null else &"",
		"part_ids": part_ids,
		"part_names": part_names,
		"power_cost": int(build.get("power_cost", 0)),
		"weight": float(build.get("weight", 0.0)),
		"stats": _stats().duplicate(true),
		"effects": _effects().duplicate(true)
	}

func get_display_name() -> String:
	return frame.display_name if frame != null else "NO WEAPON"
