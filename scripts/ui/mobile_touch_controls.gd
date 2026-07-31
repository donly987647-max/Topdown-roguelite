class_name MobileTouchControls
extends Control

const STICK_RADIUS := 82.0
const KNOB_RADIUS := 32.0
const BUTTON_RADIUS := 42.0
const DEADZONE := 0.18

var _move_touch := -1
var _aim_touch := -1
var _move_vector := Vector2.ZERO
var _aim_vector := Vector2.ZERO
var _move_center := Vector2.ZERO
var _aim_center := Vector2.ZERO
var _dash_center := Vector2.ZERO
var _reload_center := Vector2.ZERO
var _weapon_center := Vector2.ZERO
var _last_viewport_size := Vector2.ZERO
var _dash_label: Label
var _reload_label: Label
var _weapon_label: Label
var _hint_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	if not visible:
		return
	_create_labels()
	_update_layout(true)
	set_process_input(true)

func _process(_delta: float) -> void:
	if visible:
		_update_layout(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_release_all()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if event.position.distance_to(_dash_center) <= BUTTON_RADIUS * 1.25:
			InputRouter.pulse_mobile_dash()
			accept_event()
			return
		if event.position.distance_to(_reload_center) <= BUTTON_RADIUS * 1.25:
			InputRouter.pulse_mobile_reload()
			accept_event()
			return
		if event.position.distance_to(_weapon_center) <= BUTTON_RADIUS * 1.25:
			InputRouter.pulse_mobile_weapon_next()
			accept_event()
			return
		if _move_touch == -1 and event.position.x <= size.x * 0.48 and event.position.y >= size.y * 0.34:
			_move_touch = event.index
			_update_move(event.position)
			accept_event()
			return
		if _aim_touch == -1 and event.position.x >= size.x * 0.48 and event.position.y >= size.y * 0.28:
			_aim_touch = event.index
			_update_aim(event.position)
			accept_event()
			return
	else:
		if event.index == _move_touch:
			_move_touch = -1
			_move_vector = Vector2.ZERO
			InputRouter.set_mobile_move(Vector2.ZERO)
			queue_redraw()
			accept_event()
		if event.index == _aim_touch:
			_aim_touch = -1
			_aim_vector = Vector2.ZERO
			InputRouter.set_mobile_fire(false)
			queue_redraw()
			accept_event()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _move_touch:
		_update_move(event.position)
		accept_event()
	elif event.index == _aim_touch:
		_update_aim(event.position)
		accept_event()

func _update_move(position_value: Vector2) -> void:
	var raw := (position_value - _move_center) / STICK_RADIUS
	_move_vector = raw.limit_length(1.0)
	if _move_vector.length() < DEADZONE:
		_move_vector = Vector2.ZERO
	InputRouter.set_mobile_move(_move_vector)
	queue_redraw()

func _update_aim(position_value: Vector2) -> void:
	var raw := (position_value - _aim_center) / STICK_RADIUS
	_aim_vector = raw.limit_length(1.0)
	if _aim_vector.length() >= DEADZONE:
		InputRouter.set_mobile_aim(_aim_vector.normalized())
		InputRouter.set_mobile_fire(true)
	else:
		InputRouter.set_mobile_fire(false)
	queue_redraw()

func _release_all() -> void:
	_move_touch = -1
	_aim_touch = -1
	_move_vector = Vector2.ZERO
	_aim_vector = Vector2.ZERO
	InputRouter.clear_mobile_state()
	queue_redraw()

func _update_layout(force := false) -> void:
	var viewport_size := get_viewport_rect().size
	if not force and viewport_size.is_equal_approx(_last_viewport_size):
		return
	_last_viewport_size = viewport_size
	position = Vector2.ZERO
	size = viewport_size
	var bottom := viewport_size.y - 106.0
	_move_center = Vector2(124.0, bottom)
	_aim_center = Vector2(viewport_size.x - 126.0, bottom)
	_dash_center = Vector2(viewport_size.x - 304.0, bottom - 4.0)
	_reload_center = Vector2(viewport_size.x - 228.0, bottom - 116.0)
	_weapon_center = Vector2(viewport_size.x - 400.0, bottom - 116.0)
	if _dash_label != null:
		_dash_label.position = _dash_center - Vector2(50.0, 15.0)
	if _reload_label != null:
		_reload_label.position = _reload_center - Vector2(50.0, 15.0)
	if _weapon_label != null:
		_weapon_label.position = _weapon_center - Vector2(50.0, 15.0)
	if _hint_label != null:
		_hint_label.position = Vector2(viewport_size.x * 0.5 - 180.0, viewport_size.y - 32.0)
	queue_redraw()

func _create_labels() -> void:
	_dash_label = _make_label("DASH", 18)
	_reload_label = _make_label("RELOAD", 15)
	_weapon_label = _make_label("WEAPON", 14)
	_hint_label = _make_label("LEFT: MOVE    RIGHT: AIM / AUTO FIRE", 13)
	_hint_label.modulate = Color(1, 1, 1, 0.62)

func _make_label(text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.size = Vector2(100.0, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f1f6f8"))
	add_child(label)
	return label

func _draw() -> void:
	if not visible:
		return
	_draw_stick(_move_center, _move_vector, Color("69e79a"))
	_draw_stick(_aim_center, _aim_vector, Color("ffbd55"))
	_draw_button(_dash_center, Color("6de7ef"))
	_draw_button(_reload_center, Color("c7a7ff"))
	_draw_button(_weapon_center, Color("ff8b72"))

func _draw_stick(center: Vector2, vector: Vector2, accent: Color) -> void:
	draw_circle(center, STICK_RADIUS, Color(0.02, 0.04, 0.06, 0.42))
	draw_arc(center, STICK_RADIUS, 0.0, TAU, 48, Color(accent, 0.52), 3.0)
	draw_circle(center + vector * (STICK_RADIUS - KNOB_RADIUS), KNOB_RADIUS, Color(accent, 0.34))
	draw_arc(center + vector * (STICK_RADIUS - KNOB_RADIUS), KNOB_RADIUS, 0.0, TAU, 32, Color(accent, 0.9), 2.0)

func _draw_button(center: Vector2, accent: Color) -> void:
	draw_circle(center, BUTTON_RADIUS, Color(0.02, 0.04, 0.06, 0.52))
	draw_arc(center, BUTTON_RADIUS, 0.0, TAU, 40, Color(accent, 0.88), 3.0)
