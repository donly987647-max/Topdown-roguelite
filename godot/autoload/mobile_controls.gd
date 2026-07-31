extends Control

# Mobile-only virtual controls. Keyboard, mouse, and gamepad input remain unchanged.
const NO_TOUCH := -1
const DEADZONE := 0.18

var mobile_enabled := false
var move_touch_id := NO_TOUCH
var aim_touch_id := NO_TOUCH
var move_vector := Vector2.ZERO
var aim_vector := Vector2.ZERO

var safe_rect := Rect2()
var move_center := Vector2.ZERO
var aim_center := Vector2.ZERO
var dash_center := Vector2.ZERO
var reload_center := Vector2.ZERO
var stick_radius := 78.0
var button_radius := 38.0
var dash_flash := 0.0
var reload_flash := 0.0

func _ready() -> void:
    mobile_enabled = OS.has_feature("mobile")
    if not mobile_enabled:
        visible = false
        set_process_input(false)
        return

    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    z_index = 1000
    set_process_input(true)
    get_viewport().size_changed.connect(_layout_controls)
    _layout_controls()
    queue_redraw()

func _process(delta: float) -> void:
    if not mobile_enabled:
        return
    dash_flash = maxf(0.0, dash_flash - delta)
    reload_flash = maxf(0.0, reload_flash - delta)
    queue_redraw()

func _input(event: InputEvent) -> void:
    if not mobile_enabled:
        return

    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            _on_touch_pressed(touch.index, touch.position)
        else:
            _on_touch_released(touch.index)
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == move_touch_id:
            _update_move(drag.position)
        elif drag.index == aim_touch_id:
            _update_aim(drag.position)

func _on_touch_pressed(index: int, position: Vector2) -> void:
    # This synthetic accept action lets a screen tap start/restart the run.
    _pulse_action(&"ui_accept")

    if position.distance_to(dash_center) <= button_radius * 1.35:
        dash_flash = 0.16
        _pulse_action(&"dash")
        return

    if position.distance_to(reload_center) <= button_radius * 1.35:
        reload_flash = 0.16
        _pulse_action(&"reload")
        return

    if position.x < safe_rect.get_center().x:
        if move_touch_id == NO_TOUCH:
            move_touch_id = index
            _update_move(position)
    elif aim_touch_id == NO_TOUCH:
        aim_touch_id = index
        _update_aim(position)

func _on_touch_released(index: int) -> void:
    if index == move_touch_id:
        move_touch_id = NO_TOUCH
        move_vector = Vector2.ZERO
        _apply_move_actions()
    if index == aim_touch_id:
        aim_touch_id = NO_TOUCH
        aim_vector = Vector2.ZERO
        _apply_aim_actions()
    queue_redraw()

func _update_move(position: Vector2) -> void:
    move_vector = ((position - move_center) / stick_radius).limit_length(1.0)
    if move_vector.length() < DEADZONE:
        move_vector = Vector2.ZERO
    _apply_move_actions()
    queue_redraw()

func _update_aim(position: Vector2) -> void:
    aim_vector = ((position - aim_center) / stick_radius).limit_length(1.0)
    if aim_vector.length() < DEADZONE:
        aim_vector = Vector2.ZERO
    _apply_aim_actions()
    queue_redraw()

func _apply_move_actions() -> void:
    _apply_axis(&"move_left", &"move_right", move_vector.x)
    _apply_axis(&"move_up", &"move_down", move_vector.y)

func _apply_aim_actions() -> void:
    _apply_axis(&"aim_left", &"aim_right", aim_vector.x)
    _apply_axis(&"aim_up", &"aim_down", aim_vector.y)
    if aim_vector.length() >= DEADZONE:
        Input.action_press(&"fire", 1.0)
    else:
        Input.action_release(&"fire")

func _apply_axis(negative_action: StringName, positive_action: StringName, value: float) -> void:
    if value < -DEADZONE:
        Input.action_press(negative_action, absf(value))
    else:
        Input.action_release(negative_action)

    if value > DEADZONE:
        Input.action_press(positive_action, absf(value))
    else:
        Input.action_release(positive_action)

func _pulse_action(action: StringName) -> void:
    var press := InputEventAction.new()
    press.action = action
    press.pressed = true
    press.strength = 1.0
    Input.parse_input_event(press)
    call_deferred("_release_pulsed_action", action)

func _release_pulsed_action(action: StringName) -> void:
    var release := InputEventAction.new()
    release.action = action
    release.pressed = false
    release.strength = 0.0
    Input.parse_input_event(release)

func _layout_controls() -> void:
    var viewport_size := get_viewport_rect().size
    position = Vector2.ZERO
    size = viewport_size
    safe_rect = _logical_safe_area(viewport_size)

    var short_side := minf(safe_rect.size.x, safe_rect.size.y)
    stick_radius = clampf(short_side * 0.145, 62.0, 104.0)
    button_radius = stick_radius * 0.46
    var edge := maxf(16.0, stick_radius * 0.28)

    move_center = Vector2(
        safe_rect.position.x + edge + stick_radius,
        safe_rect.end.y - edge - stick_radius
    )
    aim_center = Vector2(
        safe_rect.end.x - edge - stick_radius,
        safe_rect.end.y - edge - stick_radius
    )
    dash_center = aim_center + Vector2(-stick_radius * 1.72, -stick_radius * 0.58)
    reload_center = aim_center + Vector2(-stick_radius * 1.72, stick_radius * 0.66)
    queue_redraw()

func _logical_safe_area(viewport_size: Vector2) -> Rect2:
    var physical_size := Vector2(DisplayServer.screen_get_size())
    var physical_safe := Rect2(DisplayServer.get_display_safe_area())
    if physical_size.x <= 0.0 or physical_size.y <= 0.0 or physical_safe.size.x <= 0.0 or physical_safe.size.y <= 0.0:
        return Rect2(Vector2.ZERO, viewport_size)

    var scale := Vector2(viewport_size.x / physical_size.x, viewport_size.y / physical_size.y)
    return Rect2(physical_safe.position * scale, physical_safe.size * scale)

func _draw() -> void:
    if not mobile_enabled:
        return

    _draw_stick(move_center, move_vector, Color(0.25, 0.90, 1.0, 0.32))
    _draw_stick(aim_center, aim_vector, Color(1.0, 0.36, 0.46, 0.32))
    _draw_button(dash_center, "DASH", Color(0.38, 0.91, 1.0, 0.58 if dash_flash > 0.0 else 0.28))
    _draw_button(reload_center, "R", Color(1.0, 0.78, 0.38, 0.58 if reload_flash > 0.0 else 0.28))

func _draw_stick(center: Vector2, vector: Vector2, color: Color) -> void:
    draw_circle(center, stick_radius, Color(0.01, 0.03, 0.05, 0.28))
    draw_arc(center, stick_radius, 0.0, TAU, 48, color, 3.0)
    var knob_position := center + vector * stick_radius * 0.63
    draw_circle(knob_position, stick_radius * 0.37, Color(color.r, color.g, color.b, 0.42))
    draw_arc(knob_position, stick_radius * 0.37, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.76), 2.0)

func _draw_button(center: Vector2, label: String, color: Color) -> void:
    draw_circle(center, button_radius, Color(0.01, 0.03, 0.05, 0.38))
    draw_arc(center, button_radius, 0.0, TAU, 36, color, 3.0)
    var font_size := int(maxf(13.0, button_radius * 0.42))
    var label_size := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
    draw_string(
        ThemeDB.fallback_font,
        center - Vector2(label_size.x * 0.5, -label_size.y * 0.30),
        label,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1.0,
        font_size,
        Color(0.92, 0.97, 1.0, 0.88)
    )

func _exit_tree() -> void:
    Input.action_release(&"move_left")
    Input.action_release(&"move_right")
    Input.action_release(&"move_up")
    Input.action_release(&"move_down")
    Input.action_release(&"aim_left")
    Input.action_release(&"aim_right")
    Input.action_release(&"aim_up")
    Input.action_release(&"aim_down")
    Input.action_release(&"fire")
