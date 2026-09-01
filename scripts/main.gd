extends Node2D

const PlayerScript = preload("res://scripts/player/player.gd")
const EncounterDirectorScript = preload("res://scripts/systems/encounter_director.gd")
const HUDScript = preload("res://scripts/ui/hud.gd")
const MobileControlsScript = preload("res://scripts/ui/mobile_controls.gd")

const SIDE_MARGIN := 36.0
const TOP_MARGIN := 118.0
const CONTROL_ZONE_HEIGHT := 300.0
const MIN_ARENA_HEIGHT := 620.0

var arena := Rect2()
var player: CharacterBody2D
var director: Node
var hud: CanvasLayer
var mobile_controls: CanvasLayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    GameManager.reset_run()
    arena = _calculate_arena()
    _build_world_bounds()

    player = PlayerScript.new()
    player.position = arena.get_center()
    add_child(player)

    director = EncounterDirectorScript.new()
    add_child(director)
    director.configure(player, arena)

    hud = HUDScript.new()
    add_child(hud)
    hud.configure(player, director)

    if _mobile_controls_enabled():
        mobile_controls = MobileControlsScript.new()
        add_child(mobile_controls)
        mobile_controls.configure(player)

    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        get_tree().paused = not get_tree().paused
        hud.set_pause_visible(get_tree().paused)

func _mobile_controls_enabled() -> bool:
    return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

func _calculate_arena() -> Rect2:
    var viewport_size := get_viewport().get_visible_rect().size
    var width := maxf(480.0, viewport_size.x - SIDE_MARGIN * 2.0)
    var available_height := viewport_size.y - TOP_MARGIN - CONTROL_ZONE_HEIGHT
    var height := maxf(MIN_ARENA_HEIGHT, available_height)
    return Rect2(Vector2((viewport_size.x - width) * 0.5, TOP_MARGIN), Vector2(width, height))

func _draw() -> void:
    var viewport_size := get_viewport().get_visible_rect().size
    draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("111522"), true)
    draw_rect(arena, Color("1b2230"), true)
    draw_rect(arena, Color("556070"), false, 3.0)

    var spacing := 64.0
    var x := arena.position.x
    while x <= arena.end.x:
        draw_line(Vector2(x, arena.position.y), Vector2(x, arena.end.y), Color(0.18, 0.22, 0.28, 0.32), 1.0)
        x += spacing
    var y := arena.position.y
    while y <= arena.end.y:
        draw_line(Vector2(arena.position.x, y), Vector2(arena.end.x, y), Color(0.18, 0.22, 0.28, 0.32), 1.0)
        y += spacing

    draw_string(ThemeDB.fallback_font, Vector2(arena.position.x + 14.0, arena.position.y + 28.0), "AREA 01 // SCRAP ASSEMBLY LINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("8995a8"))

func _build_world_bounds() -> void:
    _add_wall(Vector2(arena.get_center().x, arena.position.y - 16.0), Vector2(arena.size.x + 64.0, 32.0))
    _add_wall(Vector2(arena.get_center().x, arena.end.y + 16.0), Vector2(arena.size.x + 64.0, 32.0))
    _add_wall(Vector2(arena.position.x - 16.0, arena.get_center().y), Vector2(32.0, arena.size.y))
    _add_wall(Vector2(arena.end.x + 16.0, arena.get_center().y), Vector2(32.0, arena.size.y))

func _add_wall(pos: Vector2, size: Vector2) -> void:
    var wall := StaticBody2D.new()
    wall.position = pos
    wall.collision_layer = 4
    wall.collision_mask = 0
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = size
    shape.shape = rect
    wall.add_child(shape)
    add_child(wall)
