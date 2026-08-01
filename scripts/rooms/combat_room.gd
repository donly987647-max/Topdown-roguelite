class_name CombatRoom
extends Node

signal room_started(enemy_count: int)
signal wave_changed(current_wave: int, total_waves: int, enemy_count: int)
signal room_cleared
signal reward_spawned(reward: Node)

@export var total_waves: int = 2
@export var wave_two_enemy_scene: PackedScene
@export var wave_two_count: int = 4
@export var reward_scene: PackedScene
@export var wave_delay: float = 0.8

var _tracked_enemies: Array[Node] = []
var _current_wave := 1
var _cleared := false
var _transitioning := false

func _ready() -> void:
	call_deferred("_begin_room")

func _begin_room() -> void:
	_set_doors_locked(true)
	_track_current_enemies()
	room_started.emit(_tracked_enemies.size())
	wave_changed.emit(_current_wave, total_waves, _tracked_enemies.size())
	_check_clear()

func _track_current_enemies() -> void:
	_tracked_enemies.clear()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_track_enemy(enemy)

func _track_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy) or enemy in _tracked_enemies:
		return
	_tracked_enemies.append(enemy)
	if not enemy.tree_exited.is_connected(_on_enemy_exited):
		enemy.tree_exited.connect(_on_enemy_exited)

func _on_enemy_exited() -> void:
	call_deferred("_check_clear")

func _check_clear() -> void:
	if _cleared or _transitioning:
		return

	var alive_count := _alive_enemy_count()
	if alive_count > 0:
		return

	if _current_wave < total_waves:
		_transitioning = true
		_start_next_wave_after_delay()
	else:
		_finish_room()

func _start_next_wave_after_delay() -> void:
	await get_tree().create_timer(wave_delay).timeout
	_current_wave += 1
	_spawn_wave_two()
	_transitioning = false
	wave_changed.emit(_current_wave, total_waves, _alive_enemy_count())
	_check_clear()

func _spawn_wave_two() -> void:
	if wave_two_enemy_scene == null:
		return

	var points := _spawn_points()
	if points.is_empty():
		return

	for i in range(wave_two_count):
		var enemy := wave_two_enemy_scene.instantiate()
		if enemy == null:
			continue
		get_tree().current_scene.add_child(enemy)
		enemy.global_position = points[i % points.size()].global_position
		_track_enemy(enemy)

func _spawn_points() -> Array[Marker2D]:
	var result: Array[Marker2D] = []
	for child in get_children():
		if child is Marker2D:
			result.append(child)
	return result

func _alive_enemy_count() -> int:
	var alive := 0
	for enemy in _tracked_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			alive += 1
	return alive

func _finish_room() -> void:
	_cleared = true
	_set_doors_locked(false)
	_spawn_reward()
	room_cleared.emit()

func _spawn_reward() -> void:
	if reward_scene == null:
		return
	var reward := reward_scene.instantiate()
	if reward == null:
		return
	get_tree().current_scene.add_child(reward)
	var reward_marker := get_node_or_null("RewardPoint") as Marker2D
	if reward_marker != null:
		reward.global_position = reward_marker.global_position
	else:
		reward.global_position = Vector2(960, 540)
	reward_spawned.emit(reward)

func _set_doors_locked(value: bool) -> void:
	for door in get_tree().get_nodes_in_group("room_door"):
		if door.has_method("set_locked"):
			door.set_locked(value)

func is_cleared() -> bool:
	return _cleared

func current_wave() -> int:
	return _current_wave
