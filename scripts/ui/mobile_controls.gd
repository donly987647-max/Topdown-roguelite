extends CanvasLayer

const STICK_RADIUS := 72.0
const KNOB_RADIUS := 30.0
const DEAD_ZONE := 0.16
const SAFE_MARGIN := 28.0
const BOTTOM_MARGIN := 44.0
const TOUCH_BUILD_LABEL := "TOUCH V3"

var player: Node
var root: Control
var move_base: Panel
var move_knob: Panel
var aim_base: Panel
var aim_knob: Panel
var dodge_button: Button
var reload_button: Button
var move_touch := -1
var aim_touch := -1
var move_origin := Vector2.ZERO
var aim_origin := Vector2.ZERO
var last_viewport_size := Vector2.ZERO
var screen_touch_seen := false
var mouse_touch_mode := ""

func configure(target: Node) -> void:
    player = target
    layer = 20
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_ui()
    _layout_controls()

func _process(_delta: float) -> void:
    var current_size := get_viewport().get_visible_rect().size
    if current_size != last_viewport_size:
        _layout_controls()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        _clear_all_input()

func _on_root_gui_input(event: InputEvent) -> void:
    if player == null:
        return

    if event is InputEventScreenTouch:
        screen_touch_seen = true
        var handled := false
        if event.pressed:
            handled = _touch_pressed(event.index, event.position)
        else:
            handled = _touch_released(event.index)
        if handled:
            root.accept_event()
    elif event is InputEventScreenDrag:
        screen_touch_seen = true
        if _touch_dragged(event.index, event.position):
            root.accept_event()
    elif OS.has_feature("web") and not screen_touch_seen:
        if _handle_web_mouse_fallback(event):
            root.accept_event()

func _handle_web_mouse_fallback(event: InputEvent) -> bool:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            mouse_touch_mode = _claim_pointer(event.position)
            return mouse_touch_mode != ""
        var had_pointer := mouse_touch_mode != ""
        _release_mouse_pointer()
        return had_pointer
    elif event is InputEventMouseMotion and mouse_touch_mode != "" and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
        if mouse_touch_mode == "move":
            _update_move(event.position)
        elif mouse_touch_mode == "aim":
            _update_aim(event.position)
        return true
    return false

func _claim_pointer(position: Vector2) -> String:
    var size := get_viewport().get_visible_rect().size
    if position.x < size.x * 0.46 and position.y > size.y - 330.0:
        _update_move(position)
        return "move"
    if position.x > size.x * 0.54 and position.y > size.y - 360.0:
        _update_aim(position)
        return "aim"
    return ""

func _release_mouse_pointer() -> void:
    if mouse_touch_mode == "move":
        player.set_mobile_move(Vector2.ZERO)
        move_knob.position = move_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)
    elif mouse_touch_mode == "aim":
        player.set_mobile_aim(Vector2.ZERO, false)
        aim_knob.position = aim_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)
    mouse_touch_mode = ""

func _touch_pressed(index: int, position: Vector2) -> bool:
    var size := get_viewport().get_visible_rect().size
    if position.x < size.x * 0.46 and position.y > size.y - 330.0 and move_touch < 0:
        move_touch = index
        _update_move(position)
        return true
    if position.x > size.x * 0.54 and position.y > size.y - 360.0 and aim_touch < 0:
        aim_touch = index
        _update_aim(position)
        return true
    return false

func _touch_dragged(index: int, position: Vector2) -> bool:
    if index == move_touch:
        _update_move(position)
        return true
    if index == aim_touch:
        _update_aim(position)
        return true
    return false

func _touch_released(index: int) -> bool:
    if index == move_touch:
        move_touch = -1
        player.set_mobile_move(Vector2.ZERO)
        move_knob.position = move_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)
        return true
    if index == aim_touch:
        aim_touch = -1
        player.set_mobile_aim(Vector2.ZERO, false)
        aim_knob.position = aim_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)
        return true
    return false

func _clear_all_input() -> void:
    move_touch = -1
    aim_touch = -1
    mouse_touch_mode = ""
    if player != null:
        player.clear_mobile_input()
    if move_knob != null:
        move_knob.position = move_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)
    if aim_knob != null:
        aim_knob.position = aim_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)

func _update_move(position: Vector2) -> void:
    var delta := position - move_origin
    var normalized := delta / STICK_RADIUS
    if normalized.length() < DEAD_ZONE:
        normalized = Vector2.ZERO
    else:
        normalized = normalized.limit_length(1.0)
    player.set_mobile_move(normalized)
    var visual_delta := delta.limit_length(STICK_RADIUS - KNOB_RADIUS * 0.35)
    move_knob.position = move_origin + visual_delta - Vector2(KNOB_RADIUS, KNOB_RADIUS)

func _update_aim(position: Vector2) -> void:
    var delta := position - aim_origin
    var normalized := delta / STICK_RADIUS
    var firing := normalized.length() >= DEAD_ZONE
    if not firing:
        normalized = Vector2.ZERO
    else:
        normalized = normalized.limit_length(1.0)
    player.set_mobile_aim(normalized, firing)
    var visual_delta := delta.limit_length(STICK_RADIUS - KNOB_RADIUS * 0.35)
    aim_knob.position = aim_origin + visual_delta - Vector2(KNOB_RADIUS, KNOB_RADIUS)

func _build_ui() -> void:
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_STOP
    root.gui_input.connect(_on_root_gui_input)
    add_child(root)

    move_base = _make_panel(Vector2(STICK_RADIUS * 2.0, STICK_RADIUS * 2.0), Color(0.16, 0.22, 0.30, 0.48), STICK_RADIUS)
    move_knob = _make_panel(Vector2(KNOB_RADIUS * 2.0, KNOB_RADIUS * 2.0), Color(0.48, 0.84, 1.0, 0.70), KNOB_RADIUS)
    aim_base = _make_panel(Vector2(STICK_RADIUS * 2.0, STICK_RADIUS * 2.0), Color(0.16, 0.22, 0.30, 0.48), STICK_RADIUS)
    aim_knob = _make_panel(Vector2(KNOB_RADIUS * 2.0, KNOB_RADIUS * 2.0), Color(1.0, 0.58, 0.32, 0.78), KNOB_RADIUS)
    dodge_button = _make_action_button("DODGE", Vector2(128, 68), Color(0.20, 0.48, 0.64, 0.88))
    reload_button = _make_action_button("RELOAD", Vector2(128, 68), Color(0.45, 0.34, 0.62, 0.88))
    dodge_button.pressed.connect(_on_dodge_pressed)
    reload_button.pressed.connect(_on_reload_pressed)

    var move_label := _make_label("MOVE", 14)
    move_label.name = "MoveLabel"
    var aim_label := _make_label("AIM / FIRE", 14)
    aim_label.name = "AimLabel"
    var build_label := _make_label(TOUCH_BUILD_LABEL, 12)
    build_label.name = "TouchBuildLabel"
    build_label.modulate = Color(0.55, 0.9, 0.7, 0.86)

func _on_dodge_pressed() -> void:
    if player != null:
        player.request_dodge()

func _on_reload_pressed() -> void:
    if player != null and player.weapon != null:
        player.weapon.request_reload()

func _layout_controls() -> void:
    if root == null:
        return
    var size := get_viewport().get_visible_rect().size
    last_viewport_size = size

    move_origin = Vector2(SAFE_MARGIN + STICK_RADIUS, size.y - BOTTOM_MARGIN - STICK_RADIUS)
    aim_origin = Vector2(size.x - SAFE_MARGIN - STICK_RADIUS, size.y - BOTTOM_MARGIN - STICK_RADIUS)

    move_base.position = move_origin - Vector2(STICK_RADIUS, STICK_RADIUS)
    move_knob.position = move_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)
    aim_base.position = aim_origin - Vector2(STICK_RADIUS, STICK_RADIUS)
    aim_knob.position = aim_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)

    var center_x := size.x * 0.5
    dodge_button.position = Vector2(center_x - 138.0, size.y - 236.0)
    reload_button.position = Vector2(center_x + 10.0, size.y - 236.0)

    var move_label := root.get_node_or_null("MoveLabel") as Label
    if move_label:
        move_label.position = Vector2(move_origin.x - 24.0, move_origin.y + STICK_RADIUS + 4.0)
    var aim_label := root.get_node_or_null("AimLabel") as Label
    if aim_label:
        aim_label.position = Vector2(aim_origin.x - 40.0, aim_origin.y + STICK_RADIUS + 4.0)
    var build_label := root.get_node_or_null("TouchBuildLabel") as Label
    if build_label:
        build_label.size = Vector2(120, 24)
        build_label.position = Vector2((size.x - 120.0) * 0.5, size.y - 112.0)
        build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _make_panel(size: Vector2, color: Color, radius: float) -> Panel:
    var panel := Panel.new()
    panel.size = size
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = color
    var r := int(radius)
    style.corner_radius_top_left = r
    style.corner_radius_top_right = r
    style.corner_radius_bottom_left = r
    style.corner_radius_bottom_right = r
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color(0.78, 0.90, 1.0, 0.30)
    panel.add_theme_stylebox_override("panel", style)
    root.add_child(panel)
    return panel

func _make_action_button(text: String, size: Vector2, color: Color) -> Button:
    var button := Button.new()
    button.text = text
    button.size = size
    button.add_theme_font_size_override("font_size", 17)
    var normal := StyleBoxFlat.new()
    normal.bg_color = color
    normal.corner_radius_top_left = 20
    normal.corner_radius_top_right = 20
    normal.corner_radius_bottom_left = 20
    normal.corner_radius_bottom_right = 20
    normal.border_width_left = 2
    normal.border_width_top = 2
    normal.border_width_right = 2
    normal.border_width_bottom = 2
    normal.border_color = Color(0.78, 0.90, 1.0, 0.32)
    button.add_theme_stylebox_override("normal", normal)
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = color.darkened(0.20)
    button.add_theme_stylebox_override("pressed", pressed)
    root.add_child(button)
    return button

func _make_label(text: String, font_size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("d8e7f6"))
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(label)
    return label
