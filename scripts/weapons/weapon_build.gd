class_name WeaponBuild
extends Resource

const INCOMPATIBLE_POWER_SURCHARGE_RATE := 0.25

@export var frame: WeaponFrameDefinition
@export var barrel: WeaponPartDefinition
@export var magazine: WeaponPartDefinition
@export var core: WeaponPartDefinition
@export_range(0.0, 1.0, 0.05) var compatibility_penalty_scale: float = 1.0

func is_complete() -> bool:
	return frame != null and barrel != null and magazine != null and core != null

func base_power_cost() -> float:
	return _sum_part_float(&"power_cost")

func incompatible_part_count() -> int:
	if frame == null:
		return 0
	var count := 0
	for part in [barrel, magazine, core]:
		if part != null and not _part_matches_frame(part):
			count += 1
	return count

func incompatible_power_surcharge() -> float:
	if frame == null:
		return 0.0
	var surcharge := 0.0
	for part in [barrel, magazine, core]:
		if part == null or _part_matches_frame(part):
			continue
		surcharge += float(part.power_cost) * INCOMPATIBLE_POWER_SURCHARGE_RATE * clampf(compatibility_penalty_scale, 0.0, 1.0)
	return surcharge

func total_power_cost() -> float:
	return base_power_cost() + incompatible_power_surcharge()

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

# GDD 14/25: incompatible parts are legal; they pay an additional power cost.
# Keep this method as the assembly legality contract used by WeaponController.
func is_compatible() -> bool:
	return is_complete()

func is_tag_compatible() -> bool:
	return is_complete() and incompatible_part_count() == 0

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
		"base_power_cost": base_power_cost(),
		"power_cost": total_power_cost(),
		"incompatible_part_count": incompatible_part_count(),
		"incompatible_power_surcharge": incompatible_power_surcharge(),
		"compatibility_penalty_scale": compatibility_penalty_scale,
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

func _part_matches_frame(part: WeaponPartDefinition) -> bool:
	if part == null or part.compatible_tags.is_empty() or frame == null:
		return true
	for tag in part.compatible_tags:
		if frame.compatibility_tags.has(tag):
			return true
	return false

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
