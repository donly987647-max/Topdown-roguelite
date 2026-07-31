class_name WeaponBuildCalculator
extends RefCounted

static func compile(frame: WeaponFrameData, parts: Array[WeaponPartData]) -> Dictionary:
	if frame == null:
		return {}
	var stats := {
		"damage": frame.base_damage,
		"fire_interval": frame.fire_interval,
		"magazine_capacity": float(frame.magazine_capacity),
		"reload_time": frame.reload_time,
		"projectile_speed": frame.projectile_speed,
		"projectile_lifetime": frame.projectile_lifetime,
		"projectile_radius": frame.projectile_radius,
		"knockback": frame.knockback,
		"critical_chance": frame.critical_chance,
		"spread_degrees": frame.spread_degrees,
		"pellet_count": float(frame.pellet_count),
		"pierce_count": 0.0,
		"ricochet_count": 0.0,
		"status_buildup": 0.0
	}
	var multipliers: Dictionary = {}
	var additions: Dictionary = {}
	var effects := {
		"ammo_cost": 1,
		"pierce_damage_decay": 0.0,
		"ricochet_damage_multiplier": 1.0,
		"reverse_round_damage_decay": 0.0,
		"clone_chance": 0.0,
		"clone_damage_multiplier": 0.0,
		"status_type": &"",
		"swap_speed_multiplier": 1.0,
		"misfire_chance": 0.0,
		"move_speed_multiplier": 1.0,
		"dash_distance_multiplier": 1.0
	}
	var equipped_slots: Dictionary = {}
	var total_power := 0
	var total_weight := 0.0

	for part in parts:
		if part == null or not part.validate_contract().is_empty():
			continue
		if equipped_slots.has(part.slot):
			continue
		equipped_slots[part.slot] = part
		total_power += part.power_cost
		total_weight += part.weight
		for key in part.stat_multipliers:
			multipliers[key] = float(multipliers.get(key, 1.0)) * float(part.stat_multipliers[key])
		for key in part.stat_additions:
			additions[key] = float(additions.get(key, 0.0)) + float(part.stat_additions[key])
		for key in part.effects:
			effects[key] = part.effects[key]

	for key in stats:
		stats[key] = float(stats[key]) * float(multipliers.get(key, 1.0)) + float(additions.get(key, 0.0))

	var power_overload_ratio := maxf(0.0, float(total_power - frame.max_power) / float(maxi(frame.max_power, 1)))
	var weight_overload_ratio := maxf(0.0, (total_weight - frame.max_weight) / maxf(frame.max_weight, 0.01))
	var power_overloaded := power_overload_ratio > 0.0
	var weight_overloaded := weight_overload_ratio > 0.0

	# GDD overload rules implemented for the systems currently present in P2.
	# Heat and active-charge penalties are deferred until those systems exist.
	stats["reload_time"] = float(stats["reload_time"]) * (1.0 + power_overload_ratio * 0.50)
	effects["misfire_chance"] = clampf(power_overload_ratio * 0.12 * (1.10 - frame.stability * 0.40), 0.0, 0.25)
	effects["move_speed_multiplier"] = clampf(1.0 - weight_overload_ratio * 0.18, 0.72, 1.0)
	effects["dash_distance_multiplier"] = clampf(1.0 - weight_overload_ratio * 0.15, 0.75, 1.0)
	var base_swap_multiplier := float(effects.get("swap_speed_multiplier", 1.0))
	effects["swap_speed_multiplier"] = maxf(0.55, base_swap_multiplier / (1.0 + weight_overload_ratio * 0.40))

	stats["damage"] = maxf(0.1, float(stats["damage"]))
	stats["fire_interval"] = maxf(0.01, float(stats["fire_interval"]))
	stats["magazine_capacity"] = maxi(1, roundi(float(stats["magazine_capacity"])))
	stats["reload_time"] = maxf(0.05, float(stats["reload_time"]))
	stats["projectile_speed"] = maxf(1.0, float(stats["projectile_speed"]))
	stats["projectile_lifetime"] = maxf(0.05, float(stats["projectile_lifetime"]))
	stats["projectile_radius"] = maxf(0.5, float(stats["projectile_radius"]))
	stats["knockback"] = maxf(0.0, float(stats["knockback"]))
	stats["critical_chance"] = clampf(float(stats["critical_chance"]), 0.0, 1.0)
	stats["spread_degrees"] = maxf(0.0, float(stats["spread_degrees"]))
	stats["pellet_count"] = maxi(1, roundi(float(stats["pellet_count"])))
	stats["pierce_count"] = maxi(0, roundi(float(stats["pierce_count"])))
	stats["ricochet_count"] = maxi(0, roundi(float(stats["ricochet_count"])))
	stats["status_buildup"] = maxf(0.0, float(stats["status_buildup"]))
	effects["ammo_cost"] = maxi(1, int(effects.get("ammo_cost", 1)))

	return {
		"frame_id": frame.frame_id,
		"stats": stats,
		"effects": effects,
		"equipped_slots": equipped_slots,
		"power_cost": total_power,
		"weight": total_weight,
		"limits": {
			"max_power": frame.max_power,
			"max_weight": frame.max_weight,
			"stability": frame.stability
		},
		"overload": {
			"power": power_overloaded,
			"weight": weight_overloaded,
			"power_ratio": power_overload_ratio,
			"weight_ratio": weight_overload_ratio
		}
	}
