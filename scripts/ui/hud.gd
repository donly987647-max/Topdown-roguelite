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
var center_timer := 0.0

func configure(target: Node, encounter_director: Node) -> void:
    player = target
    director = encounter_director
    _build_ui()
    EventBus.wave_changed.connect(_on_wave_changed)
    EventBus.perfect_reload.connect(_on_perfect_reload)
    EventBus.encounter_cleared.connect(_on_encounter_cleared)
    EventBus.player_died.connect(_on_player_died)

func _process(delta: float) -> void:
    if player == null or hp_label == null:
        return

    hp_label.text = "HP  %03d / 100" % int(player.hp)
    var weapon = player.weapon
    ammo_label.text = "SERVICE PISTOL  %02d / %03d" % [weapon.ammo_in_mag, weapon.reserve_ammo]
    wave_label.text = "WAVE  %d / %d" % [director.current_wave, director.total_waves]
    run_label.text = "TIME  %s   KILLS  %d" % [_format_time(GameManager.run_elapsed), GameManager.enemies_killed]

    if weapon.reloading:
        var p: float = weapon.get_reload_progress()
        var window: Vector2 = weapon.get_perfect_window()
        var marker := " < PERFECT" if p >= window.x and p <= window.y else ""
        reload_label.text = "RELOAD  %3d%%%s" % [int(p * 100.0), marker]
    else:
        reload_label.text = "DODGE  READY" if player.dodge_cooldown_left <= 0.0 else "DODGE  %.1fs" % player.dodge_cooldown_left

    if center_timer > 0.0:
        center_timer -= delta
        if center_timer <= 0.0:
            center_label.text = ""

func set_pause_visible(value: bool) -> void:
    if pause_label:
        pause_label.visible = value

func _build_ui() -> void:
    hp_label = _make_label(Vector2(26, 24), 22)
    ammo_label = _make_label(Vector2(925, 640), 20)
    reload_label = _make_label(Vector2(925, 672), 16)
    wave_label = _make_label(Vector2(1030, 24), 18)
    run_label = _make_label(Vector2(26, 58), 16)

    center_label = _make_label(Vector2(390, 26), 24)
    center_label.size = Vector2(500, 40)
    center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    var help := _make_label(Vector2(26, 670), 14)
    help.text = "WASD move  |  Mouse aim/fire  |  Space dodge  |  R reload"
    help.modulate = Color("8995a8")

    pause_label = _make_label(Vector2(490, 325), 36)
    pause_label.text = "PAUSED"
    pause_label.size = Vector2(300, 60)
    pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pause_label.visible = false

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
    center_label.text = "AREA 01 CORE ENCOUNTER CLEARED"
    center_timer = 9999.0

func _on_player_died(_payload: Dictionary) -> void:
    center_label.text = "RUN TERMINATED"
    center_timer = 9999.0

func _format_time(seconds: float) -> String:
    var total := int(seconds)
    return "%02d:%02d" % [total / 60, total % 60]
