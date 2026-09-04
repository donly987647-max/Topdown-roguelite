extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    failures.append(message)
    push_error("RUNTIME SMOKE: %s" % message)

func _run() -> void:
    var packed := load("res://scenes/main.tscn") as PackedScene
    if packed == null:
        _fail("main.tscn could not be loaded")
        _finish()
        return

    var scene := packed.instantiate()
    root.add_child(scene)
    current_scene = scene

    for _i in range(4):
        await process_frame

    var player = scene.get_node_or_null("Player")
    var director = scene.get_node_or_null("EncounterDirector")
    var hud = scene.get_node_or_null("HUD")

    if player == null:
        _fail("Player node was not created")
    elif not (player is CharacterBody2D):
        _fail("Player is not a CharacterBody2D")
    else:
        if player.get("weapon") == null:
            _fail("Player weapon controller was not created")
        var player_canvas := player as CanvasItem
        if player_canvas == null or not player_canvas.visible:
            _fail("Player CanvasItem is hidden")

    if director == null:
        _fail("EncounterDirector node was not created")
    if hud == null:
        _fail("HUD node was not created")

    if director != null and director.has_method("_spawn_next_wave"):
        director.call("_spawn_next_wave")
        for _i in range(3):
            await process_frame
    else:
        _fail("EncounterDirector cannot spawn a wave")

    var enemies := get_nodes_in_group("enemies")
    if enemies.size() < 3:
        _fail("Expected at least 3 enemies after wave spawn, got %d" % enemies.size())
    else:
        for enemy in enemies:
            if not (enemy is Node2D):
                _fail("Spawned enemy is not Node2D")
                break
            var enemy_canvas := enemy as CanvasItem
            if enemy_canvas == null or not enemy_canvas.visible:
                _fail("Spawned enemy is hidden")
                break

    if failures.is_empty():
        print("RUNTIME SMOKE PASS: player + weapon + HUD + %d enemies are alive" % enemies.size())
    _finish()

func _finish() -> void:
    var code := 0 if failures.is_empty() else 1
    quit(code)
