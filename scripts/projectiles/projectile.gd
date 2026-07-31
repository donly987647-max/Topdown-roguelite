class_name CombatProjectile
extends Node2D

var data: ProjectileData
var direction := Vector2.RIGHT
var shooter: Node
var attack_id: StringName
var _age := 0.0
var _remaining_pierce := 0
var _remaining_ricochets := 0
var _near_miss_targets: Dictionary = {}
var _collision_excludes: Array[RID] = []

func setup(projectile_data: ProjectileData, start_position: Vector2, travel_direction: Vector2, source: Node) -> void:
	data = projectile_data
	global_position = start_position
	direction = travel_direction.normalized()
	shooter = source
	attack_id = StringName("%s:%s:%s" % [source.get_instance_id(), Time.get_ticks_usec(), randi()])
	_remaining_pierce = data.pierce_count
	_remaining_ricochets = data.ricochet_count
	_collision_excludes.clear()
	if shooter is CollisionObject2D:
		_collision_excludes.append((shooter as CollisionObject2D).get_rid())
	queue_redraw()

func _physics_process(delta: float) -> void:
	if data == null:
		queue_free()
		return
	_age += delta
	if _age >= data.lifetime:
		queue_free()
		return
	_check_precision_dodge()
	var from := global_position
	var to := from + direction * data.speed * delta
	var query := PhysicsRayQueryParameters2D.create(from, to, data.collision_mask, _collision_excludes)
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = to
		return

	global_position = hit.position
	var collider: Object = hit.collider
	if collider != null and collider.has_method("receive_projectile"):
		_resolve_actor_hit(collider, from)
		return
	_resolve_world_hit(hit)

func _resolve_actor_hit(collider: Object, source_position: Vector2) -> void:
	var packet := DamagePacket.new()
	packet.amount = data.damage
	packet.attack_id = attack_id
	packet.source = shooter
	packet.source_position = source_position
	packet.knockback = data.knockback
	packet.team = data.faction
	packet.critical = randf() < data.critical_chance
	packet.strong_hit = data.damage >= 24.0
	var accepted := bool(collider.receive_projectile(packet, direction))
	if not accepted:
		_spawn_hit_spark(0.7)
		queue_free()
		return

	if data.status_type != &"" and data.status_buildup > 0.0 and collider.has_method("apply_status_buildup"):
		collider.apply_status_buildup(data.status_type, data.status_buildup, shooter)
	_spawn_hit_spark(packet_strength())
	if collider is CollisionObject2D:
		_collision_excludes.append((collider as CollisionObject2D).get_rid())
	_remaining_pierce -= 1
	if _remaining_pierce < 0:
		queue_free()
		return
	data.damage *= maxf(0.0, 1.0 - data.pierce_damage_decay)
	global_position += direction * maxf(2.0, data.radius)

func _resolve_world_hit(hit: Dictionary) -> void:
	if _remaining_ricochets <= 0:
		_spawn_hit_spark(0.7)
		queue_free()
		return
	var normal: Vector2 = hit.get("normal", Vector2.ZERO)
	if normal.length_squared() <= 0.001:
		queue_free()
		return
	direction = direction.bounce(normal).normalized()
	_remaining_ricochets -= 1
	data.damage *= data.ricochet_damage_multiplier
	global_position = Vector2(hit.position) + direction * maxf(2.0, data.radius)
	_spawn_hit_spark(0.85)
	queue_redraw()

func packet_strength() -> float:
	return clampf(data.damage / 18.0, 0.6, 2.0)

func _check_precision_dodge() -> void:
	if data.faction != &"enemy":
		return
	for target in get_tree().get_nodes_in_group("player"):
		if not target.has_method("is_dashing") or not target.is_dashing():
			continue
		var target_id := target.get_instance_id()
		if _near_miss_targets.has(target_id):
			continue
		var distance := global_position.distance_to(target.global_position)
		if distance >= 14.0 and distance <= 38.0:
			_near_miss_targets[target_id] = true
			if target.has_method("register_precision_dodge"):
				target.register_precision_dodge(get_instance_id())

func _spawn_hit_spark(strength: float) -> void:
	var spark := HitSpark.new()
	spark.strength = strength
	spark.global_position = global_position
	get_tree().current_scene.add_child(spark)

func _draw() -> void:
	if data == null:
		return
	var color := Color("6de7ef") if data.faction == &"player" else Color("ff536d")
	if data.status_type == &"burn":
		color = Color("ff8a3d")
	draw_circle(Vector2.ZERO, data.radius + 2.0, Color(color, 0.18))
	draw_circle(Vector2.ZERO, data.radius, color)
	draw_line(-direction * 10.0, Vector2.ZERO, Color(color, 0.65), 2.0)
