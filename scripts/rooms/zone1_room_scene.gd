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
	var floor := Polygon2D.new()
	floor.name = "Floor"
	floor.z_index = -20
	floor.polygon = PackedVector2Array([Vector2.ZERO, Vector2(template.tile_size.x * tile_world_size,0), Vector2(template.tile_size.x * tile_world_size, template.tile_size.y * tile_world_size), Vector2(0, template.tile_size.y * tile_world_size)])
	floor.color = Color(0.06,0.065,0.075,1.0)
	add_child(floor)
	move_child(floor, 0)
