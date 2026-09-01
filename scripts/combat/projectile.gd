extends Node2D

var direction := Vector2.RIGHT
var speed := 900.0
var damage := 10.0
var friendly := true
var source: Node
var lifetime := 0.0
var max_lifetime := 1.8
var pierce_left := 0
var pierce_damage_decay := 0.0
var ricochet_left := 0
var ricochet_damage_multiplier := 1.0
var effect := ""
var effect_strength := 1.0
var explosion_radius := 0.0
var explosion_damage_multiplier := 0.6
var hit_rids: Array[RID] = []

func setup(origin: Vector2, dir: Vector2, projectile_speed: float, projectile_damage: float, is_friendly: bool, shooter: Node, config: Dictionary = {}) -> void:
    global_position = origin
    direction = dir.normalized()
    speed = projectile_speed
    damage = projectile_damage
    friendly = is_friendly
    source = shooter
    pierce_left = int(config.get("pierce_count", 0))
    pierce_damage_decay = float(config.get("pierce_damage_decay", 0.0))
    ricochet_left = int(config.get("ricochet_count", 0))
    ricochet_damage_multiplier = float(config.get("ricochet_damage_multiplier", 1.0))
    effect = String(config.get("effect", ""))
    effect_strength = float(config.get("effect_strength", 1.0))
    explosion_radius = float(config.get("explosion_radius", 0.0))
    explosion_damage_multiplier = float(config.get("explosion_damage_multiplier", 0.6))
    z_index = 5
    queue_redraw()

func _physics_process(delta: float) -> void:
    lifetime += delta
    if lifetime >= max_lifetime:
        if explosion_radius > 0.0:
            _explode(global_position, RID())
        queue_free()
        return

    var next_position := global_position + direction * speed * delta
    var query := PhysicsRayQueryParameters2D.create(global_position, next_position)
    query.collision_mask = (2 | 4) if friendly else (1 | 4)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    var excluded: Array[RID] = hit_rids.duplicate()
    if is_instance_valid(source) and source is CollisionObject2D:
        excluded.append(source.get_rid())
    query.exclude = excluded

    var hit := get_world_2d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        global_position = next_position
        return

    global_position = hit.position
    var collider = hit.get("collider")
    var collider_rid: RID = hit.get("rid", RID())
    var accepted := false
    if collider != null and collider.has_method("take_damage"):
        accepted = bool(collider.take_damage(damage, source))
        if accepted and friendly:
            GameManager.register_damage(damage)
            EventBus.projectile_hit.emit({"damage": damage, "target": collider, "source": source, "effect": effect})
            if collider.has_method("apply_weapon_effect") and not effect.is_empty():
                collider.apply_weapon_effect(effect, effect_strength, damage, source)
        if explosion_radius > 0.0:
            _explode(global_position, collider_rid)
            queue_free()
            return
        if accepted and pierce_left > 0:
            pierce_left -= 1
            damage *= maxf(0.0, 1.0 - pierce_damage_decay)
            if collider_rid.is_valid():
                hit_rids.append(collider_rid)
            global_position += direction * 3.0
            return
        queue_free()
        return

    if ricochet_left > 0:
        var normal: Vector2 = hit.get("normal", Vector2.ZERO)
        if normal.length_squared() > 0.01:
            direction = direction.bounce(normal).normalized()
            ricochet_left -= 1
            damage *= ricochet_damage_multiplier
            global_position += direction * 3.0
            queue_redraw()
            return

    if explosion_radius > 0.0:
        _explode(global_position, RID())
    queue_free()

func _explode(position: Vector2, ignored_rid: RID) -> void:
    if not friendly or explosion_radius <= 0.0:
        return
    var shape := CircleShape2D.new()
    shape.radius = explosion_radius
    var params := PhysicsShapeQueryParameters2D.new()
    params.shape = shape
    params.transform = Transform2D(0.0, position)
    params.collision_mask = 2
    params.collide_with_bodies = true
    params.collide_with_areas = false
    var results := get_world_2d().direct_space_state.intersect_shape(params, 24)
    for item in results:
        var body = item.get("collider")
        var rid: RID = item.get("rid", RID())
        if ignored_rid.is_valid() and rid == ignored_rid:
            continue
        if body != null and body.has_method("take_damage"):
            var explosion_damage := damage * explosion_damage_multiplier
            if body.take_damage(explosion_damage, source):
                GameManager.register_damage(explosion_damage)
                EventBus.projectile_hit.emit({"damage": explosion_damage, "target": body, "source": source, "effect": "explosion"})

func _draw() -> void:
    var color := Color("ffe08a") if friendly else Color("ff5b66")
    if friendly:
        match effect:
            "fire": color = Color("ff9d57")
            "frost": color = Color("7ee7ff")
            "electric": color = Color("e3db5f")
            "corrosion": color = Color("8ee06f")
    draw_line(-direction * 7.0, direction * 7.0, color, 4.0, true)
    draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
    if explosion_radius > 0.0:
        draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 12, Color(color, 0.55), 2.0)
