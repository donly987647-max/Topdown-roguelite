class_name RoomTemplateDefinition
extends Resource

@export var id: StringName
@export var zone_id: StringName
@export var room_type: StringName = &"combat"
@export var size_class: StringName = &"medium"
@export var tile_size: Vector2i = Vector2i(26, 16)
@export var entrance_cells: Array[Vector2i] = []
@export var exit_cells: Array[Vector2i] = []
@export var obstacle_cells: Array[Vector2i] = []
@export var hazard_cells: Array[Vector2i] = []
@export var enemy_spawn_cells: Array[Vector2i] = []
@export_range(1, 3, 1) var wave_count: int = 1
@export var recommended_threat: int = 6
@export var allowed_enemy_tags: PackedStringArray = []
@export var allowed_enemy_ids: PackedStringArray = []
@export var camera_bounds: Rect2i = Rect2i(0, 0, 26, 16)
@export var secret_connection_allowed: bool = false
@export var environment_tags: PackedStringArray = []

func is_combat_room() -> bool:
	return room_type in [&"combat", &"elite", &"boss"]

func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	if id == &"": errors.append("room template id is empty")
	if zone_id == &"": errors.append("zone_id is empty")
	if tile_size.x <= 0 or tile_size.y <= 0: errors.append("tile_size must be positive")
	if is_combat_room() and enemy_spawn_cells.is_empty(): errors.append("combat room requires enemy spawn cells")
	if wave_count < 1 or wave_count > 3: errors.append("wave_count must be 1..3")
	if recommended_threat < 0: errors.append("recommended_threat cannot be negative")
	return errors
