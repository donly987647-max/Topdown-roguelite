class_name HitSpark
extends Node2D

var strength := 1.0
var _life := 0.16
var _initial_life := 0.16

func _ready() -> void:
	_initial_life = _life
	queue_redraw()

func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := clampf(_life / _initial_life, 0.0, 1.0)
	var radius := lerpf(18.0 * strength, 3.0, t)
	var color := Color(1.0, 0.78, 0.35, t)
	for index in range(8):
		var angle := TAU * index / 8.0
		var dir := Vector2.from_angle(angle)
		draw_line(dir * 3.0, dir * radius, color, 2.0 * t + 0.5)
