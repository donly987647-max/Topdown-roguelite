extends CanvasLayer

const STICK_RADIUS := 82.0
const KNOB_RADIUS := 34.0
const DEAD_ZONE := 0.16
const SAFE_MARGIN := 44.0

var player: Node
var root: Control
var move_base: Panel
var move_knob: Panel
var aim_base: Panel
var aim_knob: Panel
var dodge_button: Panel
var reload_button: Panel
var move_touch := -1
var aim_touch := -1
var move_origin := Vector2.ZERO
var aim_origin := Vector2.ZERO
var last_viewport_size := Vector2.ZERO

func configure(target: Node) -> void:
    player = target
    layer = 20
    _build_ui()
    _layout_controls()

func _process(_delta: float) -> void:
    var current_size := get_viewport().get_visible_rect().size
    if current_size != last_viewport_size:
        _layout_controls()

func _input(event: InputEvent) -> void:
    if player == null:
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_pressed(event.index, event.position)
        else:
            _touch_released(event.index)
    elif event is InputEventScreenDrag:
        _touch_dragged(event.index, event.position)

func _touch_pressed(index: int, position: Vector2) -> void:
    if _button_rect(dodge_button).has_point(position):
        player.request_dodge()
        get_viewport().set_input_as_handled()
        return

    if _button_rect(reload_button).has_point(position):
        player.weapon.request_reload()
        get_viewport().set_input_as_handled()
        return

    var size := get_viewport().get_visible_rect().size
    if position.x < size.x * 0.48 and position.y > size.y * 0.42 and move_touch < 0:
        move_touch = index
        _update_move(position)
        get_viewport().set_input_as_handled()
    elif position.x > size.x * 0.52 and position.y > size.y * 0.35 and aim_touch < 0:
        aim_touch = index
        _update_aim(position)
        get_viewport().set_input_as_handled()

func _touch_dragged(index: int, position: Vector2) -> void:
    if index == move_touch:
        _update_move(position)
        get_viewport().set_input_as_handled()
    elif index == aim_touch:
        _update_aim(position)
        get_viewport().set_input_as_handled()

func _touch_released(index: int) -> void:
    if index == move_touch:
        move_touch = -1
        player.set_mobile_move(Vector2.ZERO)
        move_knob.position = move_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)
        get_viewport().set_input_as_handled()
    elif index == aim_touch:
        aim_touch = -1
        player.set_mobile_aim(Vector2.ZERO, false)
        aim_knob.position = aim_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)
        get_viewport().set_input_as_handled()

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
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    move_base = _make_panel(Vector2(STICK_RADIUS * 2.0, STICK_RADIUS * 2.0), Color(0.16, 0.22, 0.30, 0.48), STICK_RADIUS)
    move_knob = _make_panel(Vector2(KNOB_RADIUS * 2.0, KNOB_RADIUS * 2.0), Color(0.48, 0.84, 1.0, 0.70), KNOB_RADIUS)
    aim_base = _make_panel(Vector2(STICK_RADIUS * 2.0, STICK_RADIUS * 2.0), Color(0.16, 0.22, 0.30, 0.48), STICK_RADIUS)
    aim_knob = _make_panel(Vector2(KNOB_RADIUS * 2.0, KNOB_RADIUS * 2.0), Color(1.0, 0.58, 0.32, 0.78), KNOB_RADIUS)
    dodge_button = _make_button("DODGE", Vector2(132, 76), Color(0.20, 0.48, 0.64, 0.76))
    reload_button = _make_button("RELOAD", Vector2(132, 76), Color(0.45, 0.34, 0.62, 0.76))

    var move_label := _make_label("MOVE", 16)
    move_label.name = "MoveLabel"
    var aim_label := _make_label("AIM / FIRE", 16)
    aim_label.name = "AimLabel"

func _layout_controls() -> void:
    if root == null:
        return
    var size := get_viewport().get_visible_rect().size
    last_viewport_size = size

    move_origin = Vector2(SAFE_MARGIN + STICK_RADIUS, size.y - SAFE_MARGIN - STICK_RADIUS)
    aim_origin = Vector2(size.x - SAFE_MARGIN - STICK_RADIUS, size.y - SAFE_MARGIN - STICK_RADIUS)

    move_base.position = move_origin - Vector2(STICK_RADIUS, STICK_RADIUS)
    move_knob.position = move_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)
    aim_base.position = aim_origin - Vector2(STICK_RADIUS, STICK_RADIUS)
    aim_knob.position = aim_origin - Vector2(KNOB_RADIUS, KNOB_RADIUS)

    dodge_button.position = Vector2(aim_origin.x - 244.0, size.y - SAFE_MARGIN - 88.0)
    reload_button.position = Vector2(aim_origin.x - 176.0, size.y - SAFE_MARGIN - 184.0)

    var move_label := root.get_node_or_null("MoveLabel") as Label
    if move_label:
        move_label.position = Vector2(move_origin.x - 34.0, move_origin.y + STICK_RADIUS + 5.0)
    var aim_label := root.get_node_or_null("AimLabel") as Label
    if aim_label:
        aim_label.position = Vector2(aim_origin.x - 48.0, aim_origin.y + STICK_RADIUS + 5.0)

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

func _make_button(text: String, size: Vector2, color: Color) -> Panel:
    var panel := _make_panel(size, color, 20.0)
    var label := Label.new()
    label.text = text
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color("f4f8ff"))
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(label)
    return panel

func _make_label(text: String, font_size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color(0.80, 0.88, 0.96, 0.72))
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(label)
    return label

func _button_rect(panel: Control) -> Rect2:
    return Rect2(panel.position, panel.size)
