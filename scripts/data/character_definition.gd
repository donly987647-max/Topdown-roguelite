class_name CharacterDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var role: String
@export var max_health: float = 100.0
@export var move_speed_multiplier: float = 1.0
@export var starting_guard: int = 0
@export var crit_bonus: float = 0.0
@export var status_buildup_multiplier: float = 1.0
@export var healing_multiplier: float = 1.0
@export var starting_scrap: int = 0
@export var shop_price_multiplier: float = 1.0
@export var starting_frame_id: StringName
@export var passive_id: StringName
@export var active_id: StringName
@export var passive_description: String
@export var active_description: String
@export var playstyle: PackedStringArray = []
@export var secret: bool = false
@export var unlock_key: StringName

func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	if id == &"": errors.append("character id is empty")
	if display_name.is_empty(): errors.append("character display_name is empty")
	if max_health <= 0.0: errors.append("max_health must be positive")
	if move_speed_multiplier <= 0.0: errors.append("move speed multiplier must be positive")
	if starting_frame_id == &"": errors.append("starting frame is empty")
	return errors
