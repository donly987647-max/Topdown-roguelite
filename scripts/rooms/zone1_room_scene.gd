class_name Zone1RoomScene
extends Node2D

@export var template_id: StringName
@export var tile_world_size := 32.0

func _ready() -> void:
	var template := Zone1ContentCatalog.new().template_by_id(template_id)
	if template == null:
		push_error("Unknown Zone 1 template: %s" % String(template_id))
		return
	var builder := AuthoredRoomShellBuilder.new()
	builder.tile_world_size = tile_world_size
	builder.build_into(self, template)
	_build_floor(template)

func _build_floor(template: RoomTemplateDefinition) -> void:
	var room_size := Vector2(template.tile_size.x * tile_world_size, template.tile_size.y * tile_world_size)
	var floor := Polygon2D.new()
	floor.name = "Floor"
	floor.z_index = -20
	floor.polygon = PackedVector2Array([Vector2.ZERO, Vector2(room_size.x, 0), room_size, Vector2(0, room_size.y)])
	floor.color = Color(0.035, 0.043, 0.055, 1.0)
	add_child(floor)
	move_child(floor, 0)

	var inset := tile_world_size * 0.65
	var inner := Polygon2D.new()
	inner.name = "FloorInset"
	inner.z_index = -19
	inner.polygon = PackedVector2Array([
		Vector2(inset, inset), Vector2(room_size.x - inset, inset),
		Vector2(room_size.x - inset, room_size.y - inset), Vector2(inset, room_size.y - inset)
	])
	inner.color = Color(0.055, 0.065, 0.078, 1.0)
	add_child(inner)

	_build_floor_grid(room_size)
	_build_hazard_accents(room_size)

func _build_floor_grid(room_size: Vector2) -> void:
	var spacing := tile_world_size * 4.0
	var grid_color := Color(0.16, 0.19, 0.22, 0.24)
	var x := spacing
	while x < room_size.x:
		var line := Line2D.new()
		line.z_index = -18
		line.width = 1.0
		line.default_color = grid_color
		line.points = PackedVector2Array([Vector2(x, 0), Vector2(x, room_size.y)])
		add_child(line)
		x += spacing
	var y := spacing
	while y < room_size.y:
		var line := Line2D.new()
		line.z_index = -18
		line.width = 1.0
		line.default_color = grid_color
		line.points = PackedVector2Array([Vector2(0, y), Vector2(room_size.x, y)])
		add_child(line)
		y += spacing

func _build_hazard_accents(room_size: Vector2) -> void:
	var accent := Color(0.92, 0.45, 0.1, 0.52)
	var margin := tile_world_size * 1.15
	var segment := tile_world_size * 0.72
	var gap := tile_world_size * 0.55
	var x := margin
	while x < room_size.x - margin:
		var top := Line2D.new()
		top.z_index = -17
		top.width = 3.0
		top.default_color = accent
		top.points = PackedVector2Array([Vector2(x, margin), Vector2(minf(x + segment, room_size.x - margin), margin)])
		add_child(top)
		var bottom := Line2D.new()
		bottom.z_index = -17
		bottom.width = 3.0
		bottom.default_color = Color(accent.r, accent.g, accent.b, accent.a * 0.65)
		bottom.points = PackedVector2Array([Vector2(x, room_size.y - margin), Vector2(minf(x + segment, room_size.x - margin), room_size.y - margin)])
		add_child(bottom)
		x += segment + gap

	var center_mark := Line2D.new()
	center_mark.name = "CenterLane"
	center_mark.z_index = -17
	center_mark.width = 2.0
	center_mark.default_color = Color(0.18, 0.72, 0.82, 0.18)
	center_mark.points = PackedVector2Array([
		Vector2(room_size.x * 0.5, margin * 1.5),
		Vector2(room_size.x * 0.5, room_size.y - margin * 1.5)
	])
	add_child(center_mark)
