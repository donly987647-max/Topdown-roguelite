class_name RoomExitGate
extends Area2D

signal lock_changed(locked: bool)
signal exit_requested(target_room_id: StringName)

@export var target_room_id: StringName
@export var starts_locked: bool = true
@export var disable_collision_when_locked: bool = false

var locked := true

func _ready() -> void:
	add_to_group(&"room_exit")
	body_entered.connect(_on_body_entered)
	set_locked(starts_locked)

func set_locked(value: bool) -> void:
	if locked == value:
		_apply_collision_state()
		return
	locked = value
	_apply_collision_state()
	lock_changed.emit(locked)

func is_locked() -> bool:
	return locked

func set_target_room(room_id: StringName) -> void:
	target_room_id = room_id

func _apply_collision_state() -> void:
	if not disable_collision_when_locked:
		return
	set_deferred("monitoring", not locked)
	set_deferred("monitorable", not locked)

func _on_body_entered(body: Node) -> void:
	if locked:
		return
	if body is Player or body.is_in_group("player"):
		exit_requested.emit(target_room_id)
