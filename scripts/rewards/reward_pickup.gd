class_name RewardPickup
extends Area2D

signal collected

@export var reward_name: String = "Prototype Salvage"
@export var credits: int = 25

var _collected := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotation += delta * 1.6

func _on_body_entered(body: Node) -> void:
	if _collected or not (body is Player):
		return
	_collected = true
	collected.emit()
	queue_free()
