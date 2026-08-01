class_name ActiveEquipmentRuntime
extends Node

signal equipment_equipped(equipment_id: StringName)
signal equipment_activated(equipment_id: StringName, payload: Dictionary)
signal equipment_cooldown_changed(equipment_id: StringName, remaining: float, maximum: float)
signal equipment_charges_changed(equipment_id: StringName, current: int, maximum: int)

var equipment: ActiveEquipmentDefinition
var cooldown_remaining := 0.0
var charges_remaining := 0

func equip(definition: ActiveEquipmentDefinition) -> void:
	equipment = definition
	cooldown_remaining = 0.0
	charges_remaining = 0 if definition == null else maxi(0, definition.charges)
	if equipment != null:
		equipment_equipped.emit(equipment.id)
		equipment_charges_changed.emit(equipment.id, charges_remaining, equipment.charges)

func _process(delta: float) -> void:
	if equipment == null or cooldown_remaining <= 0.0:
		return
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	equipment_cooldown_changed.emit(equipment.id, cooldown_remaining, equipment.cooldown)

func can_activate() -> bool:
	if equipment == null or cooldown_remaining > 0.0:
		return false
	return equipment.charges <= 0 or charges_remaining > 0

func activate(context: Dictionary = {}) -> bool:
	if not can_activate():
		return false
	if equipment.charges > 0:
		charges_remaining -= 1
		equipment_charges_changed.emit(equipment.id, charges_remaining, equipment.charges)
	cooldown_remaining = maxf(0.0, equipment.cooldown)
	var payload := equipment.activation_payload.duplicate(true)
	payload["equipment_id"] = equipment.id
	payload["effect_ids"] = equipment.effect_ids
	for key in context.keys():
		payload[key] = context[key]
	equipment_activated.emit(equipment.id, payload)
	return true

func refill_charges(amount: int = -1) -> void:
	if equipment == null or equipment.charges <= 0:
		return
	if amount < 0:
		charges_remaining = equipment.charges
	else:
		charges_remaining = mini(equipment.charges, charges_remaining + amount)
	equipment_charges_changed.emit(equipment.id, charges_remaining, equipment.charges)

func reset_cooldown() -> void:
	if equipment == null:
		return
	cooldown_remaining = 0.0
	equipment_cooldown_changed.emit(equipment.id, cooldown_remaining, equipment.cooldown)
