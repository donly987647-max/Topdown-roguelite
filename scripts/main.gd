extends Node2D

const PlayerScript = preload("res://scripts/player/player.gd")
const EncounterDirectorScript = preload("res://scripts/systems/encounter_director.gd")
const HUDScript = preload("res://scripts/ui/hud.gd")

const ARENA := Rect2(120.0, 90.0, 1040.0, 540.0)
var player: CharacterBody2D
var director: Node
var hud: CanvasLayer

func _ready() -> void:
    GameManager.reset_run()
    _build_world_bounds()

    player = PlayerScript.new()
    player.position = ARENA.get_center()
    add_child(player)

    director = EncounterDirectorScript.new()
    add_child(director)
    director.configure(player, ARENA)

    hud = HUDScript.new()
    add_child(hud)
    hud.configure(player, director)

    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        get_tree().paused = not get_tree().paused
        hud.set_pause_visible(get_tree().paused)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("111522"), true)
    draw_rect(ARENA, Color("1b2230"), true)
    draw_rect(ARENA, Color("556070"), false, 3.0)

    var spacing := 64.0
    var x := ARENA.position.x
    while x <= ARENA.end.x:
        draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), Color(0.18, 0.22, 0.28, 0.32), 1.0)
        x += spacing
    var y := ARENA.position.y
    while y <= ARENA.end.y:
        draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), Color(0.18, 0.22, 0.28, 0.32), 1.0)
        y += spacing

    draw_string(ThemeDB.fallback_font, Vector2(ARENA.position.x + 16.0, ARENA.position.y + 30.0), "AREA 01 // SCRAP ASSEMBLY LINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("8995a8"))

func _build_world_bounds() -> void:
    _add_wall(Vector2(ARENA.get_center().x, ARENA.position.y - 16.0), Vector2(ARENA.size.x + 64.0, 32.0))
    _add_wall(Vector2(ARENA.get_center().x, ARENA.end.y + 16.0), Vector2(ARENA.size.x + 64.0, 32.0))
    _add_wall(Vector2(ARENA.position.x - 16.0, ARENA.get_center().y), Vector2(32.0, ARENA.size.y))
    _add_wall(Vector2(ARENA.end.x + 16.0, ARENA.get_center().y), Vector2(32.0, ARENA.size.y))

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
