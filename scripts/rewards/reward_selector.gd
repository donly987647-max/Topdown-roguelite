class_name RewardSelector
extends RefCounted

const DEFAULT_CHOICE_COUNT := 3
const RECENT_MEMORY := 8
const PITY_INTERVAL := 5

var pool: Array[RewardOffer] = []
var recent_ids: Array[StringName] = []
var claimed_ids: Dictionary = {}
var rooms_since_build_related := 0

func set_pool(offers: Array[RewardOffer]) -> void:
	pool = offers.duplicate()

func add_offer(offer: RewardOffer) -> void:
	if offer != null and offer.id != &"":
		pool.append(offer)

func generate_choices(count: int = DEFAULT_CHOICE_COUNT, excluded_ids: Array[StringName] = []) -> Array[RewardOffer]:
	return _pick_unique(_eligible_pool(excluded_ids), maxi(1, count))

func generate_major_choices(build_tags: PackedStringArray, excluded_ids: Array[StringName] = []) -> Array[RewardOffer]:
	var candidates := _eligible_pool(excluded_ids)
	var result: Array[RewardOffer] = []
	var related := _filter_by_relation(candidates, build_tags, true)
	var novel := _filter_by_relation(candidates, build_tags, false)
	var related_pick := _weighted_pick(related)
	if related_pick != null:
		result.append(related_pick)
		_remove_offer_id(candidates, related_pick.id)
		_remove_offer_id(novel, related_pick.id)
	var random_pick := _weighted_pick(candidates)
	if random_pick != null:
		result.append(random_pick)
		_remove_offer_id(candidates, random_pick.id)
		_remove_offer_id(novel, random_pick.id)
	var novel_pick := _weighted_pick(novel)
	if novel_pick == null:
		novel_pick = _weighted_pick(candidates)
	if novel_pick != null:
		result.append(novel_pick)
	while result.size() < DEFAULT_CHOICE_COUNT and not candidates.is_empty():
		var fallback := _weighted_pick(candidates)
		if fallback == null:
			break
		result.append(fallback)
		_remove_offer_id(candidates, fallback.id)
	return result

func claim(offer: RewardOffer, build_tags: PackedStringArray = []) -> bool:
	if offer == null or offer.id == &"":
		return false
	claimed_ids[offer.id] = int(claimed_ids.get(offer.id, 0)) + 1
	recent_ids.append(offer.id)
	while recent_ids.size() > RECENT_MEMORY:
		recent_ids.pop_front()
	if _offer_matches_tags(offer, build_tags):
		rooms_since_build_related = 0
	else:
		rooms_since_build_related += 1
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
	return {"recent": recent, "claimed": claimed, "rooms_since_build_related": rooms_since_build_related}

func restore_history(data: Dictionary) -> void:
	recent_ids.clear()
	for raw in data.get("recent", []):
		recent_ids.append(StringName(raw))
	claimed_ids.clear()
	for raw_id in data.get("claimed", {}).keys():
		claimed_ids[StringName(raw_id)] = int(data["claimed"][raw_id])
	rooms_since_build_related = maxi(0, int(data.get("rooms_since_build_related", 0)))

func _eligible_pool(excluded_ids: Array[StringName]) -> Array[RewardOffer]:
	var candidates: Array[RewardOffer] = []
	for offer in pool:
		if offer == null or offer.id == &"" or offer.id in excluded_ids:
			continue
		candidates.append(offer)
	return candidates

func _pick_unique(candidates: Array[RewardOffer], count: int) -> Array[RewardOffer]:
	var working := candidates.duplicate()
	var result: Array[RewardOffer] = []
	while not working.is_empty() and result.size() < count:
		var picked := _weighted_pick(working)
		if picked == null:
			break
		result.append(picked)
		_remove_offer_id(working, picked.id)
	return result

func _filter_by_relation(candidates: Array[RewardOffer], build_tags: PackedStringArray, related: bool) -> Array[RewardOffer]:
	var result: Array[RewardOffer] = []
	for offer in candidates:
		if _offer_matches_tags(offer, build_tags) == related:
			result.append(offer)
	return result

func _offer_matches_tags(offer: RewardOffer, build_tags: PackedStringArray) -> bool:
	if build_tags.is_empty() or not (offer.payload is Dictionary):
		return false
	var tags = offer.payload.get("tags", [])
	for tag in build_tags:
		if tag in tags:
			return true
	return false

func _remove_offer_id(candidates: Array[RewardOffer], id: StringName) -> void:
	for i in range(candidates.size() - 1, -1, -1):
		if candidates[i].id == id:
			candidates.remove_at(i)

func _weighted_pick(candidates: Array[RewardOffer]) -> RewardOffer:
	if candidates.is_empty():
		return null
	var total := 0.0
	var weights: Array[float] = []
	for offer in candidates:
		var weight := _effective_weight(offer)
		weights.append(weight)
		total += weight
	if total <= 0.0:
		return candidates[0]
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
	if rooms_since_build_related >= PITY_INTERVAL and offer.payload is Dictionary and not offer.payload.get("tags", []).is_empty():
		weight *= 1.20
	return weight

func _rarity_weight(rarity: StringName) -> float:
	match rarity:
		&"common": return 1.0
		&"uncommon": return 0.72
		&"rare": return 0.42
		&"epic": return 0.22
		&"legendary": return 0.10
	return 1.0
