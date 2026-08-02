class_name GameInputSetup
extends RefCounted

static func configure() -> void:
	_ensure_action(&"move_left", 0.20)
	_ensure_action(&"move_right", 0.20)
	_ensure_action(&"move_up", 0.20)
	_ensure_action(&"move_down", 0.20)
	_ensure_action(&"aim_left", 0.20)
	_ensure_action(&"aim_right", 0.20)
	_ensure_action(&"aim_up", 0.20)
	_ensure_action(&"aim_down", 0.20)
	_ensure_action(&"fire", 0.20)
	_ensure_action(&"reload", 0.20)
	_ensure_action(&"dash", 0.20)
	_ensure_action(&"interact", 0.20)
	_ensure_action(&"character_active", 0.20)
	_ensure_action(&"toggle_map", 0.20)
	_ensure_action(&"toggle_inventory", 0.20)
	_ensure_action(&"ui_accept", 0.20)
	_ensure_action(&"ui_cancel", 0.20)
	_ensure_action(&"ui_left", 0.20)
	_ensure_action(&"ui_right", 0.20)
	_ensure_action(&"ui_up", 0.20)
	_ensure_action(&"ui_down", 0.20)

	_add_axis(&"move_left", 0, -1.0)
	_add_axis(&"move_right", 0, 1.0)
	_add_axis(&"move_up", 1, -1.0)
	_add_axis(&"move_down", 1, 1.0)
	_add_axis(&"aim_left", 2, -1.0)
	_add_axis(&"aim_right", 2, 1.0)
	_add_axis(&"aim_up", 3, -1.0)
	_add_axis(&"aim_down", 3, 1.0)
	_add_axis(&"fire", 5, 1.0)

	_add_button(&"dash", 0)
	_add_button(&"reload", 2)
	_add_button(&"interact", 1)
	_add_button(&"character_active", 3)
	_add_button(&"toggle_map", 4)
	_add_button(&"toggle_inventory", 11)
	_add_button(&"ui_accept", 0)
	_add_button(&"ui_cancel", 1)
	_add_button(&"ui_up", 11)
	_add_button(&"ui_down", 12)
	_add_button(&"ui_left", 13)
	_add_button(&"ui_right", 14)

	_add_key(&"character_active", KEY_Q)
	_add_key(&"toggle_map", KEY_TAB)
	_add_key(&"toggle_inventory", KEY_I)

static func _ensure_action(action: StringName, deadzone: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)

static func _add_axis(action: StringName, axis: int, axis_value: float) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and (event as InputEventJoypadMotion).axis == axis and is_equal_approx((event as InputEventJoypadMotion).axis_value, axis_value):
			return
	var input := InputEventJoypadMotion.new()
	input.axis = axis
	input.axis_value = axis_value
	InputMap.action_add_event(action, input)

static func _add_button(action: StringName, button: int) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return
	var input := InputEventJoypadButton.new()
	input.button_index = button
	InputMap.action_add_event(action, input)

static func _add_key(action: StringName, physical_keycode: Key) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == physical_keycode:
			return
	var input := InputEventKey.new()
	input.physical_keycode = physical_keycode
	InputMap.action_add_event(action, input)
