extends CanvasLayer

var player: Node
var root: Control
var build_button: Button
var overlay: ColorRect
var panel: Panel
var value_labels: Dictionary = {}
var stats_label: Label
var warning_label: Label
var is_open := false
var previous_pause_state := false

func configure(target: Node) -> void:
    player = target
    layer = 40
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_ui()
    _layout()

func _process(_delta: float) -> void:
    _layout()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_TAB:
            if is_open:
                close()
            else:
                open()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_ESCAPE and is_open:
            close()
            get_viewport().set_input_as_handled()

func open() -> void:
    if is_open or player == null:
        return
    is_open = true
    previous_pause_state = get_tree().paused
    player.clear_mobile_input()
    overlay.visible = true
    panel.visible = true
    build_button.visible = false
    get_tree().paused = true
    _refresh()

func close() -> void:
    if not is_open:
        return
    is_open = false
    overlay.visible = false
    panel.visible = false
    build_button.visible = true
    get_tree().paused = previous_pause_state

func _cycle(slot: String, delta: int) -> void:
    if player == null or player.weapon == null:
        return
    player.weapon.cycle_part(slot, delta)
    _refresh()

func _build_ui() -> void:
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    build_button = Button.new()
    build_button.text = "BUILD"
    build_button.add_theme_font_size_override("font_size", 17)
    build_button.size = Vector2(112, 54)
    build_button.pressed.connect(open)
    root.add_child(build_button)

    overlay = ColorRect.new()
    overlay.color = Color(0.02, 0.03, 0.05, 0.82)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.visible = false
    root.add_child(overlay)

    panel = Panel.new()
    panel.size = Vector2(660, 900)
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    panel.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color("151c29")
    style.border_color = Color("596b82")
    style.set_border_width_all(3)
    style.corner_radius_top_left = 22
    style.corner_radius_top_right = 22
    style.corner_radius_bottom_left = 22
    style.corner_radius_bottom_right = 22
    panel.add_theme_stylebox_override("panel", style)
    root.add_child(panel)

    var title := _make_label(panel, "WEAPON ASSEMBLY", Vector2(28, 24), 28)
    title.size = Vector2(604, 42)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    var subtitle := _make_label(panel, "Frame + Barrel + Magazine + Core", Vector2(28, 68), 15)
    subtitle.size = Vector2(604, 28)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.modulate = Color("94a4b8")

    var slots := ["frame", "barrel", "magazine", "core"]
    var slot_names := ["FRAME", "BARREL", "MAGAZINE", "CORE"]
    for i in slots.size():
        var y := 122.0 + float(i) * 112.0
        var slot: String = slots[i]
        _make_label(panel, slot_names[i], Vector2(30, y), 15)
        var prev := _make_button(panel, "<", Vector2(30, y + 32), Vector2(66, 56))
        prev.pressed.connect(_cycle.bind(slot, -1))
        var value := _make_label(panel, "", Vector2(108, y + 37), 18)
        value.size = Vector2(438, 50)
        value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        value_labels[slot] = value
        var next := _make_button(panel, ">", Vector2(558, y + 32), Vector2(66, 56))
        next.pressed.connect(_cycle.bind(slot, 1))

    stats_label = _make_label(panel, "", Vector2(38, 584), 17)
    stats_label.size = Vector2(584, 142)

    warning_label = _make_label(panel, "", Vector2(38, 724), 15)
    warning_label.size = Vector2(584, 66)
    warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var note := _make_label(panel, "Prototype tuning: power/weight capacities are provisional. GDD effects are the design source.", Vector2(38, 790), 13)
    note.size = Vector2(584, 44)
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.modulate = Color("8290a3")

    var close_button := _make_button(panel, "APPLY / CLOSE", Vector2(190, 840), Vector2(280, 54))
    close_button.pressed.connect(close)

func _refresh() -> void:
    if player == null or player.weapon == null:
        return
    for slot in value_labels.keys():
        value_labels[slot].text = player.weapon.get_selected_name(String(slot))

    var summary: Dictionary = player.weapon.get_build_summary()
    stats_label.text = "DMG  %.1f    FIRE  %.3fs\nMAG  %d       RELOAD  %.2fs\nPOWER  %.1f / %.1f\nWEIGHT %.1f / %.1f" % [
        float(summary.get("damage", 0.0)),
        float(summary.get("fire_interval", 0.0)),
        int(summary.get("magazine_size", 0)),
        float(summary.get("reload_time", 0.0)),
        float(summary.get("power", 0.0)),
        float(summary.get("max_power", 0.0)),
        float(summary.get("weight", 0.0)),
        float(summary.get("max_weight", 0.0)),
    ]

    var warnings: Array[String] = []
    if float(summary.get("power_overload", 0.0)) > 0.0:
        warnings.append("POWER OVERLOAD: slower reload + misfire risk")
    if float(summary.get("weight_overload", 0.0)) > 0.0:
        warnings.append("WEIGHT OVERLOAD: slower movement + shorter dodge")
    warning_label.text = "\n".join(warnings) if not warnings.is_empty() else "SYSTEM NORMAL — no overload penalty"
    warning_label.modulate = Color("ff9e78") if not warnings.is_empty() else Color("7fe0b0")

func _layout() -> void:
    if root == null:
        return
    var size := get_viewport().get_visible_rect().size
    build_button.position = Vector2(size.x - build_button.size.x - 24.0, 118.0)
    panel.position = Vector2((size.x - panel.size.x) * 0.5, maxf(42.0, (size.y - panel.size.y) * 0.5))

func _make_label(parent: Control, text: String, pos: Vector2, font_size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.position = pos
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("eef4ff"))
    parent.add_child(label)
    return label

func _make_button(parent: Control, text: String, pos: Vector2, size: Vector2) -> Button:
    var button := Button.new()
    button.text = text
    button.position = pos
    button.size = size
    button.add_theme_font_size_override("font_size", 17)
    parent.add_child(button)
    return button
