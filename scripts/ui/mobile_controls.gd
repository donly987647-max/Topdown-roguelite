class_name MobileControls
extends Control

@export var movement_radius: float = 130.0
@export var aim_radius: float = 150.0
@export var fire_threshold: float = 0.18

var _move_touch := -1
var _aim_touch := -1
var _move_origin := Vector2.ZERO
var _aim_origin := Vector2.ZERO
var _move_value := Vector2.ZERO
var _aim_value := Vector2.ZERO
var _player: Player

@onready var move_base: Control = $MoveBase
@onready var move_knob: Control = $MoveBase/Knob
@onready var aim_base: Control = $AimBase
@onready var aim_knob: Control = $AimBase/Knob
@onready var dash_button: Button = $DashButton
@onready var reload_button: Button = $ReloadButton

func _ready() -> void:
	visible = OS.has_feature("mobile") or OS.has_feature("android")
	set_process_input(visible)
	if visible:
		dash_button.button_down.connect(_press_dash)
		reload_button.button_down.connect(_press_reload)
	call_deferred("_resolve_player")

func _resolve_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if _is_action_button_position(event.position):
		return
	var viewport_size := get_viewport_rect().size
	if event.pressed:
		if event.position.x < viewport_size.x * 0.5 and _move_touch == -1:
			_move_touch = event.index
			_move_origin = event.position
			move_base.global_position = _move_origin - move_base.size * 0.5
			move_base.visible = true
		elif _aim_touch == -1:
			_aim_touch = event.index
			_aim_origin = event.position
			aim_base.global_position = _aim_origin - aim_base.size * 0.5
			aim_base.visible = true
	else:
		if event.index == _move_touch:
			_release_move()
		elif event.index == _aim_touch:
			_release_aim()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _move_touch:
		_move_value = ((event.position - _move_origin) / movement_radius).limit_length(1.0)
		move_knob.position = (move_base.size - move_knob.size) * 0.5 + _move_value * movement_radius
		if _player != null:
			_player.set_mobile_move(_move_value)
	elif event.index == _aim_touch:
		_aim_value = ((event.position - _aim_origin) / aim_radius).limit_length(1.0)
		aim_knob.position = (aim_base.size - aim_knob.size) * 0.5 + _aim_value * aim_radius
		if _player != null:
			_player.set_mobile_aim(_aim_value, true)
		if _aim_value.length() >= fire_threshold:
			Input.action_press("fire")
		else:
			Input.action_release("fire")

func _is_action_button_position(position: Vector2) -> bool:
	return dash_button.get_global_rect().has_point(position) or reload_button.get_global_rect().has_point(position)

func _release_move() -> void:
	_move_touch = -1
	_move_value = Vector2.ZERO
	move_knob.position = (move_base.size - move_knob.size) * 0.5
	move_base.visible = false
	if _player != null:
		_player.set_mobile_move(Vector2.ZERO)

func _release_aim() -> void:
	_aim_touch = -1
	_aim_value = Vector2.ZERO
	aim_knob.position = (aim_base.size - aim_knob.size) * 0.5
	aim_base.visible = false
	Input.action_release("fire")
	if _player != null:
		_player.clear_mobile_aim()

func _press_dash() -> void:
	Input.action_press("dash")
	await get_tree().process_frame
	Input.action_release("dash")

func _press_reload() -> void:
	Input.action_press("reload")
	await get_tree().process_frame
	Input.action_release("reload")

func _exit_tree() -> void:
	Input.action_release("fire")
	Input.action_release("dash")
	Input.action_release("reload")
