class_name BackpackGrid
extends RefCounted

const BASE_WIDTH := 6
const BASE_HEIGHT := 5
const MAX_EXTRA_CELLS := 3

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
	if not can_place(item_id, cells, origin):
		return false
	remove(item_id)
	var absolute_cells: Array[Vector2i] = []
	for local_cell in cells:
		var cell := origin + local_cell
		absolute_cells.append(cell)
		occupancy[cell] = item_id
	placements[item_id] = {"origin": origin, "cells": absolute_cells}
	return true

func remove(item_id: StringName) -> bool:
	if not placements.has(item_id):
		return false
	for cell in placements[item_id]["cells"]:
		if occupancy.get(cell) == item_id:
			occupancy.erase(cell)
	placements.erase(item_id)
	return true

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

func adjacent_items(item_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	if not placements.has(item_id):
		return result
	for cell in placements[item_id]["cells"]:
		for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var other: StringName = item_at(cell + dir)
			if other != &"" and other != item_id and other not in result:
				result.append(other)
	return result

func _inside_base(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height

func _is_available_cell(cell: Vector2i) -> bool:
	return _inside_base(cell) or cell in extra_cells

func _touches_available_cell(cell: Vector2i) -> bool:
	for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _is_available_cell(cell + dir):
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
