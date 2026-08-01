class_name RewardChoiceViewModel
extends RefCounted

func build(choices: Array[RewardOffer]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(choices.size()):
		var offer := choices[index]
		if offer == null:
			continue
		result.append({
			"index": index,
			"id": offer.id,
			"category": offer.category,
			"rarity": offer.rarity,
			"title": _title_for(offer),
			"description": _description_for(offer),
			"tags": _tags_for(offer),
			"payload": offer.payload,
		})
	return result

func _title_for(offer: RewardOffer) -> String:
	if offer.payload is Dictionary:
		var title := String(offer.payload.get("display_name", offer.payload.get("name", "")))
		if not title.is_empty():
			return title
	return String(offer.id).replace("_", " ").capitalize()

func _description_for(offer: RewardOffer) -> String:
	if offer.payload is Dictionary:
		return String(offer.payload.get("description", ""))
	return ""

func _tags_for(offer: RewardOffer) -> PackedStringArray:
	if offer.payload is Dictionary:
		return PackedStringArray(offer.payload.get("tags", []))
	return PackedStringArray()
