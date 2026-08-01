class_name PassiveModuleRuntime
extends Node

signal passive_state_changed(summary: Dictionary)
signal passive_triggered(effect_id: StringName, context: Dictionary)

var modules: Array[PassiveModuleDefinition] = []
var aggregated_stats: Dictionary = {}

func set_modules(new_modules: Array[PassiveModuleDefinition]) -> void:
	modules = new_modules.duplicate()
	_rebuild()

func add_module(module: PassiveModuleDefinition) -> void:
	if module == null:
		return
	modules.append(module)
	_rebuild()

func remove_module(module_id: StringName) -> bool:
	for i in range(modules.size()):
		if modules[i] != null and modules[i].id == module_id:
			modules.remove_at(i)
			_rebuild()
			return true
	return false

func stat(key: StringName, fallback: float = 0.0) -> float:
	return float(aggregated_stats.get(key, fallback))

func modify_value(key: StringName, base_value: float) -> float:
	var additive := float(aggregated_stats.get(StringName(String(key) + "_add"), 0.0))
	var multiplier := float(aggregated_stats.get(StringName(String(key) + "_mult"), 1.0))
	return (base_value + additive) * multiplier

func trigger(event_id: StringName, context: Dictionary = {}) -> Array[StringName]:
	var fired: Array[StringName] = []
	for module in modules:
		if module == null:
			continue
		for raw_effect in module.trigger_effect_ids:
			var effect := StringName(raw_effect)
			if not _effect_matches_event(effect, event_id):
				continue
			fired.append(effect)
			passive_triggered.emit(effect, context)
	return fired

func summary() -> Dictionary:
	return {
		"module_count": modules.size(),
		"stats": aggregated_stats.duplicate(true),
	}

func _rebuild() -> void:
	aggregated_stats.clear()
	var stack_counts: Dictionary = {}
	for module in modules:
		if module == null:
			continue
		var count := int(stack_counts.get(module.id, 0))
		if module.max_stacks > 0 and count >= module.max_stacks:
			continue
		stack_counts[module.id] = count + 1
		for key in module.stat_modifiers.keys():
			_apply_modifier(StringName(key), module.stat_modifiers[key])
	passive_state_changed.emit(summary())

func _apply_modifier(key: StringName, raw: Variant) -> void:
	if raw is Dictionary:
		var op := String(raw.get("op", "add"))
		var value := float(raw.get("value", 0.0))
		if op == "mul":
			aggregated_stats[key] = float(aggregated_stats.get(key, 1.0)) * value
		elif op == "set":
			aggregated_stats[key] = value
		else:
			aggregated_stats[key] = float(aggregated_stats.get(key, 0.0)) + value
	elif raw is int or raw is float:
		aggregated_stats[key] = float(aggregated_stats.get(key, 0.0)) + float(raw)
	else:
		aggregated_stats[key] = raw

func _effect_matches_event(effect_id: StringName, event_id: StringName) -> bool:
	var text := String(effect_id).to_lower()
	var event_text := String(event_id).to_lower()
	return text.begins_with(event_text + ":") or text == event_text
