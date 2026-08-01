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

func _ready() -> void:
	_remaining_pierces = max_pierces
	_remaining_ricochets = max_ricochets
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func configure(new_direction: Vector2, new_damage: float, new_speed: float = -1.0, payload: Dictionary = {}) -> void:
	direction = new_direction.normalized()
	damage = new_damage
	if new_speed > 0.0:
		speed = new_speed
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
	knockback_force *= _impact_multiplier
	_remaining_pierces = max_pierces
	_remaining_ricochets = max_ricochets
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if _returning:
		_update_inverse_return(delta)
	elif homing_strength > 0.0:
		_apply_homing(delta)
	var travel := direction * speed * delta
	_sweep_motion(travel)
	rotation = direction.angle()
	lifetime -= delta
	if lifetime <= 0.0:
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
	var normal: Vector2 = hit.get("normal", Vector2.ZERO)
	if _remaining_ricochets > 0 and normal.length_squared() > 0.0:
		_remaining_ricochets -= 1
		direction = direction.bounce(normal).normalized()
		global_position += direction * 5.0
	else:
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
	if _chain_count > 0:
		_chain_damage(receiver, final_damage)
	_notify_damage_dealt(receiver, dealt, killed, critical)
	if _inverse_phase and not _returning:
		_returning = true
		_remaining_pierces = maxi(_remaining_pierces, 99)
		homing_strength = 0.0
		return
	_consume_enemy_hit()

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

func _consume_enemy_hit() -> void:
	if _remaining_pierces > 0:
		_remaining_pierces -= 1
		return
	_alive = false
	queue_free()
