class_name RewardOffer
extends RefCounted

var id: StringName
var category: StringName
var rarity: StringName
var payload: Variant
var weight: float = 1.0

func _init(new_id: StringName = &"", new_category: StringName = &"", new_rarity: StringName = &"common", new_payload: Variant = null, new_weight: float = 1.0) -> void:
	id = new_id
	category = new_category
	rarity = new_rarity
	payload = new_payload
	weight = maxf(0.0, new_weight)

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"category": category,
		"rarity": rarity,
		"payload": payload,
		"weight": weight,
	}
