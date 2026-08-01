class_name Projectile
extends Area2D

@export var speed: float = 1250.0
@export var lifetime: float = 1.6
@export var damage: float = 20.0
@export var knockback_force: float = 180.0
@export var max_pierces: int = 0
@export var max_ricochets: int = 0
@export var homing_strength: float = 0.0
@export var critical_chance: float = 0.0
@export var critical_multiplier: float = 2.0
@export var explosion_radius: float = 0.0
@export var status_id: StringName
@export var status_stacks: int = 0
@export var faction: StringName = &"player"

var direction := Vector2.RIGHT
var owner_node: Node
var weapon_controller: Node
var _remaining_pierces := 0
var _remaining_ricochets := 0
var _alive := true
var _already_hit: Dictionary = {}
var _returning := false
var _inverse_phase := false
var _void_proc_chance := 0.0
var _void_health_fraction := 0.08
var _absorption_ratio := 0.0
var _absorption_cap := 30.0
var _devour := false
var _impact_multiplier := 1.0
var _explosion_damage_multiplier := 1.0
var _chain_count := 0
var _chain_range := 240.0
var _ignore_world_collision := false
var _pierce_damage_decay := 0.0
var _ricochet_damage_multiplier := 1.0
var _distance_damage_bonus := 0.0
var _close_damage_multiplier := 1.0
var _clear_enemy_projectiles := false
var _split_count := 0
var _split_damage_multiplier := 0.30
var _resonance := false
var _last_round_explosion := false
var _last_round_explosion_radius := 190.0
var _reverse_order_mag := false
var _regenerative_mag := false
var _cross_mag := false
var _origin_position := Vector2.ZERO
var _nominal_range := 1.0
var _enemy_hits := 0
var _ricochet_hits := 0
var _split_spawned := false

func _ready() -> void:
	_remaining_pierces = max_pierces
	_remaining_ricochets = max_ricochets
	if _origin_position == Vector2.ZERO:
		_origin_position = global_position
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func configure(new_direction: Vector2, new_damage: float, new_speed: float = -1.0, payload: Dictionary = {}) -> void:
	direction = new_direction.normalized()
	damage = new_damage * float(payload.get("damage_multiplier", 1.0))
	if new_speed > 0.0:
		speed = new_speed
	speed *= float(payload.get("speed_multiplier", 1.0))
	lifetime *= float(payload.get("lifetime_multiplier", 1.0))
	max_pierces = int(payload.get("pierce", max_pierces))
	max_ricochets = int(payload.get("ricochet", max_ricochets))
	homing_strength = float(payload.get("homing", homing_strength))
	critical_chance = float(payload.get("critical_chance", critical_chance))
	critical_multiplier = float(payload.get("critical_multiplier", critical_multiplier))
	explosion_radius = float(payload.get("explosion_radius", explosion_radius))
	status_id = StringName(payload.get("status_id", status_id))
	status_stacks = int(payload.get("status_stacks", status_stacks))
	owner_node = payload.get("owner", owner_node)
	weapon_controller = payload.get("weapon_controller", weapon_controller)
	faction = StringName(payload.get("faction", faction))
	_inverse_phase = bool(payload.get("inverse_phase", false))
	_void_proc_chance = float(payload.get("void_proc_chance", 0.0))
	_void_health_fraction = float(payload.get("void_health_fraction", 0.08))
	_absorption_ratio = float(payload.get("absorption_ratio", 0.0))
	_absorption_cap = float(payload.get("absorption_cap", 30.0))
	_devour = bool(payload.get("devour", false))
	_impact_multiplier = float(payload.get("impact_multiplier", 1.0))
	_explosion_damage_multiplier = float(payload.get("explosion_damage_multiplier", 1.0))
	_chain_count = int(payload.get("chain_count", 0))
	_chain_range = float(payload.get("chain_range", 240.0))
	_ignore_world_collision = bool(payload.get("ignore_world_collision", false))
	_pierce_damage_decay = float(payload.get("pierce_damage_decay", 0.0))
	_ricochet_damage_multiplier = float(payload.get("ricochet_damage_multiplier", 1.0))
	_distance_damage_bonus = float(payload.get("distance_damage_bonus", 0.0))
	_close_damage_multiplier = float(payload.get("close_damage_multiplier", 1.0))
	_clear_enemy_projectiles = bool(payload.get("clear_enemy_projectiles", false))
	_split_count = int(payload.get("split_count", 0))
	_split_damage_multiplier = float(payload.get("split_damage_multiplier", 0.30))
	_resonance = bool(payload.get("resonance", false))
	_last_round_explosion = bool(payload.get("last_round_explosion", false))
	_last_round_explosion_radius = float(payload.get("last_round_explosion_radius", 190.0))
	_reverse_order_mag = bool(payload.get("reverse_order_mag", false))
	_regenerative_mag = bool(payload.get("regenerative_mag", false))
	_cross_mag = bool(payload.get("cross_mag", false))
	knockback_force *= _impact_multiplier
	var unstable_min := float(payload.get("unstable_damage_min", 1.0))
	var unstable_max := float(payload.get("unstable_damage_max", 1.0))
	if unstable_max > unstable_min or unstable_min != 1.0:
		damage *= randf_range(unstable_min, unstable_max)
	var unstable_spread := float(payload.get("unstable_spread_degrees", 0.0))
	if unstable_spread > 0.0:
		direction = direction.rotated(deg_to_rad(randf_range(-unstable_spread, unstable_spread)))
	var projectile_scale := float(payload.get("projectile_scale", 1.0))
	if projectile_scale != 1.0:
		scale *= projectile_scale
	_apply_magazine_round_modifiers()
	_apply_player_recoil(float(payload.get("player_recoil", 0.0)))
	if bool(payload.get("compressed_mag", false)):
		_consume_compressed_extra_ammo()
	_remaining_pierces = max_pierces
	_remaining_ricochets = max_ricochets
	_origin_position = global_position
	_nominal_range = maxf(1.0, speed * lifetime)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if _returning:
		_update_inverse_return(delta)
	elif homing_strength > 0.0:
		_apply_homing(delta)
	if _clear_enemy_projectiles:
		_clear_weak_enemy_projectiles()
	var travel := direction * speed * delta
	_sweep_motion(travel)
	rotation = direction.angle()
	lifetime -= delta
	if lifetime <= 0.0:
		_spawn_split_projectiles()
		queue_free()

func _sweep_motion(travel: Vector2) -> void:
	if travel.length_squared() <= 0.0001:
		return
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + travel, collision_mask)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position += travel
		return
	global_position = hit.get("position", global_position)
	var collider: Object = hit.get("collider")
	if collider is Node:
		var receiver := _resolve_receiver(collider as Node)
		if receiver != null and receiver.has_method("take_damage"):
			_try_hit(receiver)
			if _alive:
				global_position += direction * 3.0
			return
	if _ignore_world_collision:
		global_position += travel
		return
	var normal: Vector2 = hit.get("normal", Vector2.ZERO)
	if _remaining_ricochets > 0 and normal.length_squared() > 0.0:
		_remaining_ricochets -= 1
		_ricochet_hits += 1
		damage *= _ricochet_damage_multiplier
		direction = direction.bounce(normal).normalized()
		global_position += direction * 5.0
	else:
		_spawn_split_projectiles()
		_alive = false
		queue_free()

func _apply_homing(delta: float) -> void:
	var closest: Node2D
	var closest_dist := INF
	for candidate in get_tree().get_nodes_in_group("enemy"):
		if candidate is Node2D and is_instance_valid(candidate):
			var d := global_position.distance_squared_to(candidate.global_position)
			if d < closest_dist:
				closest = candidate
				closest_dist = d
	if closest == null:
		return
	var desired := (closest.global_position - global_position).normalized()
	direction = direction.slerp(desired, clampf(homing_strength * delta, 0.0, 1.0)).normalized()

func _update_inverse_return(delta: float) -> void:
	if not is_instance_valid(owner_node) or not (owner_node is Node2D):
		return
	var owner_2d := owner_node as Node2D
	var desired := global_position.direction_to(owner_2d.global_position)
	direction = direction.slerp(desired, clampf(8.0 * delta, 0.0, 1.0)).normalized()
	if global_position.distance_squared_to(owner_2d.global_position) <= 28.0 * 28.0:
		if is_instance_valid(weapon_controller) and weapon_controller.has_method("on_inverse_projectile_returned"):
			weapon_controller.on_inverse_projectile_returned()
		_alive = false
		queue_free()

func _on_body_entered(body: Node) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _resolve_receiver(target: Node) -> Node:
	var receiver: Node = target
	if not receiver.has_method("take_damage") and target.get_parent() != null and target.get_parent().has_method("take_damage"):
		receiver = target.get_parent()
	return receiver

func _try_hit(target: Node) -> void:
	if not _alive or target == owner_node:
		return
	var receiver := _resolve_receiver(target)
	if receiver == null or not receiver.has_method("take_damage"):
		return
	if _already_hit.has(receiver.get_instance_id()):
		return
	_already_hit[receiver.get_instance_id()] = true
	var final_damage := damage
	if _enemy_hits > 0 and _pierce_damage_decay > 0.0:
		final_damage *= maxf(0.10, 1.0 - _pierce_damage_decay * _enemy_hits)
	final_damage *= _distance_multiplier()
	if _resonance:
		final_damage *= _resonance_multiplier(receiver)
	if status_id == &"burn" and bool(receiver.get("mechanical")):
		final_damage *= 0.85
	var critical := randf() < critical_chance
	if critical:
		final_damage *= critical_multiplier
	final_damage += _void_bonus_damage(receiver)
	if receiver.has_method("react_to_projectile_hit"):
		final_damage += float(receiver.react_to_projectile_hit(final_damage, explosion_radius > 0.0))
	var health_before := _read_health(receiver)
	var dealt := final_damage
	receiver.take_damage(final_damage, direction * knockback_force)
	var health_after := _read_health(receiver)
	if health_before >= 0.0 and health_after >= 0.0:
		dealt = maxf(0.0, health_before - health_after)
	var killed := health_before > 0.0 and health_after == 0.0
	_apply_status(receiver)
	if explosion_radius > 0.0:
		_explode(final_damage * _explosion_damage_multiplier)
	if _last_round_explosion and _is_last_round():
		var previous_radius := explosion_radius
		explosion_radius = maxf(explosion_radius, _last_round_explosion_radius)
		_explode(final_damage * 1.55)
		explosion_radius = previous_radius
	if _chain_count > 0:
		_chain_damage(receiver, final_damage)
	_notify_damage_dealt(receiver, dealt, killed, critical)
	if killed and _regenerative_mag:
		_try_regenerate_ammo()
	_enemy_hits += 1
	if _split_count > 0:
		_spawn_split_projectiles()
	if _inverse_phase and not _returning:
		_returning = true
		_remaining_pierces = maxi(_remaining_pierces, 99)
		homing_strength = 0.0
		return
	_consume_enemy_hit()

func _distance_multiplier() -> float:
	if _distance_damage_bonus <= 0.0 and _close_damage_multiplier == 1.0:
		return 1.0
	var traveled := _origin_position.distance_to(global_position)
	var ratio := clampf(traveled / _nominal_range, 0.0, 1.0)
	return lerpf(_close_damage_multiplier, 1.0 + _distance_damage_bonus, ratio)

func _resonance_multiplier(receiver: Node) -> float:
	if not is_instance_valid(weapon_controller):
		return 1.0
	var target_id := receiver.get_instance_id()
	var previous_id := int(weapon_controller.get_meta("resonance_target_id", 0))
	var stacks := int(weapon_controller.get_meta("resonance_stacks", 0))
	if previous_id == target_id:
		stacks = mini(8, stacks + 1)
	else:
		stacks = 0
	weapon_controller.set_meta("resonance_target_id", target_id)
	weapon_controller.set_meta("resonance_stacks", stacks)
	return 1.0 + stacks * 0.07

func _void_bonus_damage(receiver: Node) -> float:
	if _void_proc_chance <= 0.0 or randf() >= _void_proc_chance:
		return 0.0
	if receiver.is_in_group("boss"):
		return damage * 0.6
	var maximum := receiver.get("max_health")
	if maximum is float or maximum is int:
		return float(maximum) * _void_health_fraction
	return damage * 0.75

func _read_health(receiver: Node) -> float:
	var value := receiver.get("health")
	if value is float or value is int:
		return maxf(0.0, float(value))
	return -1.0

func _notify_damage_dealt(receiver: Node, amount: float, killed: bool, critical: bool) -> void:
	if not is_instance_valid(weapon_controller):
		return
	if weapon_controller.has_method("on_projectile_damage_dealt"):
		weapon_controller.on_projectile_damage_dealt(receiver, amount, killed, critical, _absorption_ratio, _absorption_cap, _devour)

func _apply_status(receiver: Node) -> void:
	if status_id == StringName() or status_stacks <= 0:
		return
	if receiver.has_method("apply_status_by_id"):
		receiver.apply_status_by_id(status_id, status_stacks)

func _explode(base_damage: float) -> void:
	for candidate in get_tree().get_nodes_in_group("enemy"):
		if not (candidate is Node2D) or not is_instance_valid(candidate):
			continue
		if candidate == owner_node:
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance > explosion_radius:
			continue
		var falloff := 1.0 - clampf(distance / maxf(explosion_radius, 1.0), 0.0, 1.0)
		if candidate.has_method("react_to_explosion"):
			candidate.react_to_explosion(base_damage * falloff)
		if candidate.has_method("take_damage"):
			candidate.take_damage(base_damage * (0.35 + 0.65 * falloff), (candidate.global_position - global_position).normalized() * knockback_force * falloff)

func _chain_damage(primary: Node, base_damage: float) -> void:
	var origin := global_position
	var excluded: Dictionary = {primary.get_instance_id(): true}
	var previous_damage := base_damage * 0.72
	for _index in range(_chain_count):
		var best: Node2D
		var best_distance := _chain_range * _chain_range
		for candidate in get_tree().get_nodes_in_group("enemy"):
			if not (candidate is Node2D) or not is_instance_valid(candidate):
				continue
			if excluded.has(candidate.get_instance_id()):
				continue
			var distance := origin.distance_squared_to(candidate.global_position)
			if distance < best_distance:
				best = candidate
				best_distance = distance
		if best == null:
			break
		excluded[best.get_instance_id()] = true
		best.take_damage(previous_damage, Vector2.ZERO)
		if status_id == &"shock" and best.has_method("apply_status_by_id"):
			best.apply_status_by_id(&"shock", 1)
		origin = best.global_position
		previous_damage *= 0.72

func _apply_magazine_round_modifiers() -> void:
	if not is_instance_valid(weapon_controller):
		return
	var capacity := int(weapon_controller.get("magazine_capacity"))
	var remaining := int(weapon_controller.get("ammo"))
	var shot_number := maxi(1, capacity - remaining)
	if _reverse_order_mag:
		damage *= maxf(0.40, 1.30 - float(shot_number - 1) * 0.03)
	if _cross_mag:
		if shot_number % 2 == 1:
			damage *= 1.20
		else:
			status_stacks += 1

func _consume_compressed_extra_ammo() -> void:
	if not is_instance_valid(weapon_controller):
		return
	if bool(weapon_controller.get_meta("compressed_extra_ammo_lock", false)):
		return
	weapon_controller.set_meta("compressed_extra_ammo_lock", true)
	var current_ammo := int(weapon_controller.get("ammo"))
	if current_ammo > 0:
		weapon_controller.set("ammo", current_ammo - 1)
		if weapon_controller.has_method("_emit_ammo"):
			weapon_controller.call("_emit_ammo")
	get_tree().process_frame.connect(func():
		if is_instance_valid(weapon_controller):
			weapon_controller.set_meta("compressed_extra_ammo_lock", false)
	, CONNECT_ONE_SHOT)

func _try_regenerate_ammo() -> void:
	if not is_instance_valid(weapon_controller) or randf() >= 0.18:
		return
	var capacity := int(weapon_controller.get("magazine_capacity"))
	var current_ammo := int(weapon_controller.get("ammo"))
	if current_ammo >= capacity:
		return
	weapon_controller.set("ammo", current_ammo + 1)
	if weapon_controller.has_method("_emit_ammo"):
		weapon_controller.call("_emit_ammo")

func _is_last_round() -> bool:
	return is_instance_valid(weapon_controller) and int(weapon_controller.get("ammo")) <= 0

func _apply_player_recoil(force: float) -> void:
	if force <= 0.0 or not is_instance_valid(owner_node) or not (owner_node is CharacterBody2D):
		return
	(owner_node as CharacterBody2D).velocity -= direction * force

func _clear_weak_enemy_projectiles() -> void:
	for node in get_tree().get_nodes_in_group("enemy_projectile"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		if global_position.distance_squared_to(node.global_position) > 34.0 * 34.0:
			continue
		var projectile_damage := node.get("damage")
		if projectile_damage is float or projectile_damage is int:
			if float(projectile_damage) <= damage * 0.75:
				node.queue_free()

func _spawn_split_projectiles() -> void:
	if _split_spawned or _split_count <= 0 or not _alive:
		return
	_split_spawned = true
	for index in range(_split_count):
		var child := duplicate() as Projectile
		if child == null:
			continue
		child._split_count = 0
		child._split_spawned = true
		child._already_hit = {}
		child._remaining_pierces = 0
		child._remaining_ricochets = 0
		child.damage = damage * _split_damage_multiplier
		child.lifetime = minf(lifetime if lifetime > 0.0 else 0.55, 0.55)
		child.direction = direction.rotated(deg_to_rad(-18.0 if index == 0 else 18.0))
		get_tree().current_scene.add_child(child)
		child.global_position = global_position + child.direction * 6.0

func _consume_enemy_hit() -> void:
	if _remaining_pierces > 0:
		_remaining_pierces -= 1
		return
	_alive = false
	queue_free()
