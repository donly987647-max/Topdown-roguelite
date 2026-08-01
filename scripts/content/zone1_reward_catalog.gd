class_name Zone1RewardCatalog
extends RefCounted

func offers() -> Array[RewardOffer]:
	return [
		_offer(&"scrap_cache", &"scrap", &"common", {"display_name":"Scrap Cache","description":"Gain 24 scrap.","amount":24,"tags":[]}, 1.0),
		_offer(&"ammo_crate", &"ammo", &"common", {"display_name":"Ammo Crate","description":"Gain 22 reserve ammo.","amount":22,"tags":["ammo"]}, 1.0),
		_offer(&"field_patch", &"heal", &"common", {"display_name":"Field Patch","description":"Recover 18 HP.","amount":18,"tags":["survival"]}, 0.9),
		_offer(&"shield_cell", &"shield", &"uncommon", {"display_name":"Shield Cell","description":"Gain 18 temporary shield.","amount":18,"tags":["shield","survival"]}, 0.75),
		_offer(&"feed_ramp", &"passive", &"uncommon", {"display_name":"Feed Ramp","description":"Starter rapid-fire passive module.","tags":["rapid_fire","ammo"]}, 0.70),
		_offer(&"cold_sink", &"passive", &"uncommon", {"display_name":"Cold Sink","description":"Starter heat-management passive module.","tags":["heat","cooling"]}, 0.66),
		_offer(&"impact_brace", &"passive", &"uncommon", {"display_name":"Impact Brace","description":"Starter knockback/impact passive module.","tags":["impact","heavy"]}, 0.64),
		_offer(&"shock_bus", &"passive", &"rare", {"display_name":"Shock Bus","description":"Starter electric-chain passive module.","tags":["shock","chain"]}, 0.52),
		_offer(&"crit_lens", &"passive", &"rare", {"display_name":"Crit Lens","description":"Starter precision/critical passive module.","tags":["precision","critical"]}, 0.50),
		_offer(&"blast_baffle", &"passive", &"rare", {"display_name":"Blast Baffle","description":"Starter explosion-focused passive module.","tags":["explosive","launcher"]}, 0.48),
		_offer(&"repair_injector", &"active", &"rare", {"display_name":"Repair Injector","description":"Starter active recovery equipment.","tags":["active","survival"]}, 0.42),
		_offer(&"overclock_key", &"active", &"epic", {"display_name":"Overclock Key","description":"Starter high-risk offensive active equipment.","tags":["active","rapid_fire","heat"]}, 0.28),
	]

func _offer(id: StringName, category: StringName, rarity: StringName, payload: Dictionary, weight: float) -> RewardOffer:
	return RewardOffer.new(id, category, rarity, payload, weight)
