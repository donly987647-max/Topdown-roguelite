class_name RoomSceneRuntime
extends Node

signal room_loaded(template_id: StringName, room_root: Node)
signal room_unloaded(template_id: StringName)
signal exits_locked(locked: bool)
signal enemy_spawned(enemy: Node, enemy_id: StringName, wave_index: int)
signal room_scene_cleared(template_id: StringName)

@export var tile_world_size: float = 64.0

var encounter := RoomEncounterRuntime.new()
var enemy_registry := EnemySpawnRegistry.new()
var planner := ThreatBudgetPlanner.new()
var template: RoomTemplateDefinition
var room_root: Node
var room_parent: Node
var _spawn_cursor := 0
var _active_enemies: Dictionary = {}
var _room_template_id: StringName = &""

func _ready() -> void:
	encounter.wave_ready.connect(_on_wave_ready)
	encounter.encounter_cleared.connect(_on_encounter_cleared)

func configure(parent: Node, spawn_registry: EnemySpawnRegistry, threat_planner: ThreatBudgetPlanner) -> void:
	room_parent = parent
	if spawn_registry != null:
		enemy_registry = spawn_registry
	if threat_planner != null:
		planner = threat_planner

func load_room(room_template: RoomTemplateDefinition, difficulty_multiplier: float = 1.0) -> bool:
	if room_template == null or room_parent == null:
		return false
	unload_room()
	template = room_template
	_room_template_id = template.id
	room_root = _instantiate_room_root(template)
	if room_root == null:
		return false
	room_parent.add_child(room_root)
	_spawn_cursor = 0
	_active_enemies.clear()
	if not encounter.configure(template, planner, difficulty_multiplier):
		unload_room()
		return false
	set_exits_locked(template.is_combat_room())
	room_loaded.emit(template.id, room_root)
	encounter.start()
	return true

func unload_room() -> void:
	var previous_id := _room_template_id
	_active_enemies.clear()
	if room_root != null and is_instance_valid(room_root):
		room_root.queue_free()
	room_root = null
	_room_template_id = &""
	template = null
	if previous_id != &"":
		room_unloaded.emit(previous_id)

func _instantiate_room_root(room_template: RoomTemplateDefinition) -> Node:
	if room_template.has_scene():
		var resource := load(room_template.scene_path)
		if resource is PackedScene:
			return resource.instantiate()
	var fallback := Node2D.new()
	fallback.name = "Room_%s" % String(room_template.id)
	fallback.set_meta("generated_room_shell", true)
	return fallback

func _on_wave_ready(wave_index: int, entries: Array, spawn_cells: Array[Vector2i]) -> void:
	var spawn_points := _resolve_spawn_points(spawn_cells)
	var successfully_spawned := 0
	for entry in entries:
		var enemy_id := StringName(entry.get("enemy_id", "")) if entry is Dictionary else StringName(entry)
		var enemy := enemy_registry.instantiate(enemy_id)
		if enemy == null:
			continue
		room_root.add_child(enemy)
		if enemy is Node2D:
			(enemy as Node2D).global_position = _next_spawn_position(spawn_points)
		_register_enemy(enemy, enemy_id, wave_index)
		successfully_spawned += 1
	if successfully_spawned < entries.size():
		encounter.notify_enemy_removed(entries.size() - successfully_spawned)

func _register_enemy(enemy: Node, enemy_id: StringName, wave_index: int) -> void:
	var instance_id := enemy.get_instance_id()
	_active_enemies[instance_id] = enemy
	enemy.set_meta("room_wave_index", wave_index)
	enemy_spawned.emit(enemy, enemy_id, wave_index)
	enemy.tree_exiting.connect(func(): _on_enemy_removed(instance_id), CONNECT_ONE_SHOT)

func _on_enemy_removed(instance_id: int) -> void:
	if not _active_enemies.has(instance_id):
		return
	_active_enemies.erase(instance_id)
	encounter.notify_enemy_removed(1)

func _resolve_spawn_points(fallback_cells: Array[Vector2i]) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if room_root != null and template != null and template.spawn_group != &"":
		for node in get_tree().get_nodes_in_group(template.spawn_group):
			if node is Node2D and room_root.is_ancestor_of(node):
				result.append((node as Node2D).global_position)
	if result.is_empty():
		for cell in fallback_cells:
			result.append(_cell_to_world(cell))
	if result.is_empty() and room_root is Node2D:
		result.append((room_root as Node2D).global_position)
	return result

func _next_spawn_position(points: Array[Vector2]) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var result := points[_spawn_cursor % points.size()]
	_spawn_cursor += 1
	return result

func _cell_to_world(cell: Vector2i) -> Vector2:
	var local := Vector2(cell.x + 0.5, cell.y + 0.5) * tile_world_size
	if room_root is Node2D:
		return (room_root as Node2D).to_global(local)
	return local

func set_exits_locked(locked: bool) -> void:
	if room_root == null or template == null:
		return
	for node in get_tree().get_nodes_in_group(template.exit_group):
		if not room_root.is_ancestor_of(node):
			continue
		if node.has_method("set_locked"):
			node.call("set_locked", locked)
		elif _has_property(node, &"disabled"):
			node.set("disabled", locked)
		else:
			node.set_meta("locked", locked)
	exits_locked.emit(locked)

func _has_property(node: Object, property_name: StringName) -> bool:
	for property in node.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false

func _on_encounter_cleared(template_id: StringName) -> void:
	# Keep exits locked until reward/route resolution. The coordinator unlocks them.
	room_scene_cleared.emit(template_id)

func active_enemy_count() -> int:
	return _active_enemies.size()
