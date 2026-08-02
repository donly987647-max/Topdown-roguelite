class_name Zone1RewardCatalog
extends RefCounted

func offers() -> Array[RewardOffer]:
	return [
		_offer(&"scrap_cache", &"scrap", &"common", {"display_name":"Scrap Cache","description":"Gain 24 scrap.","amount":24,"tags":[]}, 1.0),
		_offer(&"ammo_crate", &"ammo", &"common", {"display_name":"Ammo Crate","description":"Gain 22 reserve ammo.","amount":22,"tags":["ammo"]}, 1.0),
		_offer(&"field_patch", &"heal", &"common", {"display_name":"Field Patch","description":"Recover 18 HP.","amount":18,"tags":["survival"]}, 0.9),
		_offer(&"shield_cell", &"shield", &"uncommon", {"display_name":"Shield Cell","description":"Gain 18 temporary shield.","amount":18,"tags":["shield","survival"]}, 0.75),
		_offer(&"feed_ramp", &"passive", &"uncommon", _module_payload("Feed Ramp", "Links ammunition flow to rapid-fire modules.", ["rapid_fire", "ammo"], [[0, 0], [1, 0]], {"left":{"type":"ammo_in","cell":[0, 0],"direction":"left"},"right":{"type":"ammo_out","cell":[1, 0],"direction":"right"}}, {"ammo_supply":8.0}), 0.70),
		_offer(&"cold_sink", &"passive", &"uncommon", _module_payload("Cold Sink", "Supplies cooling to adjacent heat modules.", ["heat", "cooling"], [[0, 0], [0, 1]], {"up":{"type":"cooling_out","cell":[0, 0],"direction":"up"},"down":{"type":"cooling_out","cell":[0, 1],"direction":"down"}}, {"cooling_supply":10.0}), 0.66),
		_offer(&"impact_brace", &"passive", &"uncommon", _module_payload("Impact Brace", "A compact brace for impact and heavy builds.", ["impact", "heavy"], [[0, 0], [1, 0], [0, 1]], {"right":{"type":"power_in","cell":[1, 0],"direction":"right"}}, {"power_draw":5.0,"requires_power":true}), 0.64),
		_offer(&"shock_bus", &"passive", &"rare", _module_payload("Shock Bus", "Generates power and signal for chained effects.", ["shock", "chain"], [[0, 0], [1, 0], [2, 0]], {"left":{"type":"power_out","cell":[0, 0],"direction":"left"},"right":{"type":"signal_out","cell":[2, 0],"direction":"right"}}, {"power_supply":12.0,"signal_strength":8.0}), 0.52),
		_offer(&"crit_lens", &"passive", &"rare", _module_payload("Crit Lens", "Powered optics for precision and critical builds.", ["precision", "critical"], [[0, 0], [1, 0]], {"left":{"type":"signal_in","cell":[0, 0],"direction":"left"},"right":{"type":"power_in","cell":[1, 0],"direction":"right"}}, {"power_draw":4.0,"requires_power":true}), 0.50),
		_offer(&"blast_baffle", &"passive", &"rare", _module_payload("Blast Baffle", "Reinforces explosive and launcher modules.", ["explosive", "launcher"], [[0, 0], [1, 0], [1, 1]], {"left":{"type":"power_in","cell":[0, 0],"direction":"left"}}, {"power_draw":6.0,"requires_power":true}), 0.48),
		_offer(&"repair_injector", &"active", &"rare", _module_payload("Repair Injector", "Active recovery equipment that needs a live power link.", ["active", "survival"], [[0, 0], [0, 1]], {"right":{"type":"power_in","cell":[0, 0],"direction":"right"}}, {"power_draw":6.0,"requires_power":true}), 0.42),
		_offer(&"overclock_key", &"active", &"epic", _module_payload("Overclock Key", "High-risk offensive active equipment with heavy power draw.", ["active", "rapid_fire", "heat"], [[0, 0], [1, 0], [0, 1]], {"left":{"type":"power_in","cell":[0, 0],"direction":"left"},"down":{"type":"signal_in","cell":[0, 1],"direction":"down"}}, {"power_draw":10.0,"requires_power":true}), 0.28),
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
