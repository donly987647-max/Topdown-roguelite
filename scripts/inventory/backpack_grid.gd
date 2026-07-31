class_name BackpackGrid
extends RefCounted

const WIDTH := 6
const HEIGHT := 5
const TERMINAL_CELLS := {
	"power": Vector2i(0, 0),
	"ammo": Vector2i(5, 1),
	"cooling": Vector2i(0, 4),
	"signal": Vector2i(5, 4)
}
const CARDINALS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var items: Dictionary = {}
var placements: Dictionary = {}
var _serial := 0

func add_part(part: WeaponPartData, requested_id: StringName = &"") -> StringName:
	if part == null:
		return &""
	_serial += 1
	var item_id := requested_id
	if item_id == &"":
		item_id = StringName("%s_%03d" % [part.part_id, _serial])
	while items.has(item_id):
		_serial += 1
		item_id = StringName("%s_%03d" % [part.part_id, _serial])
	items[item_id] = BackpackItemData.from_weapon_part(part, item_id)
	return item_id

func add_and_auto_place(part: WeaponPartData, requested_id: StringName = &"") -> StringName:
	var item_id := add_part(part, requested_id)
	if item_id != &"":
		auto_place(item_id)
	return item_id

func get_item(item_id: StringName) -> BackpackItemData:
	return items.get(item_id) as BackpackItemData

func get_item_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for key in items:
		result.append(StringName(key))
	return result

func get_unplaced_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for item_id in get_item_ids():
		if not placements.has(item_id):
			result.append(item_id)
	return result

func has_unplaced_items() -> bool:
	return not get_unplaced_ids().is_empty()

func get_placement(item_id: StringName) -> Dictionary:
	return (placements.get(item_id, {}) as Dictionary).duplicate(true)

func get_item_cells(item_id: StringName) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var item := get_item(item_id)
	if item == null or not placements.has(item_id):
		return result
	var placement: Dictionary = placements[item_id]
	var origin: Vector2i = placement.get("origin", Vector2i.ZERO)
	var rotation := int(placement.get("rotation", 0))
	for relative_cell in item.cells_for_rotation(rotation):
		result.append(origin + relative_cell)
	return result

func get_occupied_map(excluded_id: StringName = &"") -> Dictionary:
	var occupied: Dictionary = {}
	for item_id in placements:
		var typed_id := StringName(item_id)
		if typed_id == excluded_id:
			continue
		for cell in get_item_cells(typed_id):
			occupied[cell] = typed_id
	return occupied

func get_item_at(cell: Vector2i) -> StringName:
	return StringName(get_occupied_map().get(cell, &""))

func can_place(item_id: StringName, origin: Vector2i, rotation: int = 0) -> bool:
	var item := get_item(item_id)
	if item == null:
		return false
	var occupied := get_occupied_map(item_id)
	for relative_cell in item.cells_for_rotation(rotation):
		var cell := origin + relative_cell
		if cell.x < 0 or cell.y < 0 or cell.x >= WIDTH or cell.y >= HEIGHT:
			return false
		if occupied.has(cell):
			return false
	return true

func place_item(item_id: StringName, origin: Vector2i, rotation: int = 0) -> bool:
	if not can_place(item_id, origin, rotation):
		return false
	placements[item_id] = {
		"origin": origin,
		"rotation": posmod(rotation, 4)
	}
	return true

func unplace_item(item_id: StringName) -> bool:
	if not placements.has(item_id):
		return false
	placements.erase(item_id)
	return true

func rotate_item(item_id: StringName) -> bool:
	if not placements.has(item_id):
		return false
	var placement: Dictionary = placements[item_id]
	var origin: Vector2i = placement.get("origin", Vector2i.ZERO)
	var next_rotation := posmod(int(placement.get("rotation", 0)) + 1, 4)
	return place_item(item_id, origin, next_rotation)

func auto_place(item_id: StringName, preferred_rotation: int = 0) -> bool:
	if get_item(item_id) == null:
		return false
	for offset in range(4):
		var rotation := posmod(preferred_rotation + offset, 4)
		for y in range(HEIGHT):
			for x in range(WIDTH):
				if place_item(item_id, Vector2i(x, y), rotation):
					return true
	return false

func remove_item(item_id: StringName) -> WeaponPartData:
	var item := get_item(item_id)
	if item == null:
		return null
	placements.erase(item_id)
	items.erase(item_id)
	return item.part.duplicate_part() if item.part != null else null

func auto_arrange() -> bool:
	var backup := create_snapshot()
	placements.clear()
	var ordered_ids := get_item_ids()
	ordered_ids.sort_custom(func(left: StringName, right: StringName) -> bool:
		var left_item := get_item(left)
		var right_item := get_item(right)
		var left_count := left_item.cell_count() if left_item != null else 0
		var right_count := right_item.cell_count() if right_item != null else 0
		if left_count == right_count:
			return String(left) < String(right)
		return left_count > right_count
	)
	for item_id in ordered_ids:
		if not auto_place(item_id):
			restore_snapshot(backup)
			return false
	return true

func create_snapshot() -> Dictionary:
	var item_copies: Dictionary = {}
	for item_id in items:
		var item := items[item_id] as BackpackItemData
		item_copies[item_id] = item.duplicate_item() if item != null else null
	return {
		"items": item_copies,
		"placements": placements.duplicate(true),
		"serial": _serial
	}

func restore_snapshot(snapshot: Dictionary) -> void:
	items.clear()
	placements.clear()
	var snapshot_items: Dictionary = snapshot.get("items", {})
	for item_id in snapshot_items:
		var item := snapshot_items[item_id] as BackpackItemData
		items[item_id] = item.duplicate_item() if item != null else null
	placements = (snapshot.get("placements", {}) as Dictionary).duplicate(true)
	_serial = int(snapshot.get("serial", 0))

func evaluate_connections() -> Dictionary:
	var occupied := get_occupied_map()
	var active: Dictionary = {}
	for connector_name in TERMINAL_CELLS:
		var connector := String(connector_name)
		var terminal_cell: Vector2i = TERMINAL_CELLS[connector_name]
		var seed_id := StringName(occupied.get(terminal_cell, &""))
		if seed_id == &"" or not _item_has_connector(seed_id, connector):
			continue
		var queue: Array[StringName] = [seed_id]
		var visited: Dictionary = {}
		while not queue.is_empty():
			var item_id := queue.pop_front()
			if visited.has(item_id):
				continue
			visited[item_id] = true
			_append_active_connector(active, item_id, connector)
			for cell in get_item_cells(item_id):
				for direction in CARDINALS:
					var neighbor_id := StringName(occupied.get(cell + direction, &""))
					if neighbor_id == &"" or neighbor_id == item_id or visited.has(neighbor_id):
						continue
					if _item_has_connector(neighbor_id, connector):
						queue.append(neighbor_id)
	return active

func get_metrics() -> Dictionary:
	var occupied_cells := get_occupied_map().size()
	return {
		"width": WIDTH,
		"height": HEIGHT,
		"capacity": WIDTH * HEIGHT,
		"occupied_cells": occupied_cells,
		"free_cells": WIDTH * HEIGHT - occupied_cells,
		"item_count": items.size(),
		"unplaced_count": get_unplaced_ids().size(),
		"connections": evaluate_connections()
	}

func _item_has_connector(item_id: StringName, connector: String) -> bool:
	var item := get_item(item_id)
	return item != null and item.connector_types.has(connector)

func _append_active_connector(active: Dictionary, item_id: StringName, connector: String) -> void:
	var connectors := PackedStringArray()
	if active.has(item_id):
		connectors = active[item_id]
	if not connectors.has(connector):
		connectors.append(connector)
	active[item_id] = connectors
