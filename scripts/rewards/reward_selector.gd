class_name RewardSelector
extends RefCounted

const DEFAULT_CHOICE_COUNT := 3
const RECENT_MEMORY := 8

var pool: Array[RewardOffer] = []
var recent_ids: Array[StringName] = []
var claimed_ids: Dictionary = {}

func set_pool(offers: Array[RewardOffer]) -> void:
	pool = offers.duplicate()

func add_offer(offer: RewardOffer) -> void:
	if offer != null and offer.id != &"":
		pool.append(offer)

func generate_choices(count: int = DEFAULT_CHOICE_COUNT, excluded_ids: Array[StringName] = []) -> Array[RewardOffer]:
	var target_count := maxi(1, count)
	var candidates: Array[RewardOffer] = []
	for offer in pool:
		if offer == null or offer.id == &"" or offer.id in excluded_ids:
			continue
		candidates.append(offer)
	var result: Array[RewardOffer] = []
	while not candidates.is_empty() and result.size() < target_count:
		var picked := _weighted_pick(candidates)
		if picked == null:
			break
		result.append(picked)
		for i in range(candidates.size() - 1, -1, -1):
			if candidates[i].id == picked.id:
				candidates.remove_at(i)
	return result

func claim(offer: RewardOffer) -> bool:
	if offer == null or offer.id == &"":
		return false
	claimed_ids[offer.id] = int(claimed_ids.get(offer.id, 0)) + 1
	recent_ids.append(offer.id)
	while recent_ids.size() > RECENT_MEMORY:
		recent_ids.pop_front()
	return true

func claim_count(id: StringName) -> int:
	return int(claimed_ids.get(id, 0))

func serialize_history() -> Dictionary:
	var recent: Array[String] = []
	for id in recent_ids:
		recent.append(String(id))
	var claimed: Dictionary = {}
	for id in claimed_ids.keys():
		claimed[String(id)] = int(claimed_ids[id])
	return {"recent": recent, "claimed": claimed}

func restore_history(data: Dictionary) -> void:
	recent_ids.clear()
	for raw in data.get("recent", []):
		recent_ids.append(StringName(raw))
	claimed_ids.clear()
	for raw_id in data.get("claimed", {}).keys():
		claimed_ids[StringName(raw_id)] = int(data["claimed"][raw_id])

func _weighted_pick(candidates: Array[RewardOffer]) -> RewardOffer:
	var total := 0.0
	var weights: Array[float] = []
	for offer in candidates:
		var weight := _effective_weight(offer)
		weights.append(weight)
		total += weight
	if total <= 0.0:
		return candidates[0] if not candidates.is_empty() else null
	var roll := randf() * total
	for i in range(candidates.size()):
		roll -= weights[i]
		if roll <= 0.0:
			return candidates[i]
	return candidates.back()

func _effective_weight(offer: RewardOffer) -> float:
	var weight := maxf(0.001, offer.weight) * _rarity_weight(offer.rarity)
	if offer.id in recent_ids:
		weight *= 0.20
	var copies := claim_count(offer.id)
	if copies > 0:
		weight /= 1.0 + copies * 0.65
	return weight

func _rarity_weight(rarity: StringName) -> float:
	match rarity:
		&"common": return 1.0
		&"uncommon": return 0.72
		&"rare": return 0.42
		&"epic": return 0.22
		&"legendary": return 0.10
	return 1.0
