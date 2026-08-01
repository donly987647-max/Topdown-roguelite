class_name BackpackState
extends RefCounted

const SAVE_VERSION := 1

var grid := BackpackGrid.new()
var definitions: Dictionary = {}
var instance_to_definition: Dictionary = {}
var _next_instance_serial := 1

func register_definition(definition: BackpackItemDefinition) -> void:
	if definition != null and definition.id != &"":
		definitions[definition.id] = definition

func add_item(definition_id: StringName, origin: Vector2i, rotation_quarters: int = 0, instance_id: StringName = &"") -> StringName:
	var definition: BackpackItemDefinition = definitions.get(definition_id)
	if definition == null:
		return &""
	var resolved_id := instance_id if instance_id != &"" else _allocate_instance_id(definition_id)
	if grid.placements.has(resolved_id):
		return &""
	var cells := _rotated_cells(definition, rotation_quarters)
	if not grid.can_place(resolved_id, cells, origin):
		return &""
	if not grid._place_internal(resolved_id, cells, origin, definition, posmod(rotation_quarters, 4)):
		return &""
	instance_to_definition[resolved_id] = definition_id
	return resolved_id

func remove_item(instance_id: StringName) -> bool:
	if not grid.remove(instance_id):
		return false
	instance_to_definition.erase(instance_id)
	return true

func auto_place(definition_id: StringName, rotation_allowed: bool = true) -> StringName:
	var definition: BackpackItemDefinition = definitions.get(definition_id)
	if definition == null:
		return &""
	var rotations := 4 if rotation_allowed and definition.rotatable else 1
	for turn in range(rotations):
		var cells := _rotated_cells(definition, turn)
		for y in range(grid.height):
			for x in range(grid.width):
				var origin := Vector2i(x, y)
				var probe_id := StringName("__probe__")
				if grid.can_place(probe_id, cells, origin):
					return add_item(definition_id, origin, turn)
	for expansion in grid.extra_cells:
		for turn in range(rotations):
			var cells := _rotated_cells(definition, turn)
			if grid.can_place(StringName("__probe__"), cells, expansion):
				return add_item(definition_id, expansion, turn)
	return &""

func serialize() -> Dictionary:
	var placed_items: Array = []
	for instance_id in grid.placements.keys():
		var placed: Dictionary = grid.placements[instance_id]
		var definition_id: StringName = instance_to_definition.get(instance_id, &"")
		if definition_id == &"":
			continue
		placed_items.append({
			"instance_id": String(instance_id),
			"definition_id": String(definition_id),
			"origin": [placed["origin"].x, placed["origin"].y],
			"rotation": int(placed.get("rotation", 0)),
		})
	var expansions: Array = []
	for cell in grid.extra_cells:
		expansions.append([cell.x, cell.y])
	return {
		"version": SAVE_VERSION,
		"next_instance_serial": _next_instance_serial,
		"expansion_cells": expansions,
		"items": placed_items,
	}

func restore(data: Dictionary) -> bool:
	if int(data.get("version", -1)) != SAVE_VERSION:
		return false
	var restored_grid := BackpackGrid.new()
	for raw_cell in data.get("expansion_cells", []):
		if not (raw_cell is Array) or raw_cell.size() < 2:
			return false
		if not restored_grid.add_expansion_cell(Vector2i(int(raw_cell[0]), int(raw_cell[1]))):
			return false
	var old_grid := grid
	var old_map := instance_to_definition.duplicate()
	grid = restored_grid
	instance_to_definition.clear()
	for raw_item in data.get("items", []):
		if not (raw_item is Dictionary):
			grid = old_grid
			instance_to_definition = old_map
			return false
		var definition_id := StringName(raw_item.get("definition_id", ""))
		var instance_id := StringName(raw_item.get("instance_id", ""))
		var raw_origin = raw_item.get("origin", [])
		if instance_id == &"" or definition_id == &"" or not (raw_origin is Array) or raw_origin.size() < 2:
			grid = old_grid
			instance_to_definition = old_map
			return false
		var origin := Vector2i(int(raw_origin[0]), int(raw_origin[1]))
		if add_item(definition_id, origin, int(raw_item.get("rotation", 0)), instance_id) == &"":
			grid = old_grid
			instance_to_definition = old_map
			return false
	_next_instance_serial = maxi(1, int(data.get("next_instance_serial", 1)))
	return true

func _allocate_instance_id(definition_id: StringName) -> StringName:
	while true:
		var candidate := StringName("%s#%d" % [String(definition_id), _next_instance_serial])
		_next_instance_serial += 1
		if not grid.placements.has(candidate):
			return candidate
	return &""

func _rotated_cells(definition: BackpackItemDefinition, turns: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for raw_cell in definition.cells:
		cells.append(Vector2i(int(round(raw_cell.x)), int(round(raw_cell.y))))
	cells = grid._normalize_shape(cells)
	var count := posmod(turns, 4) if definition.rotatable else 0
	for _i in range(count):
		cells = grid.rotate_cells(cells, true)
	return cells
