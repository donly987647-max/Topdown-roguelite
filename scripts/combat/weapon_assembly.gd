extends RefCounted

const CATALOG_PATH := "res://data/weapons/weapon_catalog.json"

var catalog: Dictionary = {}
var selections := {
    "frame": 0,
    "barrel": 0,
    "magazine": 0,
    "core": 0,
}

func _init() -> void:
    catalog = _load_json(CATALOG_PATH)

func cycle(slot: String, delta: int) -> void:
    var key := _catalog_key(slot)
    if key.is_empty():
        return
    var entries: Array = catalog.get(key, [])
    if entries.is_empty():
        return
    selections[slot] = posmod(int(selections.get(slot, 0)) + delta, entries.size())

func get_selected(slot: String) -> Dictionary:
    var key := _catalog_key(slot)
    var entries: Array = catalog.get(key, [])
    if entries.is_empty():
        return {}
    var index := clampi(int(selections.get(slot, 0)), 0, entries.size() - 1)
    var value = entries[index]
    return value.duplicate(true) if value is Dictionary else {}

func get_selected_name(slot: String) -> String:
    return String(get_selected(slot).get("name", slot.to_upper()))

func resolve() -> Dictionary:
    var frame := get_selected("frame")
    var barrel := get_selected("barrel")
    var magazine := get_selected("magazine")
    var core := get_selected("core")

    var result := frame.duplicate(true)
    result["frame_id"] = frame.get("id", "service_pistol")
    result["barrel_id"] = barrel.get("id", "precision")
    result["magazine_id"] = magazine.get("id", "large")
    result["core_id"] = core.get("id", "fire")

    result["projectile_count"] = 1
    result["damage_multiplier"] = 1.0
    result["projectile_speed_multiplier"] = 1.0
    result["fire_interval_multiplier"] = 1.0
    result["spread_multiplier"] = 1.0
    result["pierce_count"] = 0
    result["pierce_damage_decay"] = 0.0
    result["ricochet_count"] = 0
    result["ricochet_damage_multiplier"] = 1.0
    result["explosive_last_round"] = false
    result["reverse_magazine"] = false
    result["effect"] = String(core.get("id", ""))
    result["effect_strength"] = 1.0

    match String(barrel.get("id", "")):
        "precision":
            result["spread_multiplier"] = 0.65
            result["projectile_speed_multiplier"] = 1.15
            result["fire_interval_multiplier"] = 1.0 / 0.92
        "scatter":
            result["projectile_count"] = 3
            result["damage_multiplier"] = 0.75
            result["spread_multiplier"] = 2.2
        "piercing":
            result["pierce_count"] = 2
            result["pierce_damage_decay"] = 0.15
        "ricochet":
            result["ricochet_count"] = 2
            result["ricochet_damage_multiplier"] = 1.20
            result["projectile_speed_multiplier"] = 0.90

    match String(magazine.get("id", "")):
        "large":
            result["magazine_size"] = maxi(1, int(round(float(result.get("magazine_size", 10)) * 1.60)))
            result["reload_time"] = float(result.get("reload_time", 1.2)) * 1.25
        "light":
            result["magazine_size"] = maxi(1, int(round(float(result.get("magazine_size", 10)) * 0.75)))
            result["reload_time"] = float(result.get("reload_time", 1.2)) * 0.65
        "explosive":
            result["magazine_size"] = maxi(2, int(round(float(result.get("magazine_size", 10)) * 0.80)))
            result["explosive_last_round"] = true
        "reverse":
            result["reverse_magazine"] = true

    var total_power := float(barrel.get("power", 0.0)) + float(magazine.get("power", 0.0)) + float(core.get("power", 0.0))
    var total_weight := float(barrel.get("weight", 0.0)) + float(magazine.get("weight", 0.0)) + float(core.get("weight", 0.0))
    var max_power := maxf(float(frame.get("max_power", 10.0)), 0.01)
    var max_weight := maxf(float(frame.get("max_weight", 10.0)), 0.01)
    var power_over := maxf(0.0, total_power - max_power)
    var weight_over := maxf(0.0, total_weight - max_weight)
    var power_ratio := power_over / max_power
    var weight_ratio := weight_over / max_weight

    result["total_power"] = total_power
    result["total_weight"] = total_weight
    result["power_overload"] = power_over
    result["weight_overload"] = weight_over
    result["reload_time"] = float(result.get("reload_time", 1.2)) * (1.0 + power_ratio * 0.45)
    result["misfire_chance"] = minf(0.18, power_ratio * 0.12)
    result["movement_multiplier"] = maxf(0.70, 1.0 - weight_ratio * 0.22)
    result["dodge_distance_multiplier"] = maxf(0.72, 1.0 - weight_ratio * 0.20)

    var stability := clampf(float(frame.get("stability", 80.0)), 0.0, 100.0)
    result["spread_deg"] = float(result.get("spread_deg", 3.0)) * float(result.get("spread_multiplier", 1.0)) * (1.0 + (100.0 - stability) / 250.0)
    result["projectile_speed"] = float(result.get("projectile_speed", 900.0)) * float(result.get("projectile_speed_multiplier", 1.0))
    result["fire_interval"] = float(result.get("fire_interval", 0.2)) * float(result.get("fire_interval_multiplier", 1.0))
    result["damage"] = float(result.get("damage", 10.0)) * float(result.get("damage_multiplier", 1.0))

    return result

func get_summary() -> Dictionary:
    var r := resolve()
    return {
        "frame": get_selected_name("frame"),
        "barrel": get_selected_name("barrel"),
        "magazine": get_selected_name("magazine"),
        "core": get_selected_name("core"),
        "damage": r.get("damage", 0.0),
        "fire_interval": r.get("fire_interval", 0.0),
        "magazine_size": r.get("magazine_size", 0),
        "reload_time": r.get("reload_time", 0.0),
        "power": r.get("total_power", 0.0),
        "max_power": r.get("max_power", 0.0),
        "weight": r.get("total_weight", 0.0),
        "max_weight": r.get("max_weight", 0.0),
        "power_overload": r.get("power_overload", 0.0),
        "weight_overload": r.get("weight_overload", 0.0),
    }

func _catalog_key(slot: String) -> String:
    match slot:
        "frame": return "frames"
        "barrel": return "barrels"
        "magazine": return "magazines"
        "core": return "cores"
        _: return ""

func _load_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Dictionary else {}
