extends Node

var _hitstop_active := false

func _ready() -> void:
	EventBus.hit_landed.connect(_on_hit_landed)

func _on_hit_landed(_position: Vector2, strength: float, critical: bool) -> void:
	var duration := 0.035
	if strength >= 1.5:
		duration = 0.065
	if critical:
		duration = 0.075
	request_hitstop(duration)

func request_hitstop(duration: float) -> void:
	if _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = 0.08
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_active = false
