class_name RoomDoor
extends StaticBody2D

@export var locked := true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	add_to_group("room_door")
	set_locked(locked)

func set_locked(value: bool) -> void:
	locked = value
	if collision_shape != null:
		collision_shape.set_deferred("disabled", not locked)
	if visual != null:
		visual.visible = locked
