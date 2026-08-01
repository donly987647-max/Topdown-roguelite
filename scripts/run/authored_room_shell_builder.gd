class_name AuthoredRoomShellBuilder
extends RefCounted

var tile_world_size := 64.0

func build(template: RoomTemplateDefinition) -> Node2D:
	var root := Node2D.new()
	root.name = "Room_%s" % String(template.id)
	root.set_meta("authored_room_shell", true)
	_build_boundary(root, template.tile_size)
	for cell in template.obstacle_cells:
		_add_block(root, cell, false)
	for cell in template.hazard_cells:
		_add_hazard(root, cell)
	for cell in template.enemy_spawn_cells:
		_add_marker(root, cell, template.spawn_group, "Spawn")
	for cell in template.entrance_cells:
		_add_marker(root, cell, template.entrance_group, "Entrance")
	for cell in template.exit_cells:
		_add_exit(root, cell, template.exit_group)
	return root

func _build_boundary(root: Node2D, size: Vector2i) -> void:
	for x in range(size.x):
		_add_block(root, Vector2i(x, 0), true)
		_add_block(root, Vector2i(x, size.y - 1), true)
	for y in range(1, size.y - 1):
		_add_block(root, Vector2i(0, y), true)
		_add_block(root, Vector2i(size.x - 1, y), true)

func _add_block(root: Node2D, cell: Vector2i, boundary: bool) -> void:
	var body := StaticBody2D.new()
	body.name = "%s_%d_%d" % ["Boundary" if boundary else "Obstacle", cell.x, cell.y]
	body.position = _cell_center(cell)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2.ONE * tile_world_size
	shape.shape = rect
	body.add_child(shape)
	root.add_child(body)

func _add_hazard(root: Node2D, cell: Vector2i) -> void:
	var area := Area2D.new()
	area.name = "Hazard_%d_%d" % [cell.x, cell.y]
	area.position = _cell_center(cell)
	area.add_to_group("room_hazard")
	area.set_meta("hazard_cell", cell)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2.ONE * tile_world_size * 0.85
	shape.shape = rect
	area.add_child(shape)
	root.add_child(area)

func _add_marker(root: Node2D, cell: Vector2i, group_name: StringName, prefix: String) -> void:
	var marker := Marker2D.new()
	marker.name = "%s_%d_%d" % [prefix, cell.x, cell.y]
	marker.position = _cell_center(cell)
	if group_name != &"": marker.add_to_group(group_name)
	root.add_child(marker)

func _add_exit(root: Node2D, cell: Vector2i, group_name: StringName) -> void:
	var gate := RoomExitGate.new()
	gate.name = "Exit_%d_%d" % [cell.x, cell.y]
	gate.position = _cell_center(cell)
	gate.starts_locked = true
	gate.disable_collision_when_locked = false
	if group_name != &"": gate.add_to_group(group_name)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tile_world_size * 0.8, tile_world_size * 0.8)
	shape.shape = rect
	gate.add_child(shape)
	root.add_child(gate)

func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x + 0.5, cell.y + 0.5) * tile_world_size
