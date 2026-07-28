extends Node

const DEADZONE := 0.22

func _ready() -> void:
    ensure_actions()

func ensure_actions() -> void:
    _key_action("move_left", KEY_A)
    _key_action("move_right", KEY_D)
    _key_action("move_up", KEY_W)
    _key_action("move_down", KEY_S)
    _key_action("move_left", KEY_LEFT)
    _key_action("move_right", KEY_RIGHT)
    _key_action("move_up", KEY_UP)
    _key_action("move_down", KEY_DOWN)
    _joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
    _joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
    _joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
    _joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)

    _joy_axis("aim_left", JOY_AXIS_RIGHT_X, -1.0)
    _joy_axis("aim_right", JOY_AXIS_RIGHT_X, 1.0)
    _joy_axis("aim_up", JOY_AXIS_RIGHT_Y, -1.0)
    _joy_axis("aim_down", JOY_AXIS_RIGHT_Y, 1.0)

    _mouse_action("fire", MOUSE_BUTTON_LEFT)
    _joy_axis("fire", JOY_AXIS_TRIGGER_RIGHT, 1.0)
    _mouse_action("alt_fire", MOUSE_BUTTON_RIGHT)
    _joy_axis("alt_fire", JOY_AXIS_TRIGGER_LEFT, 1.0)

    _key_action("dash", KEY_SPACE)
    _joy_button("dash", JOY_BUTTON_B)
    _key_action("reload", KEY_R)
    _joy_button("reload", JOY_BUTTON_X)
    _key_action("interact", KEY_E)
    _joy_button("interact", JOY_BUTTON_A)
    _key_action("active", KEY_Q)
    _joy_button("active", JOY_BUTTON_RIGHT_SHOULDER)
    _key_action("weapon_swap", KEY_1)
    _key_action("weapon_swap", KEY_2)
    _joy_button("weapon_swap", JOY_BUTTON_LEFT_SHOULDER)
    _key_action("map", KEY_TAB)
    _joy_button("map", JOY_BUTTON_BACK)
    _key_action("inventory", KEY_I)
    _joy_button("inventory", JOY_BUTTON_DPAD_UP)
    _key_action("quick_info", KEY_ALT)
    _key_action("pause", KEY_ESCAPE)
    _joy_button("pause", JOY_BUTTON_START)
    _key_action("ui_accept", KEY_ENTER)
    _joy_button("ui_accept", JOY_BUTTON_A)
    _key_action("ui_cancel", KEY_ESCAPE)
    _joy_button("ui_cancel", JOY_BUTTON_B)

func _ensure_action(action: StringName) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action, DEADZONE)

func _event_exists(action: StringName, event: InputEvent) -> bool:
    for existing in InputMap.action_get_events(action):
        if existing.as_text() == event.as_text():
            return true
    return false

func _key_action(action: StringName, keycode: Key) -> void:
    _ensure_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    if not _event_exists(action, event):
        InputMap.action_add_event(action, event)

func _mouse_action(action: StringName, button: MouseButton) -> void:
    _ensure_action(action)
    var event := InputEventMouseButton.new()
    event.button_index = button
    if not _event_exists(action, event):
        InputMap.action_add_event(action, event)

func _joy_button(action: StringName, button: JoyButton) -> void:
    _ensure_action(action)
    var event := InputEventJoypadButton.new()
    event.button_index = button
    if not _event_exists(action, event):
        InputMap.action_add_event(action, event)

func _joy_axis(action: StringName, axis: JoyAxis, value: float) -> void:
    _ensure_action(action)
    var event := InputEventJoypadMotion.new()
    event.axis = axis
    event.axis_value = value
    if not _event_exists(action, event):
        InputMap.action_add_event(action, event)
