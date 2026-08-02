class_name RunEquipmentRuntime
extends Node

signal loadout_changed(summary: Dictionary)
signal active_state_changed(equipment_id: StringName, title: String, ready: bool, current: float, maximum: float, powered: bool)
signal active_effect_started(effect_id: StringName, duration: float)
signal active_effect_ended(effect_id: StringName, completed: bool)

var inventory: RunInventoryRuntime
var player: Player
var weapon: WeaponController
var passive_runtime := PassiveModuleRuntime.new()
var active_runtime := ActiveEquipmentRuntime.new()

var _active_instance_id: StringName = &""
var _active_powered := false
var _equipment_states: Dictionary = {}
var _temporary_effect_id: StringName = &""
var _temporary_left := 0.0
var _repair_rate := 0.0
var _temporary_modifiers: Dictionary = {}

func configure(inventory_runtime: RunInventoryRuntime, player_node: Player, weapon_controller: WeaponController) -> bool:
	inventory = inventory_runtime
	player = player_node
	weapon = weapon_controller
	if passive_runtime.get_parent() == null:
		passive_runtime.name = "PassiveModuleRuntime"
		add_child(passive_runtime)
	if active_runtime.get_parent() == null:
		active_runtime.name = "ActiveEquipmentRuntime"
		add_child(active_runtime)
	if inventory != null and not inventory.inventory_changed.is_connected(_rebuild_loadout):
		inventory.inventory_changed.connect(_rebuild_loadout)
	if player != null and not player.damaged.is_connected(_on_player_damaged):
		player.damaged.connect(_on_player_damaged)
	if not active_runtime.equipment_activated.is_connected(_on_equipment_activated):
		active_runtime.equipment_activated.connect(_on_equipment_activated)
	if not active_runtime.equipment_cooldown_changed.is_connected(_on_cooldown_changed):
		active_runtime.equipment_cooldown_changed.connect(_on_cooldown_changed)
	_rebuild_loadout()
	return inventory != null and player != null and weapon != null

func _process(delta: float) -> void:
	if player != null and player.input_enabled and InputMap.has_action("equipment_active") and Input.is_action_just_pressed("equipment_active"):
		try_activate()
	if _temporary_effect_id == &"" or _temporary_left <= 0.0:
		return
	var step := minf(delta, _temporary_left)
	_temporary_left = maxf(0.0, _temporary_left - delta)
	if _temporary_effect_id == &"repair_over_time" and player != null:
		player.heal(_repair_rate * step)
	if _temporary_left <= 0.0:
		_finish_temporary_effect(true)

func try_activate(context: Dictionary = {}) -> bool:
	if not _active_powered or active_runtime.equipment == null:
		return false
	return active_runtime.activate(context)

func active_progress() -> Dictionary:
	var definition := active_runtime.equipment
	if definition == null:
		return {"id":&"", "title":"장비 없음", "ready":false, "current":0.0, "maximum":1.0, "powered":false}
	var maximum := maxf(0.01, definition.cooldown)
	return {
		"id": definition.id,
		"title": definition.display_name,
		"ready": _active_powered and active_runtime.can_activate(),
		"current": maxf(0.0, maximum - active_runtime.cooldown_remaining),
		"maximum": maximum,
		"powered": _active_powered,
	}

func serialize() -> Dictionary:
	_capture_active_state()
	return {
		"active_instance_id": String(_active_instance_id),
		"equipment_states": _equipment_states.duplicate(true),
		"temporary_effect_id": String(_temporary_effect_id),
		"temporary_left": _temporary_left,
		"repair_rate": _repair_rate,
		"temporary_modifiers": _temporary_modifiers.duplicate(true),
	}

func restore(data: Dictionary) -> void:
	if data.is_empty():
		return
	var raw_states: Variant = data.get("equipment_states", {})
	_equipment_states = raw_states.duplicate(true) if raw_states is Dictionary else {}
	_rebuild_loadout()
	if _active_instance_id != &"" and _equipment_states.has(String(_active_instance_id)):
		active_runtime.restore_state(_equipment_states[String(_active_instance_id)])
	_temporary_effect_id = StringName(data.get("temporary_effect_id", ""))
	_temporary_left = maxf(0.0, float(data.get("temporary_left", 0.0)))
	_repair_rate = maxf(0.0, float(data.get("repair_rate", 0.0)))
	var raw_temporary_modifiers: Variant = data.get("temporary_modifiers", {})
	_temporary_modifiers = raw_temporary_modifiers.duplicate(true) if raw_temporary_modifiers is Dictionary else {}
	if _temporary_effect_id == &"" or _temporary_left <= 0.0:
		_temporary_modifiers.clear()
	_apply_runtime_modifiers()
	_emit_active_state()

func _rebuild_loadout() -> void:
	if inventory == null or inventory.backpack == null:
		return
	var synergy := inventory.synergy_summary()
	var powered_items: Dictionary = synergy.get("powered_items", {})
	var modules: Array[PassiveModuleDefinition] = []
	for entry in inventory.entries():
		var instance_id := StringName(entry.get("instance_id", ""))
		if instance_id == &"" or StringName(entry.get("category", "")) != &"passive":
			continue
		var definition := inventory.definition_for(StringName(entry.get("definition_id", ""))) as PassiveModuleDefinition
		if definition == null:
			continue
		if definition.requires_power and not bool(powered_items.get(instance_id, false)):
			continue
		modules.append(definition)
	passive_runtime.set_modules(modules)
	_apply_runtime_modifiers()
	_rebuild_active(powered_items)
	var summary := passive_runtime.summary()
	summary["active_passive_ids"] = _active_passive_ids(modules)
	summary["synergy"] = synergy
	summary["active_equipment"] = active_progress()
	loadout_changed.emit(summary)

func _rebuild_active(powered_items: Dictionary) -> void:
	var entry := inventory.active_equipment_entry()
	var next_instance := StringName(entry.get("instance_id", ""))
	var next_definition := inventory.definition_for(StringName(entry.get("definition_id", ""))) as ActiveEquipmentDefinition if not entry.is_empty() else null
	var next_powered := false
	if next_definition != null:
		next_powered = not next_definition.requires_power or bool(powered_items.get(next_instance, false))
	if next_instance != _active_instance_id:
		_capture_active_state()
		_active_instance_id = next_instance
		active_runtime.equip(next_definition)
		if _equipment_states.has(String(next_instance)):
			active_runtime.restore_state(_equipment_states[String(next_instance)])
	_active_powered = next_powered
	if not _active_powered and _temporary_effect_id != &"":
		_finish_temporary_effect(false)
	_emit_active_state()

func _capture_active_state() -> void:
	if _active_instance_id == &"" or active_runtime.equipment == null:
		return
	_equipment_states[String(_active_instance_id)] = active_runtime.snapshot()

func _apply_runtime_modifiers() -> void:
	var modifiers := passive_runtime.aggregated_stats.duplicate(true)
	for key in _temporary_modifiers.keys():
		if String(key).ends_with("_mult"):
			modifiers[key] = float(modifiers.get(key, 1.0)) * float(_temporary_modifiers[key])
		else:
			modifiers[key] = float(modifiers.get(key, 0.0)) + float(_temporary_modifiers[key])
	if weapon != null:
		weapon.set_equipment_modifiers(modifiers)
	if player != null:
		player.set_equipment_modifiers(modifiers)

func _on_equipment_activated(_equipment_id: StringName, payload: Dictionary) -> void:
	var effect_id := StringName(payload.get("effect", ""))
	match effect_id:
		&"repair_over_time":
			_start_repair(float(payload.get("amount", 24.0)), float(payload.get("duration", 4.0)))
		&"overclock":
			_start_overclock(payload)
		&"shield_pulse":
			_apply_shield_pulse(float(payload.get("amount", 25.0)))
		&"vent_purge":
			_apply_vent_purge(float(payload.get("heat_removed", 55.0)))
	_capture_active_state()
	_emit_active_state()

func _start_repair(amount: float, duration: float) -> void:
	if amount <= 0.0 or duration <= 0.0:
		return
	_finish_temporary_effect(false)
	_temporary_effect_id = &"repair_over_time"
	_temporary_left = duration
	_repair_rate = amount / duration
	active_effect_started.emit(_temporary_effect_id, duration)

func _start_overclock(payload: Dictionary) -> void:
	var duration := maxf(0.1, float(payload.get("duration", 4.0)))
	_finish_temporary_effect(false)
	_temporary_effect_id = &"overclock"
	_temporary_left = duration
	_temporary_modifiers = {
		"damage_mult": maxf(0.0, float(payload.get("damage_mult", 1.20))),
		"fire_rate_mult": maxf(0.01, float(payload.get("fire_rate_mult", 1.25))),
		"end_overheat": maxf(0.0, float(payload.get("end_overheat", 1.35))),
	}
	_apply_runtime_modifiers()
	active_effect_started.emit(_temporary_effect_id, duration)

func _apply_shield_pulse(amount: float) -> void:
	if player == null or amount <= 0.0:
		return
	player.add_temporary_shield(amount)
	active_effect_started.emit(&"shield_pulse", 0.0)
	active_effect_ended.emit(&"shield_pulse", true)

func _apply_vent_purge(heat_removed: float) -> void:
	if weapon == null or heat_removed <= 0.0:
		return
	weapon.heat = maxf(0.0, weapon.heat - heat_removed)
	weapon.heat_changed.emit(weapon.heat, weapon.max_heat)
	active_effect_started.emit(&"vent_purge", 0.0)
	active_effect_ended.emit(&"vent_purge", true)

func _finish_temporary_effect(completed: bool) -> void:
	if _temporary_effect_id == &"":
		return
	var ended_id := _temporary_effect_id
	var overheat_duration := float(_temporary_modifiers.get("end_overheat", 0.0))
	_temporary_effect_id = &""
	_temporary_left = 0.0
	_repair_rate = 0.0
	_temporary_modifiers.clear()
	_apply_runtime_modifiers()
	if completed and ended_id == &"overclock" and weapon != null:
		weapon.force_overheat(overheat_duration)
	active_effect_ended.emit(ended_id, completed)

func _on_player_damaged(_amount: float) -> void:
	if _temporary_effect_id == &"repair_over_time":
		_finish_temporary_effect(false)

func _on_cooldown_changed(_equipment_id: StringName, _remaining: float, _maximum: float) -> void:
	_capture_active_state()
	_emit_active_state()

func _emit_active_state() -> void:
	var data := active_progress()
	active_state_changed.emit(StringName(data["id"]), String(data["title"]), bool(data["ready"]), float(data["current"]), float(data["maximum"]), bool(data["powered"]))

func _active_passive_ids(modules: Array[PassiveModuleDefinition]) -> Array[StringName]:
	var result: Array[StringName] = []
	for module in modules:
		if module != null:
			result.append(module.id)
	return result
