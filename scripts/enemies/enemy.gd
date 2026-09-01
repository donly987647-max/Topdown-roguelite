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
    var move_speed := float(data.get("move_speed", 170.0))
    velocity = offset.normalized() * move_speed if distance > 30.0 else Vector2.ZERO

    if distance <= float(data.get("attack_range", 34.0)) and attack_cooldown <= 0.0:
        _begin_telegraph()

func _ranged_ai(delta: float) -> void:
    var offset := player.global_position - global_position
    var distance := offset.length()
    var preferred := float(data.get("preferred_range", 280.0))
    var move_speed := float(data.get("move_speed", 120.0))
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
    hp -= amount
    if hp <= 0.0:
        dead = true
        GameManager.register_enemy_kill()
        EventBus.enemy_killed.emit({"enemy_id": data.get("id", "enemy"), "position": global_position, "source": source})
        remove_from_group("enemies")
        queue_free()
    else:
        queue_redraw()
    return true

func _draw() -> void:
    var role := String(data.get("role", "melee"))
    var base_color := Color("ff8d66") if role == "melee" else Color("c48cff")
    draw_circle(Vector2.ZERO, float(data.get("visual_radius", 16.0)), base_color)
    draw_circle(Vector2.ZERO, 7.0, Color("24171b"))

    if telegraph_left > 0.0 and is_instance_valid(player):
        var local_target := to_local(player.global_position)
        draw_line(Vector2.ZERO, local_target.normalized() * minf(local_target.length(), 150.0), Color(1.0, 0.25, 0.25, 0.8), 2.0, true)
        draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 28, Color("ff424f"), 3.0)
