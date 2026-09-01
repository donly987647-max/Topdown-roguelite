extends CanvasLayer

var player: Node
var director: Node
var hp_label: Label
var ammo_label: Label
var wave_label: Label
var run_label: Label
var reload_label: Label
var center_label: Label
var pause_label: Label
var help_label: Label
var center_timer := 0.0
var mobile_layout := false
var last_viewport_size := Vector2.ZERO

func configure(target: Node, encounter_director: Node) -> void:
    player = target
    director = encounter_director
    mobile_layout = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
    _build_ui()
    _layout_ui()
    EventBus.wave_changed.connect(_on_wave_changed)
    EventBus.perfect_reload.connect(_on_perfect_reload)
    EventBus.encounter_cleared.connect(_on_encounter_cleared)
    EventBus.player_died.connect(_on_player_died)

func _process(delta: float) -> void:
    if player == null or hp_label == null:
        return

    var current_size := get_viewport().get_visible_rect().size
    if current_size != last_viewport_size:
        _layout_ui()

    hp_label.text = "HP  %03d / 100" % int(player.hp)
    var weapon = player.weapon
    ammo_label.text = "SERVICE PISTOL  %02d / %03d" % [weapon.ammo_in_mag, weapon.reserve_ammo]
    wave_label.text = "WAVE  %d / %d" % [director.current_wave, director.total_waves]
    run_label.text = "TIME %s   KILLS %d" % [_format_time(GameManager.run_elapsed), GameManager.enemies_killed]

    if weapon.reloading:
        var p: float = weapon.get_reload_progress()
        var window: Vector2 = weapon.get_perfect_window()
        var marker := "  PERFECT" if p >= window.x and p <= window.y else ""
        reload_label.text = "RELOAD %3d%%%s" % [int(p * 100.0), marker]
    else:
        reload_label.text = "DODGE READY" if player.dodge_cooldown_left <= 0.0 else "DODGE %.1fs" % player.dodge_cooldown_left

    if center_timer > 0.0:
        center_timer -= delta
        if center_timer <= 0.0:
            center_label.text = ""

func set_pause_visible(value: bool) -> void:
    if pause_label:
        pause_label.visible = value

func _build_ui() -> void:
    hp_label = _make_label(Vector2.ZERO, 20)
    wave_label = _make_label(Vector2.ZERO, 17)
    run_label = _make_label(Vector2.ZERO, 14)
    ammo_label = _make_label(Vector2.ZERO, 17)
    reload_label = _make_label(Vector2.ZERO, 14)

    center_label = _make_label(Vector2.ZERO, 22)
    center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    help_label = _make_label(Vector2.ZERO, 13)
    help_label.text = "WASD move  |  Mouse aim/fire  |  Space dodge  |  R reload"
    help_label.modulate = Color("8995a8")
    help_label.visible = not mobile_layout

    pause_label = _make_label(Vector2.ZERO, 34)
    pause_label.text = "PAUSED"
    pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pause_label.visible = false

func _layout_ui() -> void:
    var size := get_viewport().get_visible_rect().size
    last_viewport_size = size

    hp_label.position = Vector2(24, 20)
    run_label.position = Vector2(24, 50)

    wave_label.size = Vector2(160, 32)
    wave_label.position = Vector2(size.x - 184, 20)
    wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    ammo_label.position = Vector2(24, 80)
    reload_label.size = Vector2(240, 28)
    reload_label.position = Vector2(size.x - 264, 80)
    reload_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    center_label.size = Vector2(minf(520.0, size.x - 48.0), 40)
    center_label.position = Vector2((size.x - center_label.size.x) * 0.5, 52)

    help_label.position = Vector2(20, size.y - 28)

    pause_label.size = Vector2(300, 58)
    pause_label.position = Vector2((size.x - 300.0) * 0.5, size.y * 0.46)

func _make_label(pos: Vector2, font_size: int) -> Label:
    var label := Label.new()
    label.position = pos
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("eef4ff"))
    add_child(label)
    return label

func _on_wave_changed(payload: Dictionary) -> void:
    center_label.text = "WAVE %d" % int(payload.get("wave", 0))
    center_timer = 1.2

func _on_perfect_reload(_payload: Dictionary) -> void:
    center_label.text = "PERFECT RELOAD +15%"
    center_timer = 0.9

func _on_encounter_cleared(_payload: Dictionary) -> void:
    center_label.text = "AREA 01 CLEARED"
    center_timer = 9999.0

func _on_player_died(_payload: Dictionary) -> void:
    center_label.text = "RUN TERMINATED"
    center_timer = 9999.0

func _format_time(seconds: float) -> String:
    var total := int(seconds)
    return "%02d:%02d" % [total / 60, total % 60]
