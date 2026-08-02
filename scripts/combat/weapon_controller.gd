class_name WeaponController
extends Node2D

signal ammo_changed(current: int, capacity: int, reserve: int)
signal reload_started(duration: float)
signal reload_finished
signal reload_cancelled
signal perfect_reload
signal shot_fired
signal heat_changed(current: float, maximum: float)
signal overheated(duration: float)
signal overheat_recovered
signal build_applied(build: WeaponBuild)
signal temporary_shield_requested(amount: float)
signal frame_state_changed(frame_id: StringName, value: float)

@export_category("Assembly")
@export var weapon_build: WeaponBuild

@export_category("Projectile")
@export var projectile_scene: PackedScene
@export var damage: float = 20.0
@export var rounds_per_second: float = 6.5
@export var spread_degrees: float = 1.5
@export var projectile_speed: float = 1250.0
@export var automatic: bool = true

@export_category("Ammo / Reload")
@export var magazine_capacity: int = 12
@export var starting_reserve_ammo: int = 120
@export var infinite_reserve_ammo: bool = false
@export var auto_reload_when_empty: bool = true
@export var reload_duration: float = 1.15
@export_range(0.0, 1.0) var perfect_reload_window_start: float = 0.62
@export_range(0.0, 1.0) var perfect_reload_window_end: float = 0.78
@export var perfect_reload_time_reduction: float = 0.25
@export var cancel_reload_on_dash: bool = true

@export_category("Heat")
@export var uses_heat: bool = false
@export var max_heat: float = 100.0
@export var heat_per_shot: float = 10.0
@export var heat_cool_rate: float = 28.0
@export var overheat_lock_duration: float = 1.2

@export_category("Feedback")
@export var muzzle_flash_duration: float = 0.045

var ammo: int
var reserve_ammo: int
var heat := 0.0
var _fire_cooldown := 0.0
var _reload_left := 0.0
var _is_reloading := false
var _overheat_left := 0.0
var _overheated := false
var _build_stats: Dictionary = {}
var _perfect_reload_damage_bonus := 1.0
var _perfect_reload_force_crit := false
var _burst_remaining := 0
var _burst_timer := 0.0
var _charge_time := 0.0
var _rotary_spin := 0.0
var _beam_tick_left := 0.0
var _beam_ammo_left := 0.0
var _beam_target_id := 0
var _beam_target_time := 0.0
var _chain_hit_streak := 0
var _chain_hit_timeout := 0.0
var _devour_multiplier := 1.0
var _absorption_shield_generated := 0.0

@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_flash: Polygon2D = get_node_or_null("MuzzleFlash") as Polygon2D

func _ready() -> void:
	if weapon_build != null:
		apply_build(weapon_build)
	ammo = magazine_capacity
	reserve_ammo = maxi(0, starting_reserve_ammo)
	_emit_ammo()
	heat_changed.emit(heat, max_heat)
	if muzzle_flash != null:
		muzzle_flash.visible = false

func apply_build(build: WeaponBuild) -> bool:
	if build == null or not build.is_complete() or not build.is_compatible():
		return false
	weapon_build = build
	_build_stats = build.computed_stats()
	damage = float(_build_stats.get("damage", damage))
	var interval := maxf(0.01, float(_build_stats.get("fire_interval", 1.0 / maxf(rounds_per_second, 0.01))))
	rounds_per_second = 1.0 / interval
	magazine_capacity = maxi(1, int(round(_build_stats.get("magazine_size", magazine_capacity))))
	reload_duration = maxf(0.05, float(_build_stats.get("reload_time", reload_duration)))
	uses_heat = bool(_build_stats.get("uses_heat", uses_heat))
	heat_per_shot = maxf(0.0, float(_build_stats.get("heat_per_shot", heat_per_shot)))
	if _build_stats.has("projectile_speed"):
		projectile_speed = maxf(1.0, float(_build_stats["projectile_speed"]))
	if _build_stats.has("spread"):
		spread_degrees = maxf(0.0, float(_build_stats["spread"]))
	_reset_frame_state()
	build_applied.emit(build)
	return true

func _process(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	_chain_hit_timeout = maxf(0.0, _chain_hit_timeout - delta)
	if _chain_hit_timeout <= 0.0:
		_chain_hit_streak = 0
	_update_heat(delta)
	_update_burst(delta)
	if _is_reloading:
		if cancel_reload_on_dash and Input.is_action_just_pressed("dash"):
			cancel_reload()
			return
		if Input.is_action_just_pressed("reload") and _is_in_perfect_reload_window():
			_trigger_perfect_reload()
			return
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()
		return
	if Input.is_action_just_pressed("reload"):
		start_reload()
		return

	var frame := _frame_id()
	if frame == &"rail_lancer":
		_process_rail_lancer(delta)
		return
	if frame == &"beam_cutter":
		_process_beam_cutter(delta)
		return
	if frame == &"rotary_cannon":
		_process_rotary_cannon(delta)
		return
	if frame == &"burst_carbine":
		if Input.is_action_just_pressed("fire"):
			_start_burst()
		return

	var wants_fire := Input.is_action_pressed("fire") if automatic else Input.is_action_just_pressed("fire")
	if wants_fire:
		try_fire()

func try_fire() -> bool:
	if _is_reloading or _fire_cooldown > 0.0 or _overheated:
		return false
	if ammo <= 0:
		if auto_reload_when_empty:
			start_reload()
		return false
	if projectile_scene == null and _frame_id() != &"beam_cutter":
		push_warning("WeaponController has no projectile_scene")
		return false
	if _roll_overload_failure():
		return false

	match _frame_id():
		&"compression_hammer":
			return _fire_compression_hammer()
		&"drone_controller":
			return _fire_drone_controller()
		_:
			return _fire_projectile_round()

func _fire_projectile_round(cooldown_override: float = -1.0, damage_multiplier: float = 1.0, payload_overrides: Dictionary = {}) -> bool:
	if not _consume_ammo_and_heat(cooldown_override):
		return false
	var payload := WeaponEffectResolver.shot_payload(weapon_build, _build_stats)
	payload["owner"] = _owner_actor()
	payload["weapon_controller"] = self
	for key in payload_overrides.keys():
		payload[key] = payload_overrides[key]
	_apply_frame_payload(payload)
	if _perfect_reload_force_crit:
		payload["critical_chance"] = 1.0
	var pellet_count := WeaponEffectResolver.pellet_count(weapon_build, _build_stats)
	if _frame_id() == &"breach_shotgun":
		pellet_count = maxi(pellet_count, 8)
	var total_spread := WeaponEffectResolver.pellet_spread_degrees(weapon_build, _build_stats, spread_degrees)
	if _frame_id() == &"breach_shotgun":
		total_spread = maxf(total_spread, 18.0)
	var base_direction := Vector2.RIGHT.rotated(global_rotation)
	var shot_damage_multiplier := damage_multiplier * _perfect_reload_damage_bonus * _devour_multiplier
	for i in range(pellet_count):
		var offset_degrees := 0.0
		if pellet_count > 1:
			var t := float(i) / float(maxi(1, pellet_count - 1))
			offset_degrees = lerpf(-total_spread * 0.5, total_spread * 0.5, t)
		else:
			offset_degrees = randf_range(-total_spread, total_spread)
		_spawn_projectile(base_direction.rotated(deg_to_rad(offset_degrees)), payload, shot_damage_multiplier)
	_try_spawn_replication(base_direction, payload, shot_damage_multiplier)
	_consume_one_shot_bonuses()
	_play_muzzle_flash()
	shot_fired.emit()
	return true

func _apply_frame_payload(payload: Dictionary) -> void:
	match _frame_id():
		&"shrapnel_launcher":
			payload["explosion_radius"] = maxf(float(payload.get("explosion_radius", 0.0)), 145.0)
			payload["explosion_damage_multiplier"] = maxf(float(payload.get("explosion_damage_multiplier", 1.0)), 2.25)
		&"arc_projector":
			payload["status_id"] = &"shock"
			payload["status_stacks"] = maxi(1, int(payload.get("status_stacks", 0)))
			payload["chain_count"] = maxi(3, int(payload.get("chain_count", 0)))
			payload["chain_range"] = maxf(260.0, float(payload.get("chain_range", 0.0)))
		&"sawblade_caster":
			payload["ricochet"] = maxi(3, int(payload.get("ricochet", 0)))

func _spawn_projectile(direction: Vector2, payload: Dictionary, damage_multiplier: float, position_offset: Vector2 = Vector2.ZERO) -> void:
	var projectile := projectile_scene.instantiate() as Projectile
	if projectile == null:
		push_error("Projectile scene root must inherit Projectile")
		return
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position + position_offset
	projectile.configure(direction, damage * damage_multiplier, projectile_speed, payload)

func _try_spawn_replication(direction: Vector2, payload: Dictionary, damage_multiplier: float) -> void:
	var chance := float(payload.get("replication_chance", 0.0))
	if chance <= 0.0:
		return
	var normalized_chance := chance
	if rounds_per_second >= 8.0:
		normalized_chance *= 0.65
	if randf() >= normalized_chance:
		return
	var clone_payload := payload.duplicate(true)
	clone_payload["replication_chance"] = 0.0
	var clone_mult := float(payload.get("replication_damage_multiplier", 0.55))
	_spawn_projectile(direction.rotated(deg_to_rad(randf_range(-3.0, 3.0))), clone_payload, damage_multiplier * clone_mult)

func _start_burst() -> void:
	if _burst_remaining > 0 or _fire_cooldown > 0.0 or _is_reloading or _overheated:
		return
	_burst_remaining = 3
	_burst_timer = 0.0
	_fire_burst_round()

func _update_burst(delta: float) -> void:
	if _burst_remaining <= 0:
		return
	_burst_timer -= delta
	if _burst_timer <= 0.0:
		_fire_burst_round()

func _fire_burst_round() -> void:
	if _burst_remaining <= 0:
		return
	if ammo <= 0 or _overheated:
		_burst_remaining = 0
		if ammo <= 0 and auto_reload_when_empty:
			start_reload()
		return
	if _roll_overload_failure():
		_burst_remaining = 0
		return
	_fire_projectile_round(0.0)
	_burst_remaining -= 1
	if _burst_remaining > 0:
		_burst_timer = 0.08
	else:
		_fire_cooldown = maxf(_fire_cooldown, 0.32)

func _process_rail_lancer(delta: float) -> void:
	if _overheated or _is_reloading:
		_charge_time = 0.0
		return
	var max_charge := float(_build_stats.get("max_charge_time", 1.2))
	if Input.is_action_pressed("fire") and ammo > 0:
		_charge_time = minf(max_charge, _charge_time + delta)
		frame_state_changed.emit(&"rail_lancer", _charge_time / maxf(max_charge, 0.01))
	if Input.is_action_just_released("fire") and _charge_time > 0.0:
		if _fire_cooldown <= 0.0 and not _roll_overload_failure():
			var ratio := clampf(_charge_time / maxf(max_charge, 0.01), 0.0, 1.0)
			var multiplier := lerpf(1.0, 110.0 / 45.0, ratio)
			var pierce := 1 + int(floor(ratio * 2.99))
			_fire_projectile_round(0.38, multiplier, {"pierce": pierce})
		_charge_time = 0.0
		frame_state_changed.emit(&"rail_lancer", 0.0)

func _process_rotary_cannon(delta: float) -> void:
	var firing := Input.is_action_pressed("fire") and ammo > 0 and not _overheated and not _is_reloading
	_rotary_spin = move_toward(_rotary_spin, 1.0 if firing else 0.0, delta * (1.8 if firing else 1.25))
	frame_state_changed.emit(&"rotary_cannon", _rotary_spin)
	if not firing or _fire_cooldown > 0.0:
		return
	var max_rps := float(_build_stats.get("max_rounds_per_second", 14.0))
	var min_rps := minf(max_rps, maxf(3.5, rounds_per_second * 0.55))
	var current_rps := lerpf(min_rps, max_rps, _rotary_spin)
	if not _roll_overload_failure():
		_fire_projectile_round(1.0 / maxf(current_rps, 0.01))

func _process_beam_cutter(delta: float) -> void:
	var firing := Input.is_action_pressed("fire") and ammo > 0 and not _overheated and not _is_reloading
	if not firing:
		_beam_tick_left = 0.0
		_beam_ammo_left = 0.0
		_beam_target_id = 0
		_beam_target_time = 0.0
		return
	_beam_tick_left -= delta
	_beam_ammo_left -= delta
	if _beam_tick_left > 0.0:
		return
	_beam_tick_left = 0.10
	if _beam_ammo_left <= 0.0:
		if not _consume_ammo_and_heat(0.0, 0.4):
			return
		_beam_ammo_left = 0.40
	else:
		_add_heat(heat_per_shot * 0.35)
	_fire_beam_tick(delta)

func _fire_beam_tick(delta: float) -> void:
	var direction := Vector2.RIGHT.rotated(global_rotation)
	var max_range := float(_build_stats.get("beam_range", 760.0))
	var query := PhysicsRayQueryParameters2D.create(muzzle.global_position, muzzle.global_position + direction * max_range)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_beam_target_id = 0
		_beam_target_time = 0.0
		return
	var collider: Object = hit.get("collider")
	if not (collider is Node):
		return
	var receiver: Node = collider as Node
	if not receiver.has_method("take_damage") and receiver.get_parent() != null and receiver.get_parent().has_method("take_damage"):
		receiver = receiver.get_parent()
	if not receiver.has_method("take_damage"):
		return
	var id := receiver.get_instance_id()
	if id == _beam_target_id:
		_beam_target_time += maxf(delta, 0.10)
	else:
		_beam_target_id = id
		_beam_target_time = 0.0
	var ramp := lerpf(1.0, 1.8, clampf(_beam_target_time / 1.5, 0.0, 1.0))
	var tick_damage := float(_build_stats.get("beam_dps", 72.0)) * 0.10 * ramp * _devour_multiplier
	var health_before := _read_health(receiver)
	receiver.take_damage(tick_damage, direction * 45.0)
	var health_after := _read_health(receiver)
	on_projectile_damage_dealt(receiver, maxf(0.0, health_before - health_after) if health_before >= 0.0 and health_after >= 0.0 else tick_damage, health_before > 0.0 and health_after == 0.0, false, 0.0, 0.0, _payload_has_devour())
	_consume_one_shot_bonuses()
	shot_fired.emit()

func _fire_drone_controller() -> bool:
	if not _consume_ammo_and_heat():
		return false
	var payload := WeaponEffectResolver.shot_payload(weapon_build, _build_stats)
	payload["owner"] = _owner_actor()
	payload["weapon_controller"] = self
	var direction := Vector2.RIGHT.rotated(global_rotation)
	var perpendicular := direction.orthogonal()
	var mult := _perfect_reload_damage_bonus * _devour_multiplier * 0.72
	_spawn_projectile(direction.rotated(-0.04), payload, mult, perpendicular * 18.0)
	_spawn_projectile(direction.rotated(0.04), payload, mult, -perpendicular * 18.0)
	_consume_one_shot_bonuses()
	_play_muzzle_flash()
	shot_fired.emit()
	return true

func _fire_compression_hammer() -> bool:
	if not _consume_ammo_and_heat(0.72):
		return false
	var forward := Vector2.RIGHT.rotated(global_rotation)
	var origin := global_position
	var hit_any := false
	for candidate in get_tree().get_nodes_in_group("enemy"):
		if not (candidate is Node2D) or not candidate.has_method("take_damage"):
			continue
		var enemy_node: Node2D = candidate as Node2D
		var offset: Vector2 = enemy_node.global_position - origin
		if offset.length() > 125.0 or offset.length_squared() <= 0.01:
			continue
		if forward.dot(offset.normalized()) < 0.42:
			continue
		var amount: float = damage * _perfect_reload_damage_bonus * _devour_multiplier
		enemy_node.call("take_damage", amount, forward * 620.0)
		hit_any = true
	for node in get_tree().get_nodes_in_group("enemy_projectile"):
		if not (node is EnemyProjectile) or not is_instance_valid(node):
			continue
		var enemy_projectile: EnemyProjectile = node as EnemyProjectile
		if origin.distance_squared_to(enemy_projectile.global_position) > 135.0 * 135.0:
			continue
		var reflected_direction: Vector2 = origin.direction_to(enemy_projectile.global_position)
		var reflected_damage: float = enemy_projectile.damage * 1.5
		var reflected_position: Vector2 = enemy_projectile.global_position
		enemy_projectile.queue_free()
		var payload: Dictionary = {"owner": _owner_actor(), "weapon_controller": self, "faction": &"player", "pierce": 0, "ricochet": 0}
		_spawn_projectile(reflected_direction, payload, reflected_damage / maxf(damage, 0.01), reflected_position - muzzle.global_position)
		hit_any = true
	_consume_one_shot_bonuses()
	_play_muzzle_flash()
	shot_fired.emit()
	return hit_any or true

func _consume_ammo_and_heat(cooldown_override: float = -1.0, ammo_interval: float = 0.0) -> bool:
	if ammo <= 0:
		if auto_reload_when_empty:
			start_reload()
		return false
	ammo -= 1
	if cooldown_override >= 0.0:
		_fire_cooldown = cooldown_override
	else:
		var rate_mult := 1.0
		if _frame_id() == &"chain_smg":
			rate_mult = minf(1.8, 1.0 + _chain_hit_streak * 0.08)
		_fire_cooldown = (1.0 / maxf(rounds_per_second, 0.01)) / rate_mult
	_add_heat(heat_per_shot)
	_emit_ammo()
	return true

func _add_heat(amount: float) -> void:
	if not uses_heat or amount <= 0.0 or _overheated:
		return
	heat = minf(max_heat, heat + amount)
	heat_changed.emit(heat, max_heat)
	if heat >= max_heat:
		_begin_overheat()

func _roll_overload_failure() -> bool:
	if weapon_build == null or weapon_build.power_overload_ratio() <= 0.0:
		return false
	var failure_chance := clampf(weapon_build.power_overload_ratio() * 0.12, 0.0, 0.35)
	if randf() >= failure_chance:
		return false
	_fire_cooldown = 0.12
	return true

func on_projectile_damage_dealt(_target: Node, amount: float, killed: bool, _critical: bool, absorption_ratio: float, absorption_cap: float, devour: bool) -> void:
	if _frame_id() == &"chain_smg" and amount > 0.0:
		_chain_hit_streak = mini(10, _chain_hit_streak + 1)
		_chain_hit_timeout = 0.85
	if absorption_ratio > 0.0 and amount > 0.0:
		var remaining_cap := maxf(0.0, absorption_cap - _absorption_shield_generated)
		var shield_gain := minf(remaining_cap, amount * absorption_ratio)
		if shield_gain > 0.0:
			_absorption_shield_generated += shield_gain
			var actor := _owner_actor()
			if actor != null and actor.has_method("add_temporary_shield"):
				actor.add_temporary_shield(shield_gain)
			else:
				temporary_shield_requested.emit(shield_gain)
	if devour and killed:
		_devour_multiplier = maxf(_devour_multiplier, 1.35)

func on_inverse_projectile_returned() -> void:
	ammo = mini(magazine_capacity, ammo + 1)
	_emit_ammo()

func _payload_has_devour() -> bool:
	var payload := WeaponEffectResolver.shot_payload(weapon_build, _build_stats)
	return bool(payload.get("devour", false))

func _read_health(receiver: Node) -> float:
	var value: Variant = receiver.get("health")
	if value is float or value is int:
		return maxf(0.0, float(value))
	return -1.0

func _owner_actor() -> Node:
	if get_parent() != null and get_parent().get_parent() != null:
		return get_parent().get_parent()
	return owner

func _frame_id() -> StringName:
	return WeaponEffectResolver.frame_id(weapon_build)

func _consume_one_shot_bonuses() -> void:
	_perfect_reload_damage_bonus = 1.0
	_perfect_reload_force_crit = false
	_devour_multiplier = 1.0

func _reset_frame_state() -> void:
	_burst_remaining = 0
	_burst_timer = 0.0
	_charge_time = 0.0
	_rotary_spin = 0.0
	_beam_tick_left = 0.0
	_beam_ammo_left = 0.0
	_beam_target_id = 0
	_beam_target_time = 0.0
	_chain_hit_streak = 0
	_chain_hit_timeout = 0.0
	_devour_multiplier = 1.0
	_absorption_shield_generated = 0.0

func start_reload() -> bool:
	if _is_reloading or ammo >= magazine_capacity:
		return false
	if not infinite_reserve_ammo and reserve_ammo <= 0:
		return false
	_is_reloading = true
	_reload_left = reload_duration
	_burst_remaining = 0
	_charge_time = 0.0
	reload_started.emit(reload_duration)
	return true

func cancel_reload() -> void:
	if not _is_reloading:
		return
	_is_reloading = false
	_reload_left = 0.0
	reload_cancelled.emit()

func _trigger_perfect_reload() -> void:
	perfect_reload.emit()
	_reload_left = minf(_reload_left, reload_duration * perfect_reload_time_reduction)
	_perfect_reload_damage_bonus = maxf(_perfect_reload_damage_bonus, float(_build_stats.get("perfect_reload_damage_multiplier", 1.25)))
	if _frame_id() == &"service_pistol":
		_perfect_reload_force_crit = true

func _finish_reload() -> void:
	_is_reloading = false
	_reload_left = 0.0
	var needed := magazine_capacity - ammo
	var loaded := needed if infinite_reserve_ammo else mini(needed, reserve_ammo)
	ammo += loaded
	if not infinite_reserve_ammo:
		reserve_ammo -= loaded
	_absorption_shield_generated = 0.0
	_emit_ammo()
	reload_finished.emit()

func add_reserve_ammo(amount: int) -> void:
	if amount <= 0 or infinite_reserve_ammo:
		return
	reserve_ammo += amount
	_emit_ammo()

func set_infinite_reserve(enabled: bool) -> void:
	infinite_reserve_ammo = enabled
	_emit_ammo()

func _is_in_perfect_reload_window() -> bool:
	var progress := reload_progress()
	return progress >= perfect_reload_window_start and progress <= perfect_reload_window_end

func _update_heat(delta: float) -> void:
	if not uses_heat:
		return
	if _overheated:
		_overheat_left -= delta
		if _overheat_left <= 0.0:
			_overheated = false
			heat = 0.0
			heat_changed.emit(heat, max_heat)
			overheat_recovered.emit()
		return
	if heat > 0.0 and not Input.is_action_pressed("fire"):
		heat = maxf(0.0, heat - heat_cool_rate * delta)
		heat_changed.emit(heat, max_heat)

func _begin_overheat() -> void:
	_overheated = true
	_overheat_left = overheat_lock_duration
	_burst_remaining = 0
	_charge_time = 0.0
	overheated.emit(overheat_lock_duration)

func _emit_ammo() -> void:
	ammo_changed.emit(ammo, magazine_capacity, -1 if infinite_reserve_ammo else reserve_ammo)

func _play_muzzle_flash() -> void:
	if muzzle_flash == null:
		return
	muzzle_flash.visible = true
	muzzle_flash.rotation = randf_range(-0.15, 0.15)
	var timer := get_tree().create_timer(muzzle_flash_duration)
	timer.timeout.connect(func():
		if is_instance_valid(muzzle_flash):
			muzzle_flash.visible = false
	)

func is_reloading() -> bool:
	return _is_reloading

func reload_progress() -> float:
	if not _is_reloading or reload_duration <= 0.0:
		return 0.0
	return 1.0 - clampf(_reload_left / reload_duration, 0.0, 1.0)

func is_perfect_reload_window_active() -> bool:
	return _is_reloading and _is_in_perfect_reload_window()

func is_overheated() -> bool:
	return _overheated