class_name MobileControls
extends CanvasLayer

@export var player_path: NodePath = NodePath("../Player")
@export var enabled_on_desktop := false
@export_range(0.15, 0.45) var joystick_radius_ratio := 0.12
@export_range(0.5, 1.0) var stick_deadzone := 0.14
@export var auto_fire_with_aim_stick := true

var _player: Player
var _active := false
var _left_touch := -1
var _right_touch := -1
var _left_origin := Vector2.ZERO
var _right_origin := Vector2.ZERO
var _left_value := Vector2.ZERO
var _right_value := Vector2.ZERO

var _left_base: ColorRect
var _left_knob: ColorRect
var _right_base: ColorRect
var _right_knob: ColorRect
var _safe_margin := 24.0

func _ready() -> void:
	layer = 90
	_active = enabled_on_desktop or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	visible = _active
	if not _active:
		set_process_input(false)
		return
	_player = get_node_or_null(player_path) as Player
	_build_ui()
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()

func _exit_tree() -> void:
	_release_fire()
	if is_instance_valid(_player):
		_player.set_mobile_move(Vector2.ZERO)
		_player.clear_mobile_aim()

func _build_ui() -> void:
	_left_base = _make_pad(Color(0.12, 0.16, 0.20, 0.30))
	_left_knob = _make_pad(Color(0.82, 0.88, 0.94, 0.42))
	_right_base = _make_pad(Color(0.12, 0.16, 0.20, 0.30))
	_right_knob = _make_pad(Color(1.0, 0.58, 0.20, 0.46))
	add_child(_left_base)
	add_child(_right_base)
	add_child(_left_knob)
	add_child(_right_knob)

	_make_action_button("DASH", "dash", Vector2(0.86, 0.58), Vector2(126, 72))
	_make_action_button("R", "reload", Vector2(0.93, 0.44), Vector2(92, 64))
	_make_action_button("USE", "interact", Vector2(0.78, 0.43), Vector2(104, 64))
	_make_action_button("SKILL", "character_active", Vector2(0.91, 0.29), Vector2(112, 64))

func _make_pad(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = 1
	return rect

func _make_action_button(label: String, action: StringName, anchor: Vector2, size: Vector2) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = size
	button.position = Vector2.ZERO
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.set_meta("mobile_anchor", anchor)
	button.set_meta("mobile_size", size)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = Color(1, 1, 1, 0.72)
	button.button_down.connect(_press_action.bind(action))
	button.button_up.connect(_release_action.bind(action))
	add_child(button)

func _layout_ui() -> void:
	if not _active:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var radius := _joystick_radius(viewport_size)
	var pad_size := Vector2.ONE * radius * 2.0
	_left_origin = Vector2(_safe_margin + radius, viewport_size.y - _safe_margin - radius)
	_right_origin = Vector2(viewport_size.x - _safe_margin - radius, viewport_size.y - _safe_margin - radius)
	_place_pad(_left_base, _left_origin, pad_size)
	_place_pad(_right_base, _right_origin, pad_size)
	_place_knob(_left_knob, _left_origin, radius)
	_place_knob(_right_knob, _right_origin, radius)
	for child in get_children():
		if child is Button and child.has_meta("mobile_anchor"):
			var a: Vector2 = child.get_meta("mobile_anchor")
			var s: Vector2 = child.get_meta("mobile_size")
			child.position = Vector2(viewport_size.x * a.x - s.x * 0.5, viewport_size.y * a.y - s.y * 0.5)

func _place_pad(rect: ColorRect, origin: Vector2, size: Vector2) -> void:
	rect.position = origin - size * 0.5
	rect.size = size

func _place_knob(rect: ColorRect, origin: Vector2, radius: float) -> void:
	var knob_size := Vector2.ONE * radius * 0.72
	rect.size = knob_size
	rect.position = origin - knob_size * 0.5

func _input(event: InputEvent) -> void:
	if not _active or not is_instance_valid(_player):
		return
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if event.pressed:
		if event.position.y < viewport_size.y * 0.43:
			return
		if event.position.x < viewport_size.x * 0.48 and _left_touch == -1:
			_left_touch = event.index
			_update_left(event.position)
			get_viewport().set_input_as_handled()
		elif event.position.x > viewport_size.x * 0.52 and _right_touch == -1:
			_right_touch = event.index
			_update_right(event.position)
			get_viewport().set_input_as_handled()
	else:
		if event.index == _left_touch:
			_left_touch = -1
			_left_value = Vector2.ZERO
			_player.set_mobile_move(Vector2.ZERO)
			_place_knob(_left_knob, _left_origin, _joystick_radius(viewport_size))
			get_viewport().set_input_as_handled()
		if event.index == _right_touch:
			_right_touch = -1
			_right_value = Vector2.ZERO
			_player.clear_mobile_aim()
			_release_fire()
			_place_knob(_right_knob, _right_origin, _joystick_radius(viewport_size))
			get_viewport().set_input_as_handled()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _left_touch:
		_update_left(event.position)
		get_viewport().set_input_as_handled()
	elif event.index == _right_touch:
		_update_right(event.position)
		get_viewport().set_input_as_handled()

func _update_left(position: Vector2) -> void:
	var radius := _joystick_radius(get_viewport().get_visible_rect().size)
	_left_value = ((position - _left_origin) / radius).limit_length(1.0)
	if _left_value.length() < stick_deadzone:
		_left_value = Vector2.ZERO
	_player.set_mobile_move(_left_value)
	_update_knob_position(_left_knob, _left_origin, _left_value, radius)

func _update_right(position: Vector2) -> void:
	var radius := _joystick_radius(get_viewport().get_visible_rect().size)
	_right_value = ((position - _right_origin) / radius).limit_length(1.0)
	var active := _right_value.length() >= stick_deadzone
	if not active:
		_right_value = Vector2.ZERO
	_player.set_mobile_aim(_right_value, active)
	_update_knob_position(_right_knob, _right_origin, _right_value, radius)
	if auto_fire_with_aim_stick:
		if active:
			Input.action_press("fire")
		else:
			_release_fire()

func _update_knob_position(knob: ColorRect, origin: Vector2, value: Vector2, radius: float) -> void:
	var knob_center := origin + value * radius * 0.72
	knob.position = knob_center - knob.size * 0.5

func _joystick_radius(viewport_size: Vector2) -> float:
	return clampf(minf(viewport_size.x, viewport_size.y) * joystick_radius_ratio, 72.0, 150.0)

func _press_action(action: StringName) -> void:
	Input.action_press(action)

func _release_action(action: StringName) -> void:
	Input.action_release(action)

func _release_fire() -> void:
	if Input.is_action_pressed("fire"):
		Input.action_release("fire")
