class_name Zone1RewardCatalog
extends RefCounted

func offers() -> Array[RewardOffer]:
	return [
		_offer(&"scrap_cache", &"scrap", &"common", {"display_name":"Scrap Cache","description":"Gain 24 scrap.","amount":24,"tags":[]}, 1.0),
		_offer(&"ammo_crate", &"ammo", &"common", {"display_name":"Ammo Crate","description":"Gain 22 reserve ammo.","amount":22,"tags":["ammo"]}, 1.0),
		_offer(&"field_patch", &"heal", &"common", {"display_name":"Field Patch","description":"Recover 18 HP.","amount":18,"tags":["survival"]}, 0.9),
		_offer(&"shield_cell", &"shield", &"uncommon", {"display_name":"Shield Cell","description":"Gain 18 temporary shield.","amount":18,"tags":["shield","survival"]}, 0.75),
		_offer(&"feed_ramp", &"passive", &"uncommon", _module_payload("Feed Ramp", "Increases magazine capacity by 15% and routes ammunition to adjacent modules.", ["rapid_fire", "ammo"], [[0, 0], [1, 0]], {"left":{"type":"ammo_in","cell":[0, 0],"direction":"left"},"right":{"type":"ammo_out","cell":[1, 0],"direction":"right"}}, {"ammo_supply":8.0,"stat_modifiers":{"magazine_mult":{"op":"mul","value":1.15}}}), 0.70),
		_offer(&"cold_sink", &"passive", &"uncommon", _module_payload("Cold Sink", "Increases heat dissipation by 25% while connected to power.", ["heat", "cooling"], [[0, 0], [0, 1]], {"left":{"type":"power_in","cell":[0, 0],"direction":"left"},"up":{"type":"cooling_out","cell":[0, 0],"direction":"up"},"down":{"type":"cooling_out","cell":[0, 1],"direction":"down"}}, {"power_draw":3.0,"cooling_supply":10.0,"requires_power":true,"stat_modifiers":{"heat_cool_rate_mult":{"op":"mul","value":1.25}}}), 0.66),
		_offer(&"impact_brace", &"passive", &"uncommon", _module_payload("Impact Brace", "Reduces projectile spread and incoming knockback while powered.", ["impact", "heavy"], [[0, 0], [1, 0], [0, 1]], {"right":{"type":"power_in","cell":[1, 0],"direction":"right"}}, {"power_draw":5.0,"requires_power":true,"stat_modifiers":{"spread_mult":{"op":"mul","value":0.78},"player_knockback_mult":{"op":"mul","value":0.55}}}), 0.64),
		_offer(&"shock_bus", &"passive", &"rare", _module_payload("Shock Bus", "Generates power and signal for chained effects.", ["shock", "chain"], [[0, 0], [1, 0], [2, 0]], {"left":{"type":"power_out","cell":[0, 0],"direction":"left"},"right":{"type":"signal_out","cell":[2, 0],"direction":"right"}}, {"power_supply":12.0,"signal_strength":8.0}), 0.52),
		_offer(&"crit_lens", &"passive", &"rare", _module_payload("Crit Lens", "Adds 8% critical chance while connected to power.", ["precision", "critical"], [[0, 0], [1, 0]], {"left":{"type":"signal_in","cell":[0, 0],"direction":"left"},"right":{"type":"power_in","cell":[1, 0],"direction":"right"}}, {"power_draw":4.0,"requires_power":true,"stat_modifiers":{"critical_chance_add":0.08}}), 0.50),
		_offer(&"blast_baffle", &"passive", &"rare", _module_payload("Blast Baffle", "Increases existing explosion radius by 20% while powered.", ["explosive", "launcher"], [[0, 0], [1, 0], [1, 1]], {"left":{"type":"power_in","cell":[0, 0],"direction":"left"}}, {"power_draw":6.0,"requires_power":true,"stat_modifiers":{"explosion_radius_mult":{"op":"mul","value":1.20}}}), 0.48),
		_offer(&"compact_cell", &"passive", &"common", _module_payload("Compact Cell", "Adds 4 rounds to every magazine without requiring power.", ["ammo", "compact"], [[0, 0]], {"right":{"type":"ammo_out","cell":[0, 0],"direction":"right"}}, {"ammo_supply":3.0,"stat_modifiers":{"magazine_add":4.0}}), 0.74),
		_offer(&"reload_actuator", &"passive", &"uncommon", _module_payload("Reload Actuator", "Reloads 18% faster while powered.", ["reload", "mechanical"], [[0, 0], [1, 0]], {"left":{"type":"power_in","cell":[0, 0],"direction":"left"}}, {"power_draw":3.0,"requires_power":true,"stat_modifiers":{"reload_speed_mult":{"op":"mul","value":1.18}}}), 0.66),
		_offer(&"thermal_buffer", &"passive", &"uncommon", _module_payload("Thermal Buffer", "Reduces heat generated per shot by 18% while powered.", ["heat", "cooling"], [[0, 0], [1, 0]], {"right":{"type":"power_in","cell":[1, 0],"direction":"right"}}, {"power_draw":4.0,"requires_power":true,"stat_modifiers":{"heat_per_shot_mult":{"op":"mul","value":0.82}}}), 0.62),
		_offer(&"servo_booster", &"passive", &"uncommon", _module_payload("Servo Booster", "Increases movement speed by 8%.", ["mobility", "mechanical"], [[0, 0], [0, 1]], {"down":{"type":"signal_out","cell":[0, 1],"direction":"down"}}, {"signal_strength":2.0,"stat_modifiers":{"player_move_speed_mult":{"op":"mul","value":1.08}}}), 0.64),
		_offer(&"recoil_compensator", &"passive", &"uncommon", _module_payload("Recoil Compensator", "Tightens spread by 12% and increases projectile speed by 8% while powered.", ["precision", "ballistic"], [[0, 0], [1, 0]], {"left":{"type":"power_in","cell":[0, 0],"direction":"left"}}, {"power_draw":4.0,"requires_power":true,"stat_modifiers":{"spread_mult":{"op":"mul","value":0.88},"projectile_speed_mult":{"op":"mul","value":1.08}}}), 0.60),
		_offer(&"rapid_cycler", &"passive", &"rare", _module_payload("Rapid Cycler", "Raises fire rate by 12% but generates 10% more heat while powered.", ["rapid_fire", "heat"], [[0, 0], [1, 0], [0, 1]], {"left":{"type":"power_in","cell":[0, 0],"direction":"left"}}, {"power_draw":6.0,"requires_power":true,"stat_modifiers":{"fire_rate_mult":{"op":"mul","value":1.12},"heat_per_shot_mult":{"op":"mul","value":1.10}}}), 0.50),
		_offer(&"high_voltage_cap", &"passive", &"rare", _module_payload("High Voltage Capacitor", "Raises weapon damage by 10% while powered.", ["power", "damage"], [[0, 0], [1, 0], [1, 1]], {"left":{"type":"power_in","cell":[0, 0],"direction":"left"},"right":{"type":"signal_out","cell":[1, 0],"direction":"right"}}, {"power_draw":7.0,"signal_strength":2.0,"requires_power":true,"stat_modifiers":{"damage_mult":{"op":"mul","value":1.10}}}), 0.46),
		_offer(&"critical_amp", &"passive", &"rare", _module_payload("Critical Amplifier", "Increases critical-hit damage by 25% while powered.", ["critical", "signal"], [[0, 0], [0, 1]], {"up":{"type":"signal_in","cell":[0, 0],"direction":"up"},"right":{"type":"power_in","cell":[0, 1],"direction":"right"}}, {"power_draw":5.0,"requires_power":true,"stat_modifiers":{"critical_damage_mult":{"op":"mul","value":1.25}}}), 0.45),
		_offer(&"velocity_coil", &"passive", &"uncommon", _module_payload("Velocity Coil", "Increases projectile speed by 18% while powered.", ["projectile", "precision"], [[0, 0], [1, 0]], {"left":{"type":"power_in","cell":[0, 0],"direction":"left"}}, {"power_draw":4.0,"requires_power":true,"stat_modifiers":{"projectile_speed_mult":{"op":"mul","value":1.18}}}), 0.58),
		_offer(&"reinforced_plating", &"passive", &"rare", _module_payload("Reinforced Plating", "Reduces incoming damage by 10% but movement speed by 4%.", ["survival", "heavy"], [[0, 0], [1, 0], [0, 1]], {}, {"stat_modifiers":{"player_damage_taken_mult":{"op":"mul","value":0.90},"player_move_speed_mult":{"op":"mul","value":0.96}}}), 0.44),
		_offer(&"inertia_damper", &"passive", &"uncommon", _module_payload("Inertia Damper", "Reduces incoming knockback by 30%.", ["survival", "stability"], [[0, 0]], {"left":{"type":"signal_in","cell":[0, 0],"direction":"left"}}, {"stat_modifiers":{"player_knockback_mult":{"op":"mul","value":0.70}}}), 0.61),
		_offer(&"chain_relay", &"passive", &"rare", _module_payload("Chain Relay", "Adds one target to chain effects while powered.", ["shock", "chain", "signal"], [[0, 0], [1, 0]], {"left":{"type":"signal_in","cell":[0, 0],"direction":"left"},"right":{"type":"power_in","cell":[1, 0],"direction":"right"}}, {"power_draw":5.0,"requires_power":true,"stat_modifiers":{"chain_count_add":1.0}}), 0.43),
		_offer(&"balanced_bolt", &"passive", &"common", _module_payload("Balanced Bolt", "Raises projectile speed by 6% and reload speed by 6%.", ["ballistic", "utility"], [[0, 0]], {}, {"stat_modifiers":{"projectile_speed_mult":{"op":"mul","value":1.06},"reload_speed_mult":{"op":"mul","value":1.06}}}), 0.68),
		_offer(&"repair_injector", &"active", &"rare", _module_payload("Repair Injector", "Restores 24 HP over 4 seconds; taking damage interrupts the repair.", ["active", "survival"], [[0, 0], [0, 1]], {"right":{"type":"power_in","cell":[0, 0],"direction":"right"}}, {"power_draw":6.0,"requires_power":true,"cooldown":18.0,"charges":0,"effect_ids":["repair_over_time"],"activation_payload":{"effect":"repair_over_time","amount":24.0,"duration":4.0}}), 0.42),
		_offer(&"overclock_key", &"active", &"epic", _module_payload("Overclock Key", "Boosts damage and fire rate for 4 seconds, then overheats the weapon.", ["active", "rapid_fire", "heat"], [[0, 0], [1, 0], [0, 1]], {"left":{"type":"power_in","cell":[0, 0],"direction":"left"},"down":{"type":"signal_in","cell":[0, 1],"direction":"down"}}, {"power_draw":10.0,"requires_power":true,"cooldown":16.0,"charges":0,"effect_ids":["overclock"],"activation_payload":{"effect":"overclock","duration":4.0,"damage_mult":1.20,"fire_rate_mult":1.25,"end_overheat":1.35}}), 0.28),
		_gear_offer(&"burst_carbine", &"frame", &"rare", "Burst Carbine", "Three-round burst frame with controlled mid-range pressure.", ["weapon", "ballistic"], 0.34),
		_gear_offer(&"breach_shotgun", &"frame", &"rare", "Breach Shotgun", "Close-range frame with strong stagger and knockback.", ["weapon", "ballistic"], 0.30),
		_gear_offer(&"precision_barrel", &"barrel", &"uncommon", "Precision Barrel", "Tighter spread and faster projectiles at a fire-rate cost.", ["precision"], 0.48),
		_gear_offer(&"spread_barrel", &"barrel", &"uncommon", "Spread Barrel", "Adds projectiles while reducing each projectile's damage.", ["spread", "shotgun"], 0.45),
		_gear_offer(&"ricochet_barrel", &"barrel", &"rare", "Ricochet Barrel", "Projectiles rebound from walls and gain post-bounce damage.", ["ricochet"], 0.34),
		_gear_offer(&"extended_mag", &"magazine", &"uncommon", "Extended Magazine", "Much larger capacity with a slower reload.", ["ammo"], 0.47),
		_gear_offer(&"light_mag", &"magazine", &"uncommon", "Light Magazine", "Smaller capacity with a much faster reload.", ["reload"], 0.46),
		_gear_offer(&"reactive_mag", &"magazine", &"rare", "Reactive Magazine", "One instant post-hit reload each room.", ["reactive"], 0.32),
		_gear_offer(&"fire_core", &"core", &"uncommon", "Fire Core", "Applies burn and detonates small enemies on death.", ["fire", "burn"], 0.45),
		_gear_offer(&"electric_core", &"core", &"rare", "Electric Core", "Applies shock and chains through nearby targets.", ["electric", "shock"], 0.34),
		_gear_offer(&"cooling_core", &"core", &"uncommon", "Cooling Core", "Applies chill and slows boss actions at maximum stacks.", ["cooling", "chill"], 0.42),
	]

func _offer(id: StringName, category: StringName, rarity: StringName, payload: Dictionary, weight: float) -> RewardOffer:
	return RewardOffer.new(id, category, rarity, payload, weight)

func _module_payload(display_name: String, description: String, tags: Array, cells: Array, connectors: Dictionary, economy: Dictionary) -> Dictionary:
	var payload := {
		"display_name": display_name,
		"description": description,
		"tags": tags,
		"cells": cells,
		"connectors": connectors,
		"rotatable": true,
	}
	for key in economy.keys():
		payload[key] = economy[key]
	return payload

func _gear_offer(id: StringName, category: StringName, rarity: StringName, display_name: String, description: String, tags: Array, weight: float) -> RewardOffer:
	return _offer(id, category, rarity, {"display_name":display_name,"description":description,"tags":tags}, weight)
