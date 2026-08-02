class_name WeaponPartCatalog
extends RefCounted

const DATA_PATHS := {
	WeaponPartDefinition.PartType.BARREL: "res://data/weapons/barrels.json",
	WeaponPartDefinition.PartType.MAGAZINE: "res://data/weapons/magazines.json",
	WeaponPartDefinition.PartType.CORE: "res://data/weapons/cores.json",
}

var _data_cache: Dictionary = {}
var _part_cache: Dictionary = {}

func get_part(id: StringName, part_type: WeaponPartDefinition.PartType) -> WeaponPartDefinition:
	var cache_key := "%d:%s" % [part_type, String(id)]
	if _part_cache.has(cache_key):
		return _part_cache[cache_key]
	var data := _load_data(part_type)
	var raw_value: Variant = data.get(String(id), {})
	if not (raw_value is Dictionary) or raw_value.is_empty():
		return null
	var raw := raw_value as Dictionary
	var effects_value: Variant = raw.get("effects", {})
	var effects: Dictionary = effects_value if effects_value is Dictionary else {}
	var part := WeaponPartDefinition.new()
	part.id = id
	part.display_name = String(raw.get("name", String(id)))
	part.part_type = part_type
	part.description = _description_from_effects(effects)
	part.power_cost = _default_power_cost(id, part_type)
	part.weight = _default_weight(id, part_type)
	part.tags = _tags_for(id, part_type, effects)
	part.modifiers = _modifiers_from_effects(effects)
	part.effect_ids = _effect_ids(effects)
	_part_cache[cache_key] = part
	return part

func get_for_category(id: StringName, category: StringName) -> WeaponPartDefinition:
	match category:
		&"barrel": return get_part(id, WeaponPartDefinition.PartType.BARREL)
		&"magazine": return get_part(id, WeaponPartDefinition.PartType.MAGAZINE)
		&"core": return get_part(id, WeaponPartDefinition.PartType.CORE)
	return null

func _load_data(part_type: WeaponPartDefinition.PartType) -> Dictionary:
	if _data_cache.has(part_type):
		return _data_cache[part_type]
	var path := String(DATA_PATHS.get(part_type, ""))
	if path.is_empty():
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	var result: Dictionary = parsed if parsed is Dictionary else {}
	_data_cache[part_type] = result
	return result

func _modifiers_from_effects(effects: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	_copy_multiplier(effects, result, "damage_mult", "damage")
	_copy_multiplier(effects, result, "magazine_mult", "magazine_size")
	_copy_multiplier(effects, result, "reload_time_mult", "reload_time")
	_copy_multiplier(effects, result, "projectile_speed_mult", "projectile_speed")
	if effects.has("fire_rate_mult"):
		var fire_rate := maxf(0.01, float(effects["fire_rate_mult"]))
		result["fire_interval"] = {"op": "mul", "value": 1.0 / fire_rate}
	if effects.has("projectile_count_add"):
		result["projectile_count"] = {"op": "add", "value": int(effects["projectile_count_add"])}
	return result

func _copy_multiplier(effects: Dictionary, target: Dictionary, source_key: String, stat_key: String) -> void:
	if effects.has(source_key):
		target[stat_key] = {"op": "mul", "value": float(effects[source_key])}

func _effect_ids(effects: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()
	for key in effects.keys():
		var value: Variant = effects[key]
		if value is bool and not value:
			continue
		result.append(String(key))
	return result

func _tags_for(id: StringName, part_type: WeaponPartDefinition.PartType, effects: Dictionary) -> PackedStringArray:
	var result := PackedStringArray([_category_name(part_type)])
	var text := String(id).to_lower()
	for tag in ["fire", "cooling", "electric", "corrosion", "bleed", "void", "impact", "absorption", "photon", "explosive", "precision", "ammo"]:
		if tag in text and tag not in result:
			result.append(tag)
	var status_value: Variant = effects.get("status", "")
	var status := String(status_value)
	if not status.is_empty() and status not in result:
		result.append(status)
	return result

func _category_name(part_type: WeaponPartDefinition.PartType) -> String:
	match part_type:
		WeaponPartDefinition.PartType.BARREL: return "barrel"
		WeaponPartDefinition.PartType.MAGAZINE: return "magazine"
		WeaponPartDefinition.PartType.CORE: return "core"
	return "part"

func _default_power_cost(id: StringName, part_type: WeaponPartDefinition.PartType) -> float:
	if id == &"void_core":
		return 28.0
	match part_type:
		WeaponPartDefinition.PartType.BARREL: return 12.0
		WeaponPartDefinition.PartType.MAGAZINE: return 8.0
		WeaponPartDefinition.PartType.CORE: return 16.0
	return 10.0

func _default_weight(id: StringName, part_type: WeaponPartDefinition.PartType) -> float:
	if id in [&"extended_mag", &"compressed_mag", &"impact_core"]:
		return 14.0
	match part_type:
		WeaponPartDefinition.PartType.BARREL: return 10.0
		WeaponPartDefinition.PartType.MAGAZINE: return 8.0
		WeaponPartDefinition.PartType.CORE: return 6.0
	return 8.0

func _description_from_effects(effects: Dictionary) -> String:
	var labels: Array[String] = []
	for key in effects.keys():
		labels.append(String(key).replace("_", " "))
	return ", ".join(labels)
