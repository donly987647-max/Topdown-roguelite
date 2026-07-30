class_name CombatProjectile
extends Node2D

var data: ProjectileData
var direction := Vector2.RIGHT
var shooter: Node
var attack_id: StringName
var _age := 0.0
var _remaining_pierce := 0
var _near_miss_targets: Dictionary = {}

func setup(projectile_data: ProjectileData, start_position: Vector2, travel_direction: Vector2, source: Node) -> void:
	data = projectile_data
	global_position = start_position
	direction = travel_direction.normalized()
	shooter = source
	attack_id = StringName("%s:%s:%s" % [source.get_instance_id(), Time.get_ticks_usec(), randi()])
	_remaining_pierce = data.pierce_count
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
	var query := PhysicsRayQueryParameters2D.create(from, to, data.collision_mask, [shooter.get_rid()] if shooter is CollisionObject2D else [])
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = to
		return
	global_position = hit.position
	var collider: Object = hit.collider
	var accepted := false
	if collider != null and collider.has_method("receive_projectile"):
		var packet := DamagePacket.new()
		packet.amount = data.damage
		packet.attack_id = attack_id
		packet.source = shooter
		packet.source_position = from
		packet.knockback = data.knockback
		packet.team = data.faction
		packet.critical = randf() < data.critical_chance
		packet.strong_hit = data.damage >= 24.0
		accepted = bool(collider.receive_projectile(packet, direction))
	if accepted:
		_spawn_hit_spark(packet_strength())
		_remaining_pierce -= 1
		if _remaining_pierce < 0:
			queue_free()
	else:
		_spawn_hit_spark(0.7)
		queue_free()

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
	draw_circle(Vector2.ZERO, data.radius + 2.0, Color(color, 0.18))
	draw_circle(Vector2.ZERO, data.radius, color)
	draw_line(-direction * 10.0, Vector2.ZERO, Color(color, 0.65), 2.0)
