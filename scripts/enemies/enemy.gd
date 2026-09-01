extends CharacterBody2D

const ProjectileScript = preload("res://scripts/combat/projectile.gd")

var player: Node2D
var data: Dictionary = {}
var hp := 40.0
var attack_cooldown := 0.0
var telegraph_left := 0.0
var burst_left := 0
var burst_gap_left := 0.0
var dead := false

var fire_stacks := 0
var fire_time := 0.0
var fire_tick := 0.0
var fire_power := 1.0
var frost_time := 0.0
var corrosion_time := 0.0
var corrosion_tick := 0.0
var corrosion_power := 1.0
var status_source: Node

func configure(target: Node2D, definition: Dictionary) -> void:
    player = target
    data = definition.duplicate(true)
    hp = float(data.get("max_hp", 40.0))
    queue_redraw()

func _ready() -> void:
    collision_layer = 2
    collision_mask = 1 | 2 | 4
    add_to_group("enemies")

    var collider := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = float(data.get("collision_radius", 15.0)) if not data.is_empty() else 15.0
    collider.shape = shape
    add_child(collider)

func _physics_process(delta: float) -> void:
    if dead or not is_instance_valid(player):
        return

    _tick_status(delta)
    if dead:
        return

    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    burst_gap_left = maxf(0.0, burst_gap_left - delta)

    if telegraph_left > 0.0:
        telegraph_left -= delta
        velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
        if telegraph_left <= 0.0:
            _execute_attack()
        move_and_slide()
        queue_redraw()
        return

    if burst_left > 0 and burst_gap_left <= 0.0:
        _fire_bolt()
        burst_left -= 1
        burst_gap_left = 0.11

    var role := String(data.get("role", "melee"))
    if role == "ranged":
        _ranged_ai(delta)
    else:
        _melee_ai(delta)

    move_and_slide()
    queue_redraw()

func _melee_ai(delta: float) -> void:
    var offset := player.global_position - global_position
    var distance := offset.length()
    var move_speed := float(data.get("move_speed", 170.0)) * _status_move_multiplier()
    velocity = offset.normalized() * move_speed if distance > 30.0 else Vector2.ZERO

    if distance <= float(data.get("attack_range", 34.0)) and attack_cooldown <= 0.0:
        _begin_telegraph()

func _ranged_ai(delta: float) -> void:
    var offset := player.global_position - global_position
    var distance := offset.length()
    var preferred := float(data.get("preferred_range", 280.0))
    var move_speed := float(data.get("move_speed", 120.0)) * _status_move_multiplier()
    var dir := offset.normalized()

    if distance > preferred + 45.0:
        velocity = dir * move_speed
    elif distance < preferred - 55.0:
        velocity = -dir * move_speed
    else:
        var tangent := Vector2(-dir.y, dir.x)
        velocity = tangent * move_speed * 0.55

    if attack_cooldown <= 0.0 and distance <= float(data.get("attack_range", 520.0)):
        _begin_telegraph()

func _begin_telegraph() -> void:
    telegraph_left = float(data.get("telegraph_time", 0.28))
    attack_cooldown = float(data.get("attack_cooldown", 1.25))

func _execute_attack() -> void:
    var role := String(data.get("role", "melee"))
    if role == "ranged":
        burst_left = int(data.get("burst_count", 3))
        burst_gap_left = 0.0
    else:
        if global_position.distance_to(player.global_position) <= float(data.get("attack_range", 34.0)) + 12.0:
            player.take_damage(float(data.get("damage", 10.0)), self)

func _fire_bolt() -> void:
    if not is_instance_valid(player):
        return
    var dir := (player.global_position - global_position).normalized()
    var projectile := ProjectileScript.new()
    get_tree().current_scene.add_child(projectile)
    projectile.setup(global_position + dir * 22.0, dir, float(data.get("projectile_speed", 460.0)), float(data.get("damage", 9.0)), false, self)

func take_damage(amount: float, source: Node = null) -> bool:
    if dead:
        return false
    var final_amount := amount * (1.12 if corrosion_time > 0.0 else 1.0)
    hp -= final_amount
    if hp <= 0.0:
        dead = true
        GameManager.register_enemy_kill()
        EventBus.enemy_killed.emit({"enemy_id": data.get("id", "enemy"), "position": global_position, "source": source})
        remove_from_group("enemies")
        queue_free()
    else:
        queue_redraw()
    return true

func apply_weapon_effect(effect: String, strength: float, hit_damage: float, source: Node) -> void:
    if dead:
        return
    status_source = source
    match effect:
        "fire":
            fire_stacks = mini(5, fire_stacks + 1)
            fire_time = 4.0
            fire_tick = minf(fire_tick, 0.25)
            fire_power = maxf(fire_power, strength)
        "frost":
            frost_time = maxf(frost_time, 2.4 + 0.5 * strength)
        "electric":
            _chain_electric(hit_damage * 0.28 * strength, source)
        "corrosion":
            corrosion_time = maxf(corrosion_time, 4.0)
            corrosion_tick = minf(corrosion_tick, 0.4)
            corrosion_power = maxf(corrosion_power, strength)
    queue_redraw()

func _tick_status(delta: float) -> void:
    if fire_time > 0.0:
        fire_time = maxf(0.0, fire_time - delta)
        fire_tick -= delta
        if fire_tick <= 0.0:
            fire_tick = 0.55
            take_damage(1.4 * float(fire_stacks) * fire_power, status_source)
        if fire_time <= 0.0:
            fire_stacks = 0

    if frost_time > 0.0:
        frost_time = maxf(0.0, frost_time - delta)

    if corrosion_time > 0.0:
        corrosion_time = maxf(0.0, corrosion_time - delta)
        corrosion_tick -= delta
        if corrosion_tick <= 0.0:
            corrosion_tick = 0.75
            take_damage(0.8 * corrosion_power, status_source)

func _status_move_multiplier() -> float:
    return 0.68 if frost_time > 0.0 else 1.0

func _chain_electric(chain_damage: float, source: Node) -> void:
    var nearest: Node2D
    var nearest_distance := 145.0
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if candidate == self or not is_instance_valid(candidate) or not candidate is Node2D:
            continue
        var distance := global_position.distance_to(candidate.global_position)
        if distance < nearest_distance:
            nearest = candidate
            nearest_distance = distance
    if nearest != null and nearest.has_method("take_damage"):
        if nearest.take_damage(chain_damage, source):
            GameManager.register_damage(chain_damage)
            EventBus.projectile_hit.emit({"damage": chain_damage, "target": nearest, "source": source, "effect": "electric_chain"})

func _draw() -> void:
    var role := String(data.get("role", "melee"))
    var base_color := Color("ff8d66") if role == "melee" else Color("c48cff")
    if frost_time > 0.0:
        base_color = base_color.lerp(Color("75dbff"), 0.48)
    elif corrosion_time > 0.0:
        base_color = base_color.lerp(Color("8ee06f"), 0.38)
    elif fire_time > 0.0:
        base_color = base_color.lerp(Color("ffad5c"), 0.42)
    draw_circle(Vector2.ZERO, float(data.get("visual_radius", 16.0)), base_color)
    draw_circle(Vector2.ZERO, 7.0, Color("24171b"))

    if fire_time > 0.0:
        draw_arc(Vector2.ZERO, 21.0, 0.0, TAU, 20, Color("ff8b45"), 2.0)
    if frost_time > 0.0:
        draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 20, Color("72e2ff"), 2.0)
    if corrosion_time > 0.0:
        draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 20, Color("84df61"), 2.0)

    if telegraph_left > 0.0 and is_instance_valid(player):
        var local_target := to_local(player.global_position)
        draw_line(Vector2.ZERO, local_target.normalized() * minf(local_target.length(), 150.0), Color(1.0, 0.25, 0.25, 0.8), 2.0, true)
        draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 28, Color("ff424f"), 3.0)
