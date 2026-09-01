extends Node

const EnemyScript = preload("res://scripts/enemies/enemy.gd")
const RUNNER_PATH := "res://data/enemies/scrap_runner.json"
const SHOOTER_PATH := "res://data/enemies/bolt_shooter.json"

var player: Node2D
var arena := Rect2()
var current_wave := 0
var total_waves := 5
var intermission := 1.0
var encounter_complete := false
var runner_data: Dictionary = {}
var shooter_data: Dictionary = {}

func configure(target: Node2D, arena_rect: Rect2) -> void:
    player = target
    arena = arena_rect
    runner_data = _load_json(RUNNER_PATH)
    shooter_data = _load_json(SHOOTER_PATH)

func _process(delta: float) -> void:
    if player == null or encounter_complete:
        return

    if get_tree().get_nodes_in_group("enemies").is_empty():
        intermission -= delta
        if intermission <= 0.0:
            if current_wave >= total_waves:
                encounter_complete = true
                EventBus.encounter_cleared.emit({"area": 1, "waves": total_waves})
            else:
                _spawn_next_wave()

func _spawn_next_wave() -> void:
    current_wave += 1
    intermission = 1.4
    EventBus.wave_changed.emit({"wave": current_wave, "total": total_waves})

    var runners := 2 + current_wave
    var shooters := maxi(0, current_wave - 1)
    if current_wave >= 4:
        shooters += 1

    for i in runners:
        _spawn_enemy(runner_data, i)
    for i in shooters:
        _spawn_enemy(shooter_data, i + runners)

func _spawn_enemy(definition: Dictionary, index: int) -> void:
    var enemy := EnemyScript.new()
    enemy.configure(player, definition)
    enemy.position = _spawn_position(index)
    get_tree().current_scene.add_child(enemy)

func _spawn_position(index: int) -> Vector2:
    var margin := 46.0
    var usable := arena.grow(-margin)
    var side := index % 4
    match side:
        0:
            return Vector2(randf_range(usable.position.x, usable.end.x), usable.position.y)
        1:
            return Vector2(usable.end.x, randf_range(usable.position.y, usable.end.y))
        2:
            return Vector2(randf_range(usable.position.x, usable.end.x), usable.end.y)
        _:
            return Vector2(usable.position.x, randf_range(usable.position.y, usable.end.y))

func _load_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Dictionary else {}
