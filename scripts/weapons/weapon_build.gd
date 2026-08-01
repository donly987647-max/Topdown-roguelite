class_name WeaponBuild
extends Resource

@export var frame: WeaponFrameDefinition
@export var barrel: WeaponPartDefinition
@export var magazine: WeaponPartDefinition
@export var core: WeaponPartDefinition

func is_complete() -> bool:
	return frame != null and barrel != null and magazine != null and core != null

func total_power_cost() -> float:
	return _sum_part_stat("power_cost")

func total_weight() -> float:
	return _sum_part_stat("weight")

func total_stability_cost() -> float:
	return _sum_part_stat("stability_cost")

func overload_ratio() -> float:
	if frame == null or frame.power_capacity <= 0.0:
		return 0.0
	return maxf(0.0, total_power_cost() / frame.power_capacity - 1.0)

func is_overloaded() -> bool:
	return overload_ratio() > 0.0

func computed_stats() -> Dictionary:
	if frame == null:
		return {}
	var stats := {
		"damage": frame.base_damage,
		"fire_rate": frame.base_fire_rate,
		"magazine": frame.base_magazine,
		"reload_time": frame.base_reload_time,
		"spread": frame.base_spread,
		"projectile_speed": frame.base_projectile_speed,
		"heat_per_shot": frame.base_heat_per_shot,
		"cooling_rate": frame.base_cooling_rate,
		"power_cost": total_power_cost(),
		"weight": total_weight(),
		"stability_cost": total_stability_cost(),
		"overload_ratio": overload_ratio(),
	}
	for part in [barrel, magazine, core]:
		if part == null:
			continue
		for key in part.stat_add.keys():
			stats[key] = float(stats.get(key, 0.0)) + float(part.stat_add[key])
		for key in part.stat_mul.keys():
			stats[key] = float(stats.get(key, 0.0)) * float(part.stat_mul[key])
	var overload := overload_ratio()
	if overload > 0.0:
		stats["spread"] = float(stats["spread"]) * (1.0 + overload * 1.25)
		stats["heat_per_shot"] = float(stats["heat_per_shot"]) * (1.0 + overload * 1.5)
		stats["reload_time"] = float(stats["reload_time"]) * (1.0 + overload * 0.5)
	return stats

func effect_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for part in [barrel, magazine, core]:
		if part == null:
			continue
		for effect_id in part.effect_ids:
			if not result.has(effect_id):
				result.append(effect_id)
	return result

func _sum_part_stat(property_name: StringName) -> float:
	var total := 0.0
	for part in [barrel, magazine, core]:
		if part != null:
			total += float(part.get(property_name))
	return total
