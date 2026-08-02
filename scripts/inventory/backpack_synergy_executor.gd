class_name BackpackSynergyExecutor
extends RefCounted

var explicit_rules: Dictionary = {}
var tag_rules: Array[Dictionary] = []

func register_explicit_rule(rule_id: StringName, required_effect_ids: Array[StringName], output_effects: Dictionary) -> void:
	if rule_id == &"" or required_effect_ids.is_empty():
		return
	explicit_rules[rule_id] = {
		"requires": required_effect_ids.duplicate(),
		"effects": output_effects.duplicate(true),
	}

func register_tag_rule(rule_id: StringName, tag: StringName, minimum_tier: int, output_effects: Dictionary) -> void:
	if rule_id == &"" or tag == &"" or minimum_tier <= 0:
		return
	tag_rules.append({
		"id": rule_id,
		"tag": tag,
		"tier": minimum_tier,
		"effects": output_effects.duplicate(true),
	})

func evaluate(resolved: Dictionary) -> Dictionary:
	var result := {
		"active_synergies": [],
		"effects": {},
	}
	var adjacency_effects: Array = resolved.get("active_effect_ids", resolved.get("adjacency_effects", []))
	for rule_id in explicit_rules.keys():
		var rule: Dictionary = explicit_rules[rule_id]
		if _contains_all(adjacency_effects, rule["requires"]):
			result["active_synergies"].append(rule_id)
			_merge_effects(result["effects"], rule["effects"])
	var tiers: Dictionary = resolved.get("tag_tiers", {})
	for rule in tag_rules:
		if int(tiers.get(rule["tag"], 0)) >= int(rule["tier"]):
			result["active_synergies"].append(rule["id"])
			_merge_effects(result["effects"], rule["effects"])
	return result

func _contains_all(haystack: Array, needles: Array) -> bool:
	for needle in needles:
		if needle not in haystack:
			return false
	return true

func _merge_effects(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		var value = source[key]
		if value is int or value is float:
			target[key] = float(target.get(key, 0.0)) + float(value)
		elif value is bool:
			target[key] = bool(target.get(key, false)) or value
		elif value is Array:
			var combined: Array = target.get(key, []).duplicate()
			for entry in value:
				if entry not in combined:
					combined.append(entry)
			target[key] = combined
		else:
			target[key] = value
