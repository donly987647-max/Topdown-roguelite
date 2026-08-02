class_name BackpackGrid
extends RefCounted

const BASE_WIDTH := 6
const BASE_HEIGHT := 5
const MAX_EXTRA_CELLS := 3
const CARDINALS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var width := BASE_WIDTH
var height := BASE_HEIGHT
var extra_cells: Array[Vector2i] = []
var placements: Dictionary = {}
var occupancy: Dictionary = {}

func can_place(item_id: StringName, cells: Array[Vector2i], origin: Vector2i) -> bool:
	for local_cell in cells:
		var cell := origin + local_cell
		if not _is_available_cell(cell):
			return false
		if occupancy.has(cell) and occupancy[cell] != item_id:
			return false
	return true

func place(item_id: StringName, cells: Array[Vector2i], origin: Vector2i) -> bool:
	return _place_internal(item_id, cells, origin, null, 0)

func place_item(item: BackpackItemDefinition, origin: Vector2i, rotation_quarters: int = 0) -> bool:
	if item == null:
		return false
	var cells := _definition_cells(item)
	var turns := posmod(rotation_quarters, 4)
	if not item.rotatable:
		turns = 0
	for _i in range(turns):
		cells = rotate_cells(cells, true)
	return _place_internal(item.id, cells, origin, item, turns)

func _place_internal(item_id: StringName, cells: Array[Vector2i], origin: Vector2i, item: BackpackItemDefinition, rotation_quarters: int) -> bool:
	if item_id == &"" or cells.is_empty() or not can_place(item_id, cells, origin):
		return false
	remove(item_id)
	var absolute_cells: Array[Vector2i] = []
	for local_cell in cells:
		var cell := origin + local_cell
		absolute_cells.append(cell)
		occupancy[cell] = item_id
	placements[item_id] = {
		"id": item_id,
		"item": item,
		"origin": origin,
		"local_cells": cells.duplicate(),
		"cells": absolute_cells,
		"rotation": rotation_quarters,
	}
	return true

func remove(item_id: StringName) -> bool:
	if not placements.has(item_id):
		return false
	for cell in placements[item_id]["cells"]:
		if occupancy.get(cell) == item_id:
			occupancy.erase(cell)
	placements.erase(item_id)
	return true

func rotate_item(item_id: StringName, clockwise: bool = true) -> bool:
	if not placements.has(item_id):
		return false
	var placed: Dictionary = placements[item_id]
	var item: BackpackItemDefinition = placed.get("item")
	if item == null or not item.rotatable:
		return false
	var cells: Array[Vector2i] = placed["local_cells"]
	var rotated := rotate_cells(cells, clockwise)
	var next_rotation := posmod(int(placed.get("rotation", 0)) + (1 if clockwise else -1), 4)
	return _place_internal(item_id, rotated, placed["origin"], item, next_rotation)

func rotate_cells(cells: Array[Vector2i], clockwise: bool = true) -> Array[Vector2i]:
	var rotated: Array[Vector2i] = []
	for cell in cells:
		rotated.append(Vector2i(-cell.y, cell.x) if clockwise else Vector2i(cell.y, -cell.x))
	return _normalize_shape(rotated)

func add_expansion_cell(cell: Vector2i) -> bool:
	if extra_cells.size() >= MAX_EXTRA_CELLS:
		return false
	if _inside_base(cell) or cell in extra_cells:
		return false
	if not _touches_available_cell(cell):
		return false
	extra_cells.append(cell)
	return true

func item_at(cell: Vector2i) -> StringName:
	return occupancy.get(cell, &"")

func placement(item_id: StringName) -> Dictionary:
	return placements.get(item_id, {})

func items() -> Array:
	var result: Array = []
	for id in placements.keys():
		var placed: Dictionary = placements[id]
		if placed.get("item") != null:
			result.append(placed)
	return result

func are_adjacent(a: Dictionary, b: Dictionary) -> bool:
	for a_cell in a.get("cells", []):
		for direction in CARDINALS:
			if a_cell + direction in b.get("cells", []):
				return true
	return false

func adjacent_items(item_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	if not placements.has(item_id):
		return result
	for cell in placements[item_id]["cells"]:
		for direction in CARDINALS:
			var other: StringName = item_at(cell + direction)
			if other != &"" and other != item_id and other not in result:
				result.append(other)
	return result

func connector_world_ports(placed: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var item: BackpackItemDefinition = placed.get("item")
	if item == null:
		return result
	var connectors: Dictionary = item.connector_types
	for key in connectors.keys():
		var raw = connectors[key]
		var connector_type := StringName()
		var local_cell := Vector2i.ZERO
		var direction := _direction_from_name(String(key))
		if raw is Dictionary:
			connector_type = StringName(raw.get("type", ""))
			local_cell = _vector2i_from_variant(raw.get("cell", Vector2i.ZERO))
			if raw.has("direction"):
				direction = _direction_from_name(String(raw["direction"]))
		else:
			connector_type = StringName(raw)
			local_cell = _edge_cell_for_direction(placed.get("local_cells", []), direction)
		if connector_type == &"" or direction == Vector2i.ZERO:
			continue
		var rotation := int(placed.get("rotation", 0))
		var rotated_direction := direction
		for _i in range(rotation):
			rotated_direction = Vector2i(-rotated_direction.y, rotated_direction.x)
		var rotated_local := _rotate_local_cell(local_cell, placed.get("local_cells", []), rotation)
		var world_cell: Vector2i = placed["origin"] + rotated_local
		result.append({
			"item_id": StringName(placed.get("id", item.id)),
			"definition_id": item.id,
			"type": connector_type,
			"cell": world_cell,
			"direction": rotated_direction,
			"target_cell": world_cell + rotated_direction,
		})
	return result

func _definition_cells(item: BackpackItemDefinition) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in item.cells:
		result.append(Vector2i(int(round(cell.x)), int(round(cell.y))))
	return _normalize_shape(result)

func _rotate_local_cell(cell: Vector2i, original_cells: Array, turns: int) -> Vector2i:
	var current := cell
	var shape: Array[Vector2i] = []
	for value in original_cells:
		shape.append(value)
	for _i in range(turns):
		var rotated_shape := rotate_cells(shape, true)
		var raw_rotated := Vector2i(-current.y, current.x)
		var raw_shape: Array[Vector2i] = []
		for old_cell in shape:
			raw_shape.append(Vector2i(-old_cell.y, old_cell.x))
		var min_x := 0
		var min_y := 0
		if not raw_shape.is_empty():
			min_x = raw_shape[0].x
			min_y = raw_shape[0].y
			for rc in raw_shape:
				min_x = mini(min_x, rc.x)
				min_y = mini(min_y, rc.y)
		current = Vector2i(raw_rotated.x - min_x, raw_rotated.y - min_y)
		shape = rotated_shape
	return current

func _edge_cell_for_direction(cells: Array, direction: Vector2i) -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO
	var best: Vector2i = cells[0]
	for value in cells:
		var cell: Vector2i = value
		if direction == Vector2i.LEFT and cell.x < best.x:
			best = cell
		elif direction == Vector2i.RIGHT and cell.x > best.x:
			best = cell
		elif direction == Vector2i.UP and cell.y < best.y:
			best = cell
		elif direction == Vector2i.DOWN and cell.y > best.y:
			best = cell
	return best

func _direction_from_name(value: String) -> Vector2i:
	match value.to_lower():
		"left", "west", "w": return Vector2i.LEFT
		"right", "east", "e": return Vector2i.RIGHT
		"up", "north", "n": return Vector2i.UP
		"down", "south", "s": return Vector2i.DOWN
	return Vector2i.ZERO

func _vector2i_from_variant(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(int(round(value.x)), int(round(value.y)))
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO

func _inside_base(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height

func _is_available_cell(cell: Vector2i) -> bool:
	return _inside_base(cell) or cell in extra_cells

func _touches_available_cell(cell: Vector2i) -> bool:
	for direction in CARDINALS:
		if _is_available_cell(cell + direction):
			return true
	return false

func _normalize_shape(cells: Array[Vector2i]) -> Array[Vector2i]:
	if cells.is_empty():
		return cells
	var min_x := cells[0].x
	var min_y := cells[0].y
	for cell in cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
	var normalized: Array[Vector2i] = []
	for cell in cells:
		normalized.append(Vector2i(cell.x - min_x, cell.y - min_y))
	return normalized
