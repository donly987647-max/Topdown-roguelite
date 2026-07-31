class_name BackpackItemData
extends Resource

const VALID_CONNECTORS := ["power", "ammo", "cooling", "signal"]

@export var instance_id: StringName = &""
@export var part: WeaponPartData
@export var base_cells: Array[Vector2i] = [Vector2i.ZERO]
@export var connector_types := PackedStringArray()
@export var requires_connection := false

static func from_weapon_part(part_data: WeaponPartData, requested_id: StringName = &"") -> BackpackItemData:
	var item := BackpackItemData.new()
	item.part = part_data.duplicate_part() if part_data != null else null
	item.instance_id = requested_id
	if item.instance_id == &"" and part_data != null:
		item.instance_id = StringName("%s_%d_%d" % [part_data.part_id, Time.get_ticks_usec(), randi()])
	item._apply_prototype_profile()
	return item

func duplicate_item() -> BackpackItemData:
	var copy := BackpackItemData.new()
	copy.instance_id = instance_id
	copy.part = part.duplicate_part() if part != null else null
	copy.base_cells = base_cells.duplicate()
	copy.connector_types = connector_types.duplicate()
	copy.requires_connection = requires_connection
	return copy

func cells_for_rotation(rotation_steps: int) -> Array[Vector2i]:
	var rotated: Array[Vector2i] = []
	var normalized_steps := posmod(rotation_steps, 4)
	for source_cell in base_cells:
		var cell := source_cell
		for _step in range(normalized_steps):
			cell = Vector2i(-cell.y, cell.x)
		rotated.append(cell)
	if rotated.is_empty():
		return [Vector2i.ZERO]
	var min_x := rotated[0].x
	var min_y := rotated[0].y
	for cell in rotated:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
	for index in rotated.size():
		rotated[index] -= Vector2i(min_x, min_y)
	return rotated

func cell_count() -> int:
	return base_cells.size()

func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if instance_id == &"":
		errors.append("instance_id is empty")
	if part == null:
		errors.append("weapon part is missing")
	if base_cells.is_empty():
		errors.append("base_cells is empty")
	var seen: Dictionary = {}
	for cell in base_cells:
		if seen.has(cell):
			errors.append("base_cells contains duplicates")
			break
		seen[cell] = true
	for connector in connector_types:
		if not VALID_CONNECTORS.has(connector):
			errors.append("unknown connector: %s" % connector)
	return errors

func _apply_prototype_profile() -> void:
	base_cells = [Vector2i.ZERO]
	connector_types = PackedStringArray()
	requires_connection = false
	if part == null:
		return
	match part.part_id:
		&"precision_barrel":
			base_cells = [Vector2i(0, 0), Vector2i(0, 1)]
			connector_types = PackedStringArray(["power", "signal"])
		&"spread_barrel":
			base_cells = [Vector2i(0, 0), Vector2i(1, 0)]
			connector_types = PackedStringArray(["power", "ammo"])
		&"piercing_barrel":
			base_cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
			connector_types = PackedStringArray(["power", "ammo"])
		&"ricochet_barrel":
			base_cells = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]
			connector_types = PackedStringArray(["power", "signal"])
		&"extended_magazine":
			base_cells = [Vector2i(0, 0), Vector2i(0, 1)]
			connector_types = PackedStringArray(["ammo"])
		&"lightweight_magazine":
			base_cells = [Vector2i.ZERO]
			connector_types = PackedStringArray(["ammo"])
		&"compressed_magazine":
			base_cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
			connector_types = PackedStringArray(["ammo", "power"])
		&"reverse_magazine":
			base_cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
			connector_types = PackedStringArray(["ammo", "signal"])
		&"impact_core":
			base_cells = [Vector2i(0, 0), Vector2i(1, 0)]
			connector_types = PackedStringArray(["power"])
		&"photon_core":
			base_cells = [Vector2i(0, 0), Vector2i(0, 1)]
			connector_types = PackedStringArray(["power", "cooling"])
		&"clone_core":
			base_cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]
			connector_types = PackedStringArray(["power", "signal"])
		&"flame_core":
			base_cells = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]
			connector_types = PackedStringArray(["power", "cooling"])
