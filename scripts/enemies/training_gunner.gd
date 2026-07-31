class_name TrainingGunner
extends CharacterBody2D

const MOVE_SPEED := 105.0
const PREFERRED_DISTANCE := 250.0
const DETECTION_RANGE := 700.0
const TELEGRAPH_TIME := 0.65
const ATTACK_COOLDOWN := 1.45
const BURN_THRESHOLD := 100.0
const BURN_DURATION := 3.0
const BURN_TICK_INTERVAL := 0.5
const BURN_TICK_DAMAGE := 3.0

var target: PlayerController
var health_component: HealthComponent
var health_multiplier := 1.0
var damage_multiplier := 1.0
var elite_rank := 0
var _attack_cooldown := 0.8
var _telegraph_remaining := 0.0
var _strafe_sign := 1.0
var _flash_remaining := 0.0
var _burn_buildup := 0.0
var _burn_remaining := 0.0
var _burn_tick_remaining := 0.0
var _burn_source: Node
var spawn_index := 0

func _ready() -> void:
	add_to_group("enemy")
	collision_layer = GameConstants.LAYER_ENEMY
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMY
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 13.0 + float(elite_rank) * 1.5
	collider.shape = shape
	add_child(collider)
	health_component = HealthComponent.new()
	health_component.max_health = 54.0 * maxf(0.1, health_multiplier)
	health_component.max_armor_plates = elite_rank
	health_component.armor_per_plate = 12.0
	add_child(health_component)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	_strafe_sign = -1.0 if spawn_index % 2 == 0 else 1.0
	_attack_cooldown = maxf(0.45, 0.8 - float(elite_rank) * 0.08)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	_process_status(delta)
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as PlayerController
		return
	var offset := target.global_position - global_position
	var move_speed := MOVE_SPEED * (1.0 + float(elite_rank) * 0.08)
	if offset.length() > DETECTION_RANGE:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 5.0 * delta)
		move_and_slide()
		return
	if _telegraph_remaining > 0.0:
		_telegraph_remaining -= delta
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 8.0 * delta)
		move_and_slide()
		if _telegraph_remaining <= 0.0:
			_fire_at_target()
		queue_redraw()
		return
	_attack_cooldown -= delta
	var distance := offset.length()
	var move_direction := Vector2.ZERO
	if distance > PREFERRED_DISTANCE + 45.0:
		move_direction = offset.normalized()
	elif distance < PREFERRED_DISTANCE - 45.0:
		move_direction = -offset.normalized()
	else:
		move_direction = offset.normalized().orthogonal() * _strafe_sign
	move_direction += _separation_force() * 0.7
	velocity = velocity.move_toward(move_direction.normalized() * move_speed, move_speed * 5.0 * delta)
	move_and_slide()
	if _attack_cooldown <= 0.0 and _has_line_of_sight():
		_telegraph_remaining = maxf(0.38, TELEGRAPH_TIME - float(elite_rank) * 0.08)
		_attack_cooldown = maxf(0.72, ATTACK_COOLDOWN - float(elite_rank) * 0.12)
		AudioManager.play_cue(&"telegraph", -6.0, 0.12)
	queue_redraw()

func _has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, GameConstants.LAYER_WORLD, [get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _fire_at_target() -> void:
	if target == null:
		return
	var direction := (target.global_position + target.velocity * 0.12 - global_position).normalized()
	var data := ProjectileData.new()
	data.damage = 10.0 * maxf(0.1, damage_multiplier)
	data.speed = 430.0 * (1.0 + float(elite_rank) * 0.04)
	data.lifetime = 2.4
	data.radius = 4.0 + float(elite_rank) * 0.4
	data.knockback = 18.0 + float(elite_rank) * 4.0
	data.critical_chance = 0.0
	data.faction = &"enemy"
	data.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER
	var projectile := CombatProjectile.new()
	get_tree().current_scene.add_child(projectile)
	projectile.setup(data, global_position + direction * 22.0, direction, self)

func _separation_force() -> Vector2:
	var result := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemy"):
		if other == self or not is_instance_valid(other):
			continue
		var delta: Vector2 = global_position - other.global_position
		if delta.length_squared() > 0.01 and delta.length() < 42.0:
			result += delta.normalized() * (1.0 - delta.length() / 42.0)
	return result

func receive_projectile(packet: DamagePacket, direction: Vector2) -> bool:
	var result := health_component.apply_damage(packet, true)
	if bool(result.accepted):
		velocity += direction * packet.knockback
		GameState.damage_dealt += packet.amount
		EventBus.hit_landed.emit(global_position, 1.5 if packet.strong_hit else 1.0, packet.critical)
		EventBus.screen_shake.emit(0.65 if packet.strong_hit else 0.25, global_position)
		AudioManager.play_cue(&"hit", -8.0, 0.025)
		return true
	return false

func apply_status_buildup(status_type: StringName, amount: float, source: Node) -> void:
	if status_type != &"burn" or amount <= 0.0:
		return
	_burn_buildup += amount
	while _burn_buildup >= BURN_THRESHOLD:
		_burn_buildup -= BURN_THRESHOLD
		_burn_remaining = maxf(_burn_remaining, BURN_DURATION)
		_burn_tick_remaining = minf(_burn_tick_remaining, 0.08) if _burn_tick_remaining > 0.0 else 0.08
		_burn_source = source
	queue_redraw()

func _process_status(delta: float) -> void:
	if _burn_remaining <= 0.0:
		return
	_burn_remaining = maxf(0.0, _burn_remaining - delta)
	_burn_tick_remaining -= delta
	if _burn_tick_remaining > 0.0:
		return
	_burn_tick_remaining += BURN_TICK_INTERVAL
	var packet := DamagePacket.new()
	packet.amount = BURN_TICK_DAMAGE
	packet.attack_id = StringName("burn:%s:%s" % [get_instance_id(), Time.get_ticks_msec()])
	packet.source = _burn_source
	packet.source_position = global_position
	packet.team = &"player"
	var result := health_component.apply_damage(packet, true)
	if bool(result.accepted):
		GameState.damage_dealt += packet.amount
		_flash_remaining = 0.06
		queue_redraw()

func _on_damaged(_amount: float, _source: Vector2) -> void:
	_flash_remaining = 0.09
	queue_redraw()

func _on_died(_packet: DamagePacket) -> void:
	GameState.kills += 1
	queue_free()

func _draw() -> void:
	var base_color := Color("ff536d")
	if elite_rank == 1:
		base_color = Color("ff9f43")
	elif elite_rank >= 2:
		base_color = Color("d78cff")
	var color := Color("ffffff") if _flash_remaining > 0.0 else base_color
	if _burn_remaining > 0.0 and _flash_remaining <= 0.0:
		color = Color("ff8a3d")
	var points := PackedVector2Array([Vector2(0, -15), Vector2(13, 9), Vector2(0, 14), Vector2(-13, 9)])
	draw_colored_polygon(points, Color(0.08, 0.04, 0.06, 0.95))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), color, 3.0 + float(elite_rank))
	if elite_rank > 0:
		draw_arc(Vector2.ZERO, 19.0 + float(elite_rank) * 2.0, 0.0, TAU, 24, base_color, 2.0)
	if _burn_remaining > 0.0:
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, Color("ff8a3d"), 2.0)
	if target != null:
		var direction := (target.global_position - global_position).normalized()
		draw_line(Vector2.ZERO, direction * 18.0, color, 3.0)
		if _telegraph_remaining > 0.0:
			var telegraph_time := maxf(0.38, TELEGRAPH_TIME - float(elite_rank) * 0.08)
			var alpha := 0.35 + 0.65 * (1.0 - _telegraph_remaining / telegraph_time)
			draw_line(direction * 20.0, direction * 420.0, Color(1.0, 0.25, 0.3, alpha), 2.0)
			draw_arc(Vector2.ZERO, 20.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - _telegraph_remaining / telegraph_time), 24, Color("ffbd55"), 3.0)
