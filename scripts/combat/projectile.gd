extends Node2D

var direction := Vector2.RIGHT
var speed := 900.0
var damage := 10.0
var friendly := true
var source: Node
var lifetime := 0.0
var max_lifetime := 1.8

func setup(origin: Vector2, dir: Vector2, projectile_speed: float, projectile_damage: float, is_friendly: bool, shooter: Node) -> void:
    global_position = origin
    direction = dir.normalized()
    speed = projectile_speed
    damage = projectile_damage
    friendly = is_friendly
    source = shooter
    z_index = 5
    queue_redraw()

func _physics_process(delta: float) -> void:
    lifetime += delta
    if lifetime >= max_lifetime:
        queue_free()
        return

    var next_position := global_position + direction * speed * delta
    var query := PhysicsRayQueryParameters2D.create(global_position, next_position)
    query.collision_mask = (2 | 4) if friendly else (1 | 4)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    if is_instance_valid(source) and source is CollisionObject2D:
        query.exclude = [source.get_rid()]

    var hit := get_world_2d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        global_position = hit.position
        var collider = hit.get("collider")
        if collider != null and collider.has_method("take_damage"):
            var accepted: bool = collider.take_damage(damage, source)
            if accepted and friendly:
                GameManager.register_damage(damage)
                EventBus.projectile_hit.emit({"damage": damage, "target": collider, "source": source})
        queue_free()
        return

    global_position = next_position

func _draw() -> void:
    var color := Color("ffe08a") if friendly else Color("ff5b66")
    draw_line(-direction * 7.0, direction * 7.0, color, 4.0, true)
    draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
