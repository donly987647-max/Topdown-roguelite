class_name WeaponPartData
extends Resource

enum Slot {
	BARREL,
	MAGAZINE,
	CORE
}

@export var part_id: StringName = &""
@export var display_name := ""
@export var slot: Slot = Slot.BARREL
@export var power_cost := 0
@export var weight := 0.0
@export var stat_multipliers: Dictionary = {}
@export var stat_additions: Dictionary = {}
@export var effects: Dictionary = {}
@export var tags := PackedStringArray()

func duplicate_part() -> WeaponPartData:
	return duplicate(true) as WeaponPartData

func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if part_id == &"":
		errors.append("part_id is empty")
	if display_name.is_empty():
		errors.append("display_name is empty")
	if slot < Slot.BARREL or slot > Slot.CORE:
		errors.append("slot is invalid")
	if power_cost < 0:
		errors.append("power_cost cannot be negative")
	if weight < 0.0:
		errors.append("weight cannot be negative")
	for key in stat_multipliers:
		if float(stat_multipliers[key]) <= 0.0:
			errors.append("stat multiplier %s must be positive" % key)
	return errors
