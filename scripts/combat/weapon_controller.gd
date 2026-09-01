extends Node

const ProjectileScript = preload("res://scripts/combat/projectile.gd")
const WeaponAssemblyScript = preload("res://scripts/combat/weapon_assembly.gd")

var actor: Node2D
var assembly
var data: Dictionary = {}
var ammo_in_mag := 0
var reserve_ammo := 0
var fire_cooldown := 0.0
var reloading := false
var reload_elapsed := 0.0
var perfect_reload_armed := true
var next_shot_damage_multiplier := 1.0
var burst_remaining := 0
var burst_gap_left := 0.0
var chain_hits := 0
var chain_hit_decay := 0.0
var shots_since_reload := 0

func configure(owner_actor: Node2D) -> void:
    actor = owner_actor
    assembly = WeaponAssemblyScript.new()
    data = assembly.resolve()
    ammo_in_mag = int(data.get("magazine_size", 10))
    reserve_ammo = ammo_in_mag * 9
    EventBus.projectile_hit.connect(_on_projectile_hit)

func tick(delta: float, aim_direction: Vector2, mobile_fire_held: bool = false) -> void:
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    burst_gap_left = maxf(0.0, burst_gap_left - delta)
    chain_hit_decay = maxf(0.0, chain_hit_decay - delta)
    if chain_hit_decay <= 0.0:
        chain_hits = 0

    if reloading:
        reload_elapsed += delta
        if reload_elapsed >= float(data.get("reload_time", 1.25)):
            _finish_reload(false)
        return

    if burst_remaining > 0 and burst_gap_left <= 0.0:
        _fire_trigger(aim_direction, true)
        burst_remaining -= 1
        if burst_remaining > 0:
            burst_gap_left = float(data.get("burst_interval", 0.08))
        else:
            fire_cooldown = float(data.get("post_burst_delay", 0.32))

    var gamepad_fire := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.35
    var fire_held := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or gamepad_fire or mobile_fire_held
    if fire_held and burst_remaining <= 0:
        if String(data.get("mode", "semi")) == "burst":
            if fire_cooldown <= 0.0:
                burst_remaining = mini(int(data.get("burst_count", 3)), ammo_in_mag)
                burst_gap_left = 0.0
        else:
            _try_fire(aim_direction)

    if ammo_in_mag <= 0 and reserve_ammo > 0 and burst_remaining <= 0:
        _start_reload()

func request_reload() -> void:
    if reloading:
        var duration := float(data.get("reload_time", 1.25))
        var progress := reload_elapsed / maxf(duration, 0.001)
        var window_start := 0.55
        var window_end := 0.72
        if perfect_reload_armed and progress >= window_start and progress <= window_end:
            perfect_reload_armed = false
            next_shot_damage_multiplier = 1.15
            if String(data.get("frame_id", "")) == "service_pistol":
                next_shot_damage_multiplier = 1.75
            EventBus.perfect_reload.emit({"weapon_id": data.get("frame_id", "service_pistol"), "progress": progress})
            _finish_reload(true)
        return

    if ammo_in_mag < int(data.get("magazine_size", 10)) and reserve_ammo > 0:
        _start_reload()

func cancel_reload() -> void:
    if not reloading:
        return
    reloading = false
    reload_elapsed = 0.0
    perfect_reload_armed = true

func cycle_part(slot: String, delta: int) -> void:
    if assembly == null:
        return
    assembly.cycle(slot, delta)
    _apply_build()

func get_build_summary() -> Dictionary:
    return assembly.get_summary() if assembly != null else {}

func get_selected_name(slot: String) -> String:
    return assembly.get_selected_name(slot) if assembly != null else slot.to_upper()

func get_display_name() -> String:
    return String(data.get("name", "SERVICE PISTOL"))

func get_movement_multiplier() -> float:
    return float(data.get("movement_multiplier", 1.0))

func get_dodge_distance_multiplier() -> float:
    return float(data.get("dodge_distance_multiplier", 1.0))

func get_reload_progress() -> float:
    if not reloading:
        return 0.0
    return clampf(reload_elapsed / maxf(float(data.get("reload_time", 1.25)), 0.001), 0.0, 1.0)

func get_perfect_window() -> Vector2:
    return Vector2(0.55, 0.72)

func _try_fire(direction: Vector2) -> void:
    if fire_cooldown > 0.0 or ammo_in_mag <= 0 or actor == null:
        return
    _fire_trigger(direction, false)
    var interval := float(data.get("fire_interval", 0.24))
    if String(data.get("frame_id", "")) == "chain_smg":
        var speedup := minf(float(data.get("chain_hit_speedup_cap", 0.36)), chain_hits * float(data.get("chain_hit_speedup", 0.04)))
        interval *= 1.0 - speedup
    fire_cooldown = maxf(0.025, interval)

func _fire_trigger(direction: Vector2, from_burst: bool) -> void:
    if ammo_in_mag <= 0 or actor == null:
        burst_remaining = 0
        return

    var ammo_cost := 1
    ammo_in_mag -= ammo_cost
    shots_since_reload += 1

    if randf() < float(data.get("misfire_chance", 0.0)):
        EventBus.shot_fired.emit({"weapon_id": data.get("frame_id", "weapon"), "ammo": ammo_in_mag, "misfire": true})
        return

    var base_damage := float(data.get("damage", 10.0)) * next_shot_damage_multiplier
    next_shot_damage_multiplier = 1.0
    if bool(data.get("reverse_magazine", false)):
        base_damage *= maxf(0.72, 1.18 - 0.03 * float(shots_since_reload - 1))

    var projectile_count := int(data.get("projectile_count", 1))
    var spread_deg := float(data.get("spread_deg", 2.0))
    for i in projectile_count:
        var offset := 0.0
        if projectile_count > 1:
            var t := float(i) / float(maxi(1, projectile_count - 1))
            offset = lerpf(-spread_deg, spread_deg, t)
        elif spread_deg > 0.01:
            offset = randf_range(-spread_deg, spread_deg)
        _spawn_projectile(direction.rotated(deg_to_rad(offset)), base_damage)

    EventBus.shot_fired.emit({
        "weapon_id": data.get("frame_id", "weapon"),
        "ammo": ammo_in_mag,
        "burst": from_burst,
        "barrel": data.get("barrel_id", ""),
        "magazine": data.get("magazine_id", ""),
        "core": data.get("core_id", ""),
    })

func _spawn_projectile(direction: Vector2, projectile_damage: float) -> void:
    var projectile := ProjectileScript.new()
    actor.get_tree().current_scene.add_child(projectile)
    var projectile_config := {
        "pierce_count": int(data.get("pierce_count", 0)),
        "pierce_damage_decay": float(data.get("pierce_damage_decay", 0.0)),
        "ricochet_count": int(data.get("ricochet_count", 0)),
        "ricochet_damage_multiplier": float(data.get("ricochet_damage_multiplier", 1.0)),
        "effect": String(data.get("effect", "")),
        "effect_strength": float(data.get("effect_strength", 1.0)),
        "explosion_radius": 78.0 if bool(data.get("explosive_last_round", false)) and ammo_in_mag <= 0 else 0.0,
        "explosion_damage_multiplier": 0.60,
    }
    projectile.setup(actor.global_position + direction * 24.0, direction, float(data.get("projectile_speed", 950.0)), projectile_damage, true, actor, projectile_config)

func _start_reload() -> void:
    if reloading or reserve_ammo <= 0:
        return
    reloading = true
    burst_remaining = 0
    reload_elapsed = 0.0
    perfect_reload_armed = true
    EventBus.reload_started.emit({"weapon_id": data.get("frame_id", "weapon")})

func _finish_reload(perfect: bool) -> void:
    var mag_size := int(data.get("magazine_size", 10))
    var needed := mag_size - ammo_in_mag
    var loaded := mini(needed, reserve_ammo)
    ammo_in_mag += loaded
    reserve_ammo -= loaded
    reloading = false
    reload_elapsed = 0.0
    perfect_reload_armed = true
    shots_since_reload = 0
    if not perfect:
        next_shot_damage_multiplier = 1.0
    EventBus.reload_completed.emit({"weapon_id": data.get("frame_id", "weapon"), "perfect": perfect, "ammo": ammo_in_mag})

func _apply_build() -> void:
    var previous_mag := int(data.get("magazine_size", 10))
    var previous_ammo := ammo_in_mag
    data = assembly.resolve()
    var new_mag := int(data.get("magazine_size", 10))
    ammo_in_mag = mini(previous_ammo, new_mag)
    if previous_mag <= 0:
        ammo_in_mag = new_mag
    reloading = false
    burst_remaining = 0
    fire_cooldown = 0.15
    shots_since_reload = 0
    chain_hits = 0
    EventBus.weapon_build_changed.emit({"summary": assembly.get_summary()})

func _on_projectile_hit(payload: Dictionary) -> void:
    if String(data.get("frame_id", "")) != "chain_smg":
        return
    if payload.get("source") != actor:
        return
    chain_hits = mini(chain_hits + 1, 12)
    chain_hit_decay = 0.70
