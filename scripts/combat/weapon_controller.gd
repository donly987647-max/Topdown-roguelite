extends Node

const ProjectileScript = preload("res://scripts/combat/projectile.gd")
const DATA_PATH := "res://data/weapons/service_pistol.json"

var actor: Node2D
var data: Dictionary = {}
var ammo_in_mag := 0
var reserve_ammo := 0
var fire_cooldown := 0.0
var reloading := false
var reload_elapsed := 0.0
var perfect_reload_armed := true
var next_mag_damage_multiplier := 1.0

func configure(owner_actor: Node2D) -> void:
    actor = owner_actor
    data = _load_json(DATA_PATH)
    ammo_in_mag = int(data.get("magazine_size", 8))
    reserve_ammo = int(data.get("reserve_ammo", 72))

func tick(delta: float, aim_direction: Vector2, mobile_fire_held: bool = false) -> void:
    fire_cooldown = maxf(0.0, fire_cooldown - delta)

    if reloading:
        reload_elapsed += delta
        if reload_elapsed >= float(data.get("reload_time", 1.25)):
            _finish_reload(false)
        return

    var gamepad_fire := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.35
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or gamepad_fire or mobile_fire_held:
        _try_fire(aim_direction)

    if ammo_in_mag <= 0 and reserve_ammo > 0:
        _start_reload()

func request_reload() -> void:
    if reloading:
        var duration := float(data.get("reload_time", 1.25))
        var progress := reload_elapsed / maxf(duration, 0.001)
        var window_start := float(data.get("perfect_reload_start", 0.55))
        var window_end := float(data.get("perfect_reload_end", 0.72))
        if perfect_reload_armed and progress >= window_start and progress <= window_end:
            perfect_reload_armed = false
            next_mag_damage_multiplier = float(data.get("perfect_reload_damage_multiplier", 1.15))
            EventBus.perfect_reload.emit({"weapon_id": data.get("id", "service_pistol"), "progress": progress})
            _finish_reload(true)
        return

    if ammo_in_mag < int(data.get("magazine_size", 8)) and reserve_ammo > 0:
        _start_reload()

func cancel_reload() -> void:
    if not reloading:
        return
    reloading = false
    reload_elapsed = 0.0
    perfect_reload_armed = true

func get_reload_progress() -> float:
    if not reloading:
        return 0.0
    return clampf(reload_elapsed / maxf(float(data.get("reload_time", 1.25)), 0.001), 0.0, 1.0)

func get_perfect_window() -> Vector2:
    return Vector2(float(data.get("perfect_reload_start", 0.55)), float(data.get("perfect_reload_end", 0.72)))

func _try_fire(direction: Vector2) -> void:
    if fire_cooldown > 0.0 or ammo_in_mag <= 0 or actor == null:
        return

    ammo_in_mag -= 1
    fire_cooldown = 1.0 / maxf(float(data.get("fire_rate", 4.5)), 0.01)

    var projectile := ProjectileScript.new()
    actor.get_tree().current_scene.add_child(projectile)
    var damage := float(data.get("damage", 18.0)) * next_mag_damage_multiplier
    projectile.setup(actor.global_position + direction * 24.0, direction, float(data.get("projectile_speed", 950.0)), damage, true, actor)
    EventBus.shot_fired.emit({"weapon_id": data.get("id", "service_pistol"), "ammo": ammo_in_mag})

func _start_reload() -> void:
    reloading = true
    reload_elapsed = 0.0
    perfect_reload_armed = true
    EventBus.reload_started.emit({"weapon_id": data.get("id", "service_pistol")})

func _finish_reload(perfect: bool) -> void:
    var mag_size := int(data.get("magazine_size", 8))
    var needed := mag_size - ammo_in_mag
    var loaded := mini(needed, reserve_ammo)
    ammo_in_mag += loaded
    reserve_ammo -= loaded
    reloading = false
    reload_elapsed = 0.0
    perfect_reload_armed = true
    if not perfect:
        next_mag_damage_multiplier = 1.0
    EventBus.reload_completed.emit({"weapon_id": data.get("id", "service_pistol"), "perfect": perfect, "ammo": ammo_in_mag})

func _load_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Dictionary else {}
