class_name StatusController
extends Node

signal status_applied(status_id: StringName, stacks: int)
signal status_removed(status_id: StringName)
signal periodic_damage(amount: float, status_id: StringName)

var _active: Dictionary = {}

func apply(definition: StatusEffectDefinition, stacks: int = 1, source_power: float = 1.0) -> void:
	if definition == null or definition.id == StringName():
		return
	var state: Dictionary = _active.get(definition.id, {
		"definition": definition,
		"stacks": 0,
		"remaining": 0.0,
		"tick_left": definition.tick_interval,
		"source_power": source_power,
	})
	state["stacks"] = mini(definition.max_stacks, int(state["stacks"]) + maxi(1, stacks))
	state["remaining"] = maxf(float(state["remaining"]), definition.duration)
	state["source_power"] = maxf(float(state["source_power"]), source_power)
	_active[definition.id] = state
	status_applied.emit(definition.id, int(state["stacks"]))

func clear(status_id: StringName) -> void:
	if _active.erase(status_id):
		status_removed.emit(status_id)

func clear_all() -> void:
	for status_id in _active.keys():
		status_removed.emit(status_id)
	_active.clear()

func _process(delta: float) -> void:
	var removals: Array[StringName] = []
	for status_id in _active.keys():
		var state: Dictionary = _active[status_id]
		var definition := state["definition"] as StatusEffectDefinition
		state["remaining"] = float(state["remaining"]) - delta
		if definition.tick_interval > 0.0 and definition.damage_per_tick > 0.0:
			state["tick_left"] = float(state["tick_left"]) - delta
			while float(state["tick_left"]) <= 0.0:
				var amount: float = definition.damage_per_tick * int(state["stacks"]) * float(state["source_power"])
				periodic_damage.emit(amount, status_id)
				state["tick_left"] = float(state["tick_left"]) + definition.tick_interval
		_active[status_id] = state
		if float(state["remaining"]) <= 0.0:
			removals.append(status_id)
	for status_id in removals:
		clear(status_id)

func move_speed_multiplier() -> float:
	return _product_modifier("move_speed_multiplier")

func damage_taken_multiplier() -> float:
	return _product_modifier("damage_taken_multiplier")

func outgoing_damage_multiplier() -> float:
	return _product_modifier("outgoing_damage_multiplier")

func is_confused() -> bool:
	return _active.has(&"confusion")

func active_ids() -> Array:
	return _active.keys()

func _product_modifier(property_name: StringName) -> float:
	var value := 1.0
	for state in _active.values():
		var definition := state["definition"] as StatusEffectDefinition
		var per_stack := float(definition.get(property_name))
		var stacks := int(state["stacks"])
		value *= pow(per_stack, stacks)
	return value
