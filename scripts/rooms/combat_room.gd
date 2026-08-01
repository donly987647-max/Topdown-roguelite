class_name CombatRoom
extends Node

signal room_started(enemy_count: int)
signal room_cleared

var _tracked_enemies: Array[Node] = []
var _cleared := false

func _ready() -> void:
	call_deferred("_begin_room")

func _begin_room() -> void:
	_tracked_enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in _tracked_enemies:
		if is_instance_valid(enemy):
			enemy.tree_exited.connect(_on_enemy_exited)
	room_started.emit(_tracked_enemies.size())
	_check_clear()

func _on_enemy_exited() -> void:
	call_deferred("_check_clear")

func _check_clear() -> void:
	if _cleared:
		return
	var alive_count := 0
	for enemy in _tracked_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			alive_count += 1
	if alive_count == 0:
		_cleared = true
		room_cleared.emit()

func is_cleared() -> bool:
	return _cleared
