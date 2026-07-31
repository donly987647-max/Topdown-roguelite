extends Node

signal device_changed(device_name: StringName)

const ACTIONS := [
	"move_left", "move_right", "move_up", "move_down",
	"aim_left", "aim_right", "aim_up", "aim_down",
	"fire", "alt_fire", "dash", "reload", "interact",
	"weapon_slot_1", "weapon_slot_2", "weapon_slot_3", "weapon_next",
	"map", "inventory", "pause", "reset_room"
]

var last_device: StringName = &"keyboard_mouse"
var _last_mouse_position := Vector2.ZERO
var _mobile_move := Vector2.ZERO
var _mobile_aim := Vector2.RIGHT
var _mobile_fire_held := false
var _mobile_dash_queued := false
var _mobile_reload_queued := false
var _mobile_weapon_next_queued := false

func _ready() -> void:
	_install_default_actions()
	_load_bindings()
	set_process_input(true)

func _input(event: InputEvent) -> void:
	var next_device := last_device
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		next_device = &"gamepad"
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		next_device = &"keyboard_mouse"
	if next_device != last_device:
		last_device = next_device
		device_changed.emit(last_device)
	if event is InputEventMouseMotion:
		_last_mouse_position = event.position

func get_move_vector() -> Vector2:
	if _mobile_move.length_squared() > 0.0001:
		return _mobile_move
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func get_aim_vector(origin_global: Vector2) -> Vector2:
	if last_device == &"touch":
		return _mobile_aim
	if last_device == &"gamepad":
		var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		if stick.length_squared() >= 0.09:
			return stick.normalized()
	var viewport := get_viewport()
	if viewport == null:
		return Vector2.RIGHT
	var mouse_global := viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
	var direction := mouse_global - origin_global
	return direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT

func get_command_snapshot(origin_global: Vector2) -> Dictionary:
	var requested_weapon_slot := -1
	if Input.is_action_just_pressed("weapon_slot_1"):
		requested_weapon_slot = 0
	elif Input.is_action_just_pressed("weapon_slot_2"):
		requested_weapon_slot = 1
	elif Input.is_action_just_pressed("weapon_slot_3"):
		requested_weapon_slot = 2
	var snapshot := {
		"move": get_move_vector(),
		"aim": get_aim_vector(origin_global),
		"fire_pressed": Input.is_action_just_pressed("fire"),
		"fire_held": Input.is_action_pressed("fire") or _mobile_fire_held,
		"dash_pressed": Input.is_action_just_pressed("dash") or _mobile_dash_queued,
		"reload_pressed": Input.is_action_just_pressed("reload") or _mobile_reload_queued,
		"weapon_slot": requested_weapon_slot,
		"weapon_next": Input.is_action_just_pressed("weapon_next") or _mobile_weapon_next_queued,
		"device": last_device
	}
	_mobile_dash_queued = false
	_mobile_reload_queued = false
	_mobile_weapon_next_queued = false
	return snapshot

func set_mobile_move(value: Vector2) -> void:
	_mobile_move = value.limit_length(1.0)
	_mark_touch_device()

func set_mobile_aim(value: Vector2) -> void:
	if value.length_squared() > 0.001:
		_mobile_aim = value.normalized()
	_mark_touch_device()

func set_mobile_fire(held: bool) -> void:
	_mobile_fire_held = held
	_mark_touch_device()

func pulse_mobile_dash() -> void:
	_mobile_dash_queued = true
	_mark_touch_device()

func pulse_mobile_reload() -> void:
	_mobile_reload_queued = true
	_mark_touch_device()

func pulse_mobile_weapon_next() -> void:
	_mobile_weapon_next_queued = true
	_mark_touch_device()

func clear_mobile_state() -> void:
	_mobile_move = Vector2.ZERO
	_mobile_fire_held = false
	_mobile_dash_queued = false
	_mobile_reload_queued = false
	_mobile_weapon_next_queued = false

func _mark_touch_device() -> void:
	if last_device != &"touch":
		last_device = &"touch"
		device_changed.emit(last_device)

func rebind_action(action: StringName, event: InputEvent, clear_existing := true) -> bool:
	if not InputMap.has_action(action):
		return false
	if clear_existing:
		InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	_save_bindings()
	return true

func reset_bindings() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
	_install_default_actions()
	_save_bindings()

func _install_default_actions() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
	_add_key(&"move_left", KEY_A)
	_add_key(&"move_right", KEY_D)
	_add_key(&"move_up", KEY_W)
	_add_key(&"move_down", KEY_S)
	_add_joy_motion(&"move_left", 0, -1.0)
	_add_joy_motion(&"move_right", 0, 1.0)
	_add_joy_motion(&"move_up", 1, -1.0)
	_add_joy_motion(&"move_down", 1, 1.0)
	_add_joy_motion(&"aim_left", 2, -1.0)
	_add_joy_motion(&"aim_right", 2, 1.0)
	_add_joy_motion(&"aim_up", 3, -1.0)
	_add_joy_motion(&"aim_down", 3, 1.0)
	_add_mouse_button(&"fire", MOUSE_BUTTON_LEFT)
	_add_joy_motion(&"fire", 5, 1.0)
	_add_mouse_button(&"alt_fire", MOUSE_BUTTON_RIGHT)
	_add_joy_motion(&"alt_fire", 4, 1.0)
	_add_key(&"dash", KEY_SPACE)
	_add_joy_button(&"dash", 1)
	_add_key(&"reload", KEY_R)
	_add_joy_button(&"reload", 2)
	_add_key(&"interact", KEY_E)
	_add_joy_button(&"interact", 0)
	_add_key(&"weapon_slot_1", KEY_1)
	_add_key(&"weapon_slot_2", KEY_2)
	_add_key(&"weapon_slot_3", KEY_3)
	_add_key(&"weapon_next", KEY_Q)
	_add_joy_button(&"weapon_next", 3)
	_add_key(&"map", KEY_TAB)
	_add_key(&"inventory", KEY_I)
	_add_key(&"pause", KEY_ESCAPE)
	_add_joy_button(&"pause", 6)
	_add_key(&"reset_room", KEY_F5)

func _add_key(action: StringName, keycode: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	_add_unique(action, event)

func _add_mouse_button(action: StringName, button: int) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	_add_unique(action, event)

func _add_joy_button(action: StringName, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	_add_unique(action, event)

func _add_joy_motion(action: StringName, axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	_add_unique(action, event)

func _add_unique(action: StringName, event: InputEvent) -> void:
	for existing in InputMap.action_get_events(action):
		if existing.as_text() == event.as_text():
			return
	InputMap.action_add_event(action, event)

func _save_bindings() -> void:
	var config := ConfigFile.new()
	for action in ACTIONS:
		var serialized: Array[Dictionary] = []
		for event in InputMap.action_get_events(action):
			serialized.append(_serialize_event(event))
		config.set_value("bindings", action, serialized)
	config.save("user://input_bindings.cfg")

func _load_bindings() -> void:
	var config := ConfigFile.new()
	if config.load("user://input_bindings.cfg") != OK:
		return
	for action in ACTIONS:
		if not config.has_section_key("bindings", action):
			continue
		InputMap.action_erase_events(action)
		for payload in config.get_value("bindings", action, []):
			var event := _deserialize_event(payload)
			if event != null:
				InputMap.action_add_event(action, event)

func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "physical_keycode": event.physical_keycode}
	if event is InputEventMouseButton:
		return {"type": "mouse_button", "button_index": event.button_index}
	if event is InputEventJoypadButton:
		return {"type": "joy_button", "button_index": event.button_index}
	if event is InputEventJoypadMotion:
		return {"type": "joy_motion", "axis": event.axis, "axis_value": event.axis_value}
	return {}

func _deserialize_event(payload: Dictionary) -> InputEvent:
	match String(payload.get("type", "")):
		"key":
			var key_event := InputEventKey.new()
			key_event.physical_keycode = int(payload.get("physical_keycode", 0))
			return key_event
		"mouse_button":
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = int(payload.get("button_index", 1))
			return mouse_event
		"joy_button":
			var joy_button := InputEventJoypadButton.new()
			joy_button.button_index = int(payload.get("button_index", 0))
			return joy_button
		"joy_motion":
			var joy_motion := InputEventJoypadMotion.new()
			joy_motion.axis = int(payload.get("axis", 0))
			joy_motion.axis_value = float(payload.get("axis_value", 0.0))
			return joy_motion
	return null
