class_name WeaponBuild
extends Resource

@export var frame: WeaponFrameDefinition
@export var barrel: WeaponPartDefinition
@export var magazine: WeaponPartDefinition
@export var core: WeaponPartDefinition

func is_complete() -> bool:
	return frame != null and barrel != null and magazine != null and core != null

func total_power_cost() -> float:
	return _sum_part_float(&"power_cost")

func total_weight() -> float:
	return _sum_part_float(&"weight")

func power_overload_ratio() -> float:
	if frame == null or frame.max_power <= 0.0:
		return 0.0
	return maxf(0.0, total_power_cost() / frame.max_power - 1.0)

func weight_overload_ratio() -> float:
	if frame == null or frame.max_weight <= 0.0:
		return 0.0
	return maxf(0.0, total_weight() / frame.max_weight - 1.0)

func overload_ratio() -> float:
	return maxf(power_overload_ratio(), weight_overload_ratio())

func is_overloaded() -> bool:
	return overload_ratio() > 0.0

func is_compatible() -> bool:
	if not is_complete():
		return false
	for part in [barrel, magazine, core]:
		if part.compatible_tags.is_empty():
			continue
		var matched := false
		for tag in part.compatible_tags:
			if frame.compatibility_tags.has(tag):
				matched = true
				break
		if not matched:
			return false
	return true

func computed_stats() -> Dictionary:
	if frame == null:
		return {}
	var stats := {
		"damage": frame.base_damage,
		"fire_interval": frame.fire_interval,
		"magazine_size": frame.magazine_size,
		"reload_time": frame.reload_time,
		"stability": frame.stability,
		"uses_heat": frame.uses_heat,
		"heat_per_shot": frame.heat_per_shot,
		"ammo_type": frame.ammo_type,
		"special_rule": frame.special_rule,
		"power_cost": total_power_cost(),
		"weight": total_weight(),
		"power_overload_ratio": power_overload_ratio(),
		"weight_overload_ratio": weight_overload_ratio(),
		"overload_ratio": overload_ratio(),
	}
	for part in [barrel, magazine, core]:
		if part == null:
			continue
		for key in part.modifiers.keys():
			_apply_modifier(stats, StringName(key), part.modifiers[key])
	var overload := overload_ratio()
	if overload > 0.0:
		stats["stability"] = maxf(0.05, float(stats["stability"]) / (1.0 + overload * 1.25))
		stats["heat_per_shot"] = float(stats["heat_per_shot"]) * (1.0 + overload * 1.5)
		stats["reload_time"] = float(stats["reload_time"]) * (1.0 + overload * 0.5)
	return stats

func effect_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for part in [barrel, magazine, core]:
		if part == null:
			continue
		for effect_id in part.effect_ids:
			var id := StringName(effect_id)
			if not result.has(id):
				result.append(id)
	return result

func tag_set() -> Dictionary:
	var tags := {}
	if frame != null:
		for tag in frame.compatibility_tags:
			tags[StringName(tag)] = true
	for part in [barrel, magazine, core]:
		if part == null:
			continue
		for tag in part.tags:
			tags[StringName(tag)] = true
	return tags

func _apply_modifier(stats: Dictionary, key: StringName, value: Variant) -> void:
	if value is Dictionary:
		var op := String(value.get("op", "add"))
		var amount: Variant = value.get("value", 0.0)
		if op == "mul":
			stats[key] = float(stats.get(key, 1.0)) * float(amount)
		elif op == "set":
			stats[key] = amount
		else:
			stats[key] = float(stats.get(key, 0.0)) + float(amount)
	elif value is float or value is int:
		stats[key] = float(stats.get(key, 0.0)) + float(value)
	else:
		stats[key] = value

func _sum_part_float(property_name: StringName) -> float:
	var total := 0.0
	for part in [barrel, magazine, core]:
		if part != null:
			total += float(part.get(property_name))
	return total
