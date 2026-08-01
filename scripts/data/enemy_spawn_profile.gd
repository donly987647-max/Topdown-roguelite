class_name EnemySpawnProfile
extends Resource

@export var id: StringName
@export var display_name: String
@export var threat_cost: int = 1
@export var tags: PackedStringArray = []
@export var scene_path: String = ""
@export var elite: bool = false

func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	if id == &"": errors.append("enemy id is empty")
	if threat_cost <= 0: errors.append("threat cost must be positive")
	return errors
