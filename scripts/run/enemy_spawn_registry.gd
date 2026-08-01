class_name EnemySpawnRegistry
extends RefCounted

var scenes: Dictionary = {}

func register_enemy(enemy_id: StringName, scene: PackedScene) -> void:
	if enemy_id != &"" and scene != null:
		scenes[enemy_id] = scene

func register_path(enemy_id: StringName, scene_path: String) -> bool:
	if enemy_id == &"" or scene_path.is_empty():
		return false
	var resource := load(scene_path)
	if not (resource is PackedScene):
		return false
	scenes[enemy_id] = resource
	return true

func has_enemy(enemy_id: StringName) -> bool:
	return scenes.has(enemy_id)

func instantiate(enemy_id: StringName) -> Node:
	var scene: PackedScene = scenes.get(enemy_id)
	if scene == null:
		return null
	var instance := scene.instantiate()
	if instance != null:
		instance.set_meta("enemy_id", enemy_id)
	return instance

func missing_ids(entries: Array) -> Array[StringName]:
	var missing: Array[StringName] = []
	for entry in entries:
		var enemy_id := _entry_id(entry)
		if enemy_id != &"" and not scenes.has(enemy_id) and enemy_id not in missing:
			missing.append(enemy_id)
	return missing

func _entry_id(entry: Variant) -> StringName:
	if entry is Dictionary:
		return StringName(entry.get("enemy_id", entry.get("id", "")))
	if entry is StringName:
		return entry
	if entry is String:
		return StringName(entry)
	return &""
