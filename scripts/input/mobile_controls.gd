extends CanvasLayer

@export var player_path: NodePath = NodePath("../Player")
@export var enabled_on_desktop := false
@export_range(0.08, 0.22) var joystick_radius_ratio := 0.12
@export_range(0.05, 0.35) var stick_deadzone := 0.14
@export var auto_fire_with_aim_stick := true

var _player: Player
var _platform_active := false
var _combat_active := false
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
var _action_buttons: Array[Button] = []

func _ready() -> void:
	layer = 90
	_platform_active = enabled_on_desktop or OS.has_feature("Android") or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	_player = get_node_or_null(player_path) as Player
	if not _platform_active or _player == null:
		visible = false
		set_process_input(false)
		set_process(false)
		return
	_build_ui()
	get_viewport().size_changed.connect(_layout_ui)
	if DisplayServer.has_signal("orientation_changed"):
		DisplayServer.orientation_changed.connect(func(_orientation: int): call_deferred("_layout_ui"))
	_layout_ui()
	_sync_combat_state()

func _process(_delta: float) -> void:
	_sync_combat_state()

func _exit_tree() -> void:
	_reset_touch_state()

func _sync_combat_state() -> void:
	var next_active := _platform_active and is_instance_valid(_player) and _player.input_enabled and not _player.is_dead()
	if next_active == _combat_active:
		return
	_combat_active = next_active
	visible = _combat_active
	if not _combat_active:
		_reset_touch_state()
	else:
		_layout_ui()

func _reset_touch_state() -> void:
	_left_touch = -1
	_right_touch = -1
	_left_value = Vector2.ZERO
	_right_value = Vector2.ZERO
	_release_fire()
	for action in [&"dash", &"reload", &"interact", &"character_active"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)
	if is_instance_valid(_player):
		_player.set_mobile_move(Vector2.ZERO)
		_player.clear_mobile_aim()

func _build_ui() -> void:
	_left_base = _make_pad(Color(0.04, 0.07, 0.10, 0.42))
	_left_knob = _make_pad(Color(0.70, 0.84, 0.94, 0.72))
	_right_base = _make_pad(Color(0.04, 0.07, 0.10, 0.42))
	_right_knob = _make_pad(Color(1.0, 0.48, 0.16, 0.78))
	add_child(_left_base)
	add_child(_right_base)
	add_child(_left_knob)
	add_child(_right_knob)
	_make_action_button("DASH", &"dash")
	_make_action_button("RELOAD", &"reload")
	_make_action_button("USE", &"interact")
	_make_action_button("SKILL", &"character_active")

func _make_pad(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = 1
	return rect

func _make_action_button(label_text: String, action: StringName) -> void:
	var button := Button.new()
	button.text = label_text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = Color(1.0, 1.0, 1.0, 0.88)
	button.set_meta("mobile_action", action)
	button.button_down.connect(_press_action.bind(action))
	button.button_up.connect(_release_action.bind(action))
	add_child(button)
	_action_buttons.append(button)

func _layout_ui() -> void:
	if not _platform_active or _left_base == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var safe_rect := _viewport_safe_rect(viewport_size)
	var radius := _joystick_radius(safe_rect.size)
	var pad_size := Vector2.ONE * radius * 2.0
	var portrait := viewport_size.y > viewport_size.x
	var edge := maxf(18.0, radius * 0.26)
	_left_origin = Vector2(safe_rect.position.x + edge + radius, safe_rect.end.y - edge - radius)
	_right_origin = Vector2(safe_rect.end.x - edge - radius, safe_rect.end.y - edge - radius)
	_place_pad(_left_base, _left_origin, pad_size)
	_place_pad(_right_base, _right_origin, pad_size)
	_place_knob(_left_knob, _left_origin, radius)
	_place_knob(_right_knob, _right_origin, radius)
	_layout_action_buttons(safe_rect, radius, portrait)

func _viewport_safe_rect(viewport_size: Vector2) -> Rect2:
	if not OS.has_feature("Android"):
		return Rect2(Vector2.ZERO, viewport_size)
	var physical_safe := DisplayServer.get_display_safe_area()
	var window_size := Vector2(get_window().size)
	if physical_safe.size.x <= 0 or physical_safe.size.y <= 0 or window_size.x <= 0.0 or window_size.y <= 0.0:
		return Rect2(Vector2.ZERO, viewport_size)
	var scale := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	var pos := Vector2(physical_safe.position) * scale
	var size := Vector2(physical_safe.size) * scale
	return Rect2(pos, size)

func _layout_action_buttons(safe_rect: Rect2, radius: float, portrait: bool) -> void:
	var button_h := clampf(radius * 0.62, 58.0, 92.0)
	var button_w := clampf(radius * 1.12, 96.0, 150.0)
	var gap := maxf(10.0, radius * 0.12)
	for button in _action_buttons:
		button.size = Vector2(button_w, button_h)
		button.add_theme_font_size_override("font_size", int(clampf(radius * 0.19, 16.0, 26.0)))
	if _action_buttons.size() < 4:
		return
	if portrait:
		var x := safe_rect.end.x - button_w - gap
		var y := safe_rect.position.y + safe_rect.size.y * 0.50
		_action_buttons[3].position = Vector2(x, y - button_h - gap)
		_action_buttons[2].position = Vector2(x, y)
		_action_buttons[1].position = Vector2(x, y + button_h + gap)
		_action_buttons[0].position = Vector2(x - button_w - gap, y + button_h * 0.5)
	else:
		var x_right := safe_rect.end.x - button_w - gap
		var y_base := _right_origin.y - radius - button_h - gap
		_action_buttons[0].position = Vector2(x_right - button_w - gap, y_base + button_h * 0.5)
		_action_buttons[1].position = Vector2(x_right, y_base)
		_action_buttons[2].position = Vector2(x_right - button_w - gap, y_base - button_h - gap)
		_action_buttons[3].position = Vector2(x_right, y_base - button_h - gap)

func _place_pad(rect: ColorRect, origin: Vector2, size: Vector2) -> void:
	rect.position = origin - size * 0.5
	rect.size = size

func _place_knob(rect: ColorRect, origin: Vector2, radius: float) -> void:
	var knob_size := Vector2.ONE * radius * 0.72
	rect.size = knob_size
	rect.position = origin - knob_size * 0.5

func _input(event: InputEvent) -> void:
	if not _combat_active or not is_instance_valid(_player):
		return
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if event.pressed:
		if _touch_over_action_button(event.position):
			return
		var lower_zone := event.position.y >= viewport_size.y * (0.36 if viewport_size.y > viewport_size.x else 0.42)
		if not lower_zone:
			return
		if event.position.x < viewport_size.x * 0.5 and _left_touch == -1:
			_left_touch = event.index
			_left_origin = _clamp_stick_origin(event.position, true)
			_update_left(event.position)
			get_viewport().set_input_as_handled()
		elif event.position.x >= viewport_size.x * 0.5 and _right_touch == -1:
			_right_touch = event.index
			_right_origin = _clamp_stick_origin(event.position, false)
			_update_right(event.position)
			get_viewport().set_input_as_handled()
	else:
		if event.index == _left_touch:
			_left_touch = -1
			_left_value = Vector2.ZERO
			_player.set_mobile_move(Vector2.ZERO)
			get_viewport().set_input_as_handled()
		if event.index == _right_touch:
			_right_touch = -1
			_right_value = Vector2.ZERO
			_player.clear_mobile_aim()
			_release_fire()
			get_viewport().set_input_as_handled()
		_layout_ui()

func _touch_over_action_button(position: Vector2) -> bool:
	for button in _action_buttons:
		if button.visible and Rect2(button.position, button.size).has_point(position):
			return true
	return false

func _clamp_stick_origin(position: Vector2, left_side: bool) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var safe_rect := _viewport_safe_rect(viewport_size)
	var radius := _joystick_radius(safe_rect.size)
	var min_x := safe_rect.position.x + radius
	var max_x := safe_rect.end.x - radius
	if left_side:
		max_x = minf(max_x, viewport_size.x * 0.46)
	else:
		min_x = maxf(min_x, viewport_size.x * 0.54)
	var min_y := safe_rect.position.y + radius
	var max_y := safe_rect.end.y - radius
	return Vector2(clampf(position.x, min_x, max_x), clampf(position.y, min_y, max_y))

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
	return clampf(minf(viewport_size.x, viewport_size.y) * joystick_radius_ratio, 70.0, 156.0)

func _press_action(action: StringName) -> void:
	if _combat_active:
		Input.action_press(action)

func _release_action(action: StringName) -> void:
	if Input.is_action_pressed(action):
		Input.action_release(action)

func _release_fire() -> void:
	if Input.is_action_pressed("fire"):
		Input.action_release("fire")
