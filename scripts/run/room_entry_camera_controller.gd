class_name RoomEntryCameraController
extends Node

@export var tile_world_size: float = 64.0

func place_player(player: Node2D, room_root: Node, template: RoomTemplateDefinition, preferred_index: int = 0) -> bool:
	if player == null or room_root == null or template == null:
		return false
	var points := _group_points(room_root, template.entrance_group)
	if points.is_empty():
		for cell in template.entrance_cells:
			points.append(_cell_to_world(room_root, cell))
	if points.is_empty():
		return false
	player.global_position = points[clampi(preferred_index, 0, points.size() - 1)]
	return true

func apply_camera_bounds(camera: Camera2D, room_root: Node, template: RoomTemplateDefinition) -> bool:
	if camera == null or room_root == null or template == null:
		return false
	var rect := template.camera_bounds
	var origin := _cell_origin_to_world(room_root, rect.position)
	camera.limit_left = int(round(origin.x))
	camera.limit_top = int(round(origin.y))
	camera.limit_right = int(round(origin.x + rect.size.x * tile_world_size))
	camera.limit_bottom = int(round(origin.y + rect.size.y * tile_world_size))
	return true

func _group_points(room_root: Node, group_name: StringName) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if group_name == &"" or room_root.get_tree() == null:
		return points
	for node in room_root.get_tree().get_nodes_in_group(group_name):
		if node is Node2D and room_root.is_ancestor_of(node):
			points.append((node as Node2D).global_position)
	return points

func _cell_to_world(room_root: Node, cell: Vector2i) -> Vector2:
	var local := Vector2(cell.x + 0.5, cell.y + 0.5) * tile_world_size
	if room_root is Node2D:
		return (room_root as Node2D).to_global(local)
	return local

func _cell_origin_to_world(room_root: Node, cell: Vector2i) -> Vector2:
	var local := Vector2(cell.x, cell.y) * tile_world_size
	if room_root is Node2D:
		return (room_root as Node2D).to_global(local)
	return local
