class_name ThreatBudgetPlanner
extends RefCounted

var enemy_costs: Dictionary = {}
var enemy_tags: Dictionary = {}

func register_enemy(enemy_id: StringName, threat_cost: int, tags: PackedStringArray = []) -> void:
	if enemy_id == &"":
		return
	enemy_costs[enemy_id] = maxi(1, threat_cost)
	enemy_tags[enemy_id] = tags

func build_waves(template: RoomTemplateDefinition, difficulty_multiplier: float = 1.0, elite_bonus: float = 1.35) -> Array[Array]:
	var waves: Array[Array] = []
	if template == null or not template.is_combat_room():
		return waves
	var wave_count := clampi(template.wave_count, 1, 3)
	var room_multiplier := elite_bonus if template.room_type == &"elite" else 1.0
	var total_budget := maxi(wave_count, int(round(template.recommended_threat * maxf(0.1, difficulty_multiplier) * room_multiplier)))
	var remaining_budget := total_budget
	for wave_index in range(wave_count):
		var waves_left := wave_count - wave_index
		var target_budget := maxi(1, int(ceil(float(remaining_budget) / float(waves_left))))
		var wave := _fill_wave(template, target_budget)
		waves.append(wave)
		remaining_budget = maxi(0, remaining_budget - _wave_cost(wave))
	return waves

func _fill_wave(template: RoomTemplateDefinition, budget: int) -> Array:
	var candidates := _eligible_enemies(template)
	var wave: Array = []
	if candidates.is_empty():
		return wave
	var remaining := maxi(1, budget)
	var safety := 64
	while remaining > 0 and safety > 0:
		safety -= 1
		var best_id := _pick_enemy_for_budget(candidates, remaining, wave.is_empty())
		if best_id == &"":
			break
		var cost := int(enemy_costs.get(best_id, 1))
		wave.append({"enemy_id": best_id, "threat_cost": cost})
		remaining -= cost
	return wave

func _eligible_enemies(template: RoomTemplateDefinition) -> Array[StringName]:
	var result: Array[StringName] = []
	if not template.allowed_enemy_ids.is_empty():
		for raw_id in template.allowed_enemy_ids:
			var id := StringName(raw_id)
			if enemy_costs.has(id):
				result.append(id)
		return result
	for id in enemy_costs.keys():
		if template.allowed_enemy_tags.is_empty() or _has_any_tag(id, template.allowed_enemy_tags):
			result.append(id)
	return result

func _pick_enemy_for_budget(candidates: Array[StringName], remaining: int, allow_over_budget: bool) -> StringName:
	var affordable: Array[StringName] = []
	var cheapest := 999999
	var cheapest_id := StringName()
	for id in candidates:
		var cost := int(enemy_costs.get(id, 1))
		if cost <= remaining:
			affordable.append(id)
		if cost < cheapest:
			cheapest = cost
			cheapest_id = id
	if not affordable.is_empty():
		return affordable[randi() % affordable.size()]
	return cheapest_id if allow_over_budget else &""

func _has_any_tag(enemy_id: StringName, allowed: PackedStringArray) -> bool:
	var tags: PackedStringArray = enemy_tags.get(enemy_id, PackedStringArray())
	for tag in allowed:
		if tag in tags:
			return true
	return false

func _wave_cost(wave: Array) -> int:
	var total := 0
	for entry in wave:
		total += int(entry.get("threat_cost", 0))
	return total
