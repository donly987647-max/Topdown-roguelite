extends Node2D

# Executable Godot vertical slice for LAST MAGAZINE.
# All visuals are procedural placeholders so the project runs without external assets.

enum GameState { TITLE, RUNNING, GAME_OVER }

const ARENA_MARGIN := 30.0
const PLAYER_RADIUS := 14.0
const BULLET_RADIUS := 4.0
const MAX_ENEMIES := 90

var state := GameState.TITLE
var elapsed := 0.0
var kills := 0
var level := 1
var score := 0
var spawn_timer := 0.0
var next_boss_kills := 25
var mouse_position := Vector2.ZERO
var last_aim := Vector2.RIGHT

var player: Dictionary = {}
var weapon: Dictionary = {}
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var enemy_bullets: Array[Dictionary] = []
var particles: Array[Dictionary] = []

func _ready() -> void:
    AudioManager.apply_profile_settings(SaveManager.profile.get("settings", {}))
    set_process(true)
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        mouse_position = event.position
    if state == GameState.TITLE and (event.is_action_pressed("ui_accept") or event.is_action_pressed("fire")):
        start_run()
    elif state == GameState.GAME_OVER and (event.is_action_pressed("ui_accept") or event.is_action_pressed("fire")):
        start_run()

func start_run(character_id: String = "mara") -> void:
    var character: Dictionary = GameData.get_character(character_id)
    weapon = GameData.get_weapon(str(character.get("weapon", "pistol"))).duplicate(true)
    var center := get_viewport_rect().size * 0.5
    player = {
        "position": center,
        "velocity": Vector2.ZERO,
        "hp": float(character.get("hp", 100.0)),
        "max_hp": float(character.get("hp", 100.0)),
        "shield": float(character.get("shield", 0)) * 20.0,
        "speed": float(character.get("speed", 260.0)),
        "ammo": int(weapon.get("magazine", 10)),
        "reserve": int(weapon.get("magazine", 10)) * 12,
        "fire_cooldown": 0.0,
        "reload_timer": 0.0,
        "reloading": false,
        "dash_timer": 0.0,
        "dash_cooldown": 0.0,
        "invulnerable": 0.0,
        "heat": 0.0
    }
    enemies.clear()
    bullets.clear()
    enemy_bullets.clear()
    particles.clear()
    elapsed = 0.0
    kills = 0
    level = 1
    score = 0
    spawn_timer = 0.25
    next_boss_kills = 25
    state = GameState.RUNNING
    SaveManager.profile["runs"] = int(SaveManager.profile.get("runs", 0)) + 1
    SaveManager.profile["last_character"] = character_id
    SaveManager.profile["last_weapon"] = str(weapon.get("id", "pistol"))
    SaveManager.save_slot()
    queue_redraw()

func _process(delta: float) -> void:
    var safe_delta := minf(delta, 0.033)
    if state == GameState.RUNNING:
        _update_run(safe_delta)
    _update_particles(safe_delta)
    queue_redraw()

func _update_run(delta: float) -> void:
    elapsed += delta
    _update_player(delta)
    _update_spawning(delta)
    _update_enemies(delta)
    _update_bullets(delta)
    _update_enemy_bullets(delta)
    score = int(elapsed * 10.0) + kills * 125 + max(level - 1, 0) * 500

func _update_player(delta: float) -> void:
    player["fire_cooldown"] = maxf(0.0, float(player["fire_cooldown"]) - delta)
    player["dash_timer"] = maxf(0.0, float(player["dash_timer"]) - delta)
    player["dash_cooldown"] = maxf(0.0, float(player["dash_cooldown"]) - delta)
    player["invulnerable"] = maxf(0.0, float(player["invulnerable"]) - delta)
    player["heat"] = maxf(0.0, float(player["heat"]) - delta * 18.0)

    var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var aim_stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
    if aim_stick.length() > 0.22:
        last_aim = aim_stick.normalized()
    else:
        var mouse_aim := mouse_position - Vector2(player["position"])
        if mouse_aim.length() > 4.0:
            last_aim = mouse_aim.normalized()

    if Input.is_action_just_pressed("dash") and float(player["dash_cooldown"]) <= 0.0 and movement.length() > 0.1:
        player["dash_timer"] = 0.16
        player["dash_cooldown"] = 1.05
        player["invulnerable"] = 0.24
        _burst(Vector2(player["position"]), Color("62e7ff"), 14)

    var speed_multiplier := 3.15 if float(player["dash_timer"]) > 0.0 else 1.0
    var velocity := movement.normalized() * float(player["speed"]) * speed_multiplier
    player["velocity"] = velocity
    player["position"] = _clamp_to_arena(Vector2(player["position"]) + velocity * delta, PLAYER_RADIUS)

    if bool(player["reloading"]):
        player["reload_timer"] = float(player["reload_timer"]) - delta
        if float(player["reload_timer"]) <= 0.0:
            _finish_reload()
    elif Input.is_action_just_pressed("reload"):
        _begin_reload()

    var wants_fire := Input.is_action_pressed("fire")
    if wants_fire and not bool(player["reloading"]) and float(player["fire_cooldown"]) <= 0.0:
        _fire_weapon()

func _fire_weapon() -> void:
    if int(player["ammo"]) <= 0:
        _begin_reload()
        return
    var projectile_count := int(weapon.get("projectiles", 1))
    var kind := str(weapon.get("kind", "semi"))
    var spread := 0.0
    if kind == "spread":
        spread = 0.42
    elif projectile_count > 1:
        spread = 0.16

    for i in projectile_count:
        var ratio := 0.5 if projectile_count <= 1 else float(i) / float(projectile_count - 1)
        var angle_offset := lerpf(-spread, spread, ratio)
        var direction := last_aim.rotated(angle_offset)
        bullets.append({
            "position": Vector2(player["position"]) + direction * 22.0,
            "previous": Vector2(player["position"]),
            "velocity": direction * float(weapon.get("projectile_speed", 760.0)),
            "damage": float(weapon.get("damage", 18.0)),
            "life": 1.4,
            "radius": BULLET_RADIUS,
            "pierce": 1 if kind == "charge" else 0
        })

    player["ammo"] = int(player["ammo"]) - 1
    player["fire_cooldown"] = float(weapon.get("rate", 0.24))
    player["heat"] = minf(100.0, float(player["heat"]) + (5.0 if kind != "spin" else 9.0))
    if int(player["ammo"]) <= 0 and bool(SaveManager.profile.get("settings", {}).get("auto_reload", false)):
        _begin_reload()

func _begin_reload() -> void:
    if bool(player["reloading"]) or int(player["reserve"]) <= 0:
        return
    var capacity := int(weapon.get("magazine", 10))
    if int(player["ammo"]) >= capacity:
        return
    player["reloading"] = true
    player["reload_timer"] = float(weapon.get("reload", 1.15))

func _finish_reload() -> void:
    var capacity := int(weapon.get("magazine", 10))
    var needed := capacity - int(player["ammo"])
    var loaded := mini(needed, int(player["reserve"]))
    player["ammo"] = int(player["ammo"]) + loaded
    player["reserve"] = int(player["reserve"]) - loaded
    player["reloading"] = false
    player["reload_timer"] = 0.0

func _update_spawning(delta: float) -> void:
    spawn_timer -= delta
    if kills >= next_boss_kills and not _boss_alive():
        _spawn_boss()
        next_boss_kills += 35
        return
    if spawn_timer <= 0.0 and enemies.size() < MAX_ENEMIES and not _boss_alive():
        _spawn_enemy(false)
        if elapsed > 45.0 and randf() < 0.28:
            _spawn_enemy(false)
        spawn_timer = maxf(0.22, 1.0 - elapsed / 140.0)

func _spawn_enemy(is_boss: bool) -> void:
    var viewport_size := get_viewport_rect().size
    var angle := randf() * TAU
    var distance := maxf(viewport_size.x, viewport_size.y) * 0.72 + randf_range(40.0, 160.0)
    var position := _clamp_to_arena(Vector2(player["position"]) + Vector2.from_angle(angle) * distance, 22.0)
    var data: Dictionary
    if is_boss:
        data = GameData.bosses[(level - 1) % GameData.bosses.size()]
    else:
        data = GameData.enemies[randi() % GameData.enemies.size()]
    var hp_scale := 1.0 + elapsed / 150.0 + float(level - 1) * 0.08
    enemies.append({
        "id": str(data.get("id", "enemy")),
        "name": str(data.get("name", "적")),
        "position": position,
        "velocity": Vector2.ZERO,
        "radius": 38.0 if is_boss else randf_range(13.0, 20.0),
        "hp": float(data.get("hp", 40.0)) * hp_scale,
        "max_hp": float(data.get("hp", 40.0)) * hp_scale,
        "speed": float(data.get("speed", 80.0)) * (0.75 if is_boss else 1.0),
        "damage": float(data.get("damage", 10.0)),
        "cooldown": randf_range(0.3, 1.2),
        "shoot_interval": float(data.get("cooldown", 1.2)),
        "archetype": "boss" if is_boss else str(data.get("archetype", "chaser")),
        "color": data.get("color", Color("ff5d73")),
        "boss": is_boss,
        "phase": 1,
        "dead": false
    })

func _spawn_boss() -> void:
    _spawn_enemy(true)
    _burst(get_viewport_rect().size * 0.5, Color("ffc760"), 40)

func _boss_alive() -> bool:
    for enemy in enemies:
        if bool(enemy.get("boss", false)) and not bool(enemy.get("dead", false)):
            return true
    return false

func _update_enemies(delta: float) -> void:
    var player_position := Vector2(player["position"])
    for enemy in enemies:
        if bool(enemy["dead"]):
            continue
        var position := Vector2(enemy["position"])
        var to_player := player_position - position
        var distance := maxf(to_player.length(), 0.001)
        var direction := to_player / distance
        var archetype := str(enemy["archetype"])
        enemy["cooldown"] = float(enemy["cooldown"]) - delta

        if bool(enemy["boss"]):
            var health_ratio := float(enemy["hp"]) / float(enemy["max_hp"])
            enemy["phase"] = 3 if health_ratio < 0.35 else (2 if health_ratio < 0.7 else 1)
            var orbit := direction.rotated(PI * 0.5) * sin(elapsed * 1.3)
            enemy["velocity"] = (direction * 0.35 + orbit * 0.65).normalized() * float(enemy["speed"])
            if float(enemy["cooldown"]) <= 0.0:
                _boss_volley(enemy)
                enemy["cooldown"] = maxf(0.35, 1.15 - float(enemy["phase"]) * 0.18)
        elif archetype == "shooter" or archetype == "orbiter":
            var desired := direction * (1.0 if distance > 270.0 else -0.7)
            var side := direction.rotated(PI * 0.5) * (0.65 if archetype == "orbiter" else 0.25)
            enemy["velocity"] = (desired + side).normalized() * float(enemy["speed"])
            if float(enemy["cooldown"]) <= 0.0:
                _enemy_shot(position, direction, float(enemy["damage"]))
                enemy["cooldown"] = float(enemy["shoot_interval"])
        elif archetype == "dasher":
            enemy["velocity"] = direction * float(enemy["speed"]) * (2.1 if float(enemy["cooldown"]) < 0.25 else 0.55)
            if float(enemy["cooldown"]) <= 0.0:
                enemy["cooldown"] = 1.8
        else:
            enemy["velocity"] = direction * float(enemy["speed"])

        enemy["position"] = _clamp_to_arena(position + Vector2(enemy["velocity"]) * delta, float(enemy["radius"]))
        var overlap := PLAYER_RADIUS + float(enemy["radius"])
        if Vector2(enemy["position"]).distance_to(player_position) <= overlap:
            _hurt_player(float(enemy["damage"]))
            enemy["position"] = _clamp_to_arena(Vector2(enemy["position"]) - direction * 16.0, float(enemy["radius"]))

func _enemy_shot(origin: Vector2, direction: Vector2, damage: float) -> void:
    enemy_bullets.append({
        "position": origin,
        "previous": origin,
        "velocity": direction * 280.0,
        "damage": damage,
        "life": 4.0,
        "radius": 5.0
    })

func _boss_volley(enemy: Dictionary) -> void:
    var phase := int(enemy["phase"])
    var count := 10 + phase * 4
    var origin := Vector2(enemy["position"])
    for i in count:
        var direction := Vector2.from_angle(TAU * float(i) / float(count) + elapsed * 0.35 * phase)
        _enemy_shot(origin, direction, float(enemy["damage"]) * 0.65)
    var aimed := (Vector2(player["position"]) - origin).normalized()
    for i in 1 + phase:
        _enemy_shot(origin, aimed.rotated((float(i) - float(phase) * 0.5) * 0.12), float(enemy["damage"]))

func _update_bullets(delta: float) -> void:
    for bullet_index in range(bullets.size() - 1, -1, -1):
        var bullet := bullets[bullet_index]
        bullet["previous"] = bullet["position"]
        bullet["position"] = Vector2(bullet["position"]) + Vector2(bullet["velocity"]) * delta
        bullet["life"] = float(bullet["life"]) - delta
        var remove := float(bullet["life"]) <= 0.0
        if not remove:
            for enemy in enemies:
                if bool(enemy["dead"]):
                    continue
                if Vector2(bullet["position"]).distance_to(Vector2(enemy["position"])) <= float(bullet["radius"]) + float(enemy["radius"]):
                    enemy["hp"] = float(enemy["hp"]) - float(bullet["damage"])
                    _burst(Vector2(bullet["position"]), Color.WHITE, 4)
                    if float(enemy["hp"]) <= 0.0:
                        _kill_enemy(enemy)
                    if int(bullet["pierce"]) > 0:
                        bullet["pierce"] = int(bullet["pierce"]) - 1
                    else:
                        remove = true
                    break
        if remove:
            bullets.remove_at(bullet_index)

    for enemy_index in range(enemies.size() - 1, -1, -1):
        if bool(enemies[enemy_index]["dead"]):
            enemies.remove_at(enemy_index)

func _update_enemy_bullets(delta: float) -> void:
    for bullet_index in range(enemy_bullets.size() - 1, -1, -1):
        var bullet := enemy_bullets[bullet_index]
        bullet["previous"] = bullet["position"]
        bullet["position"] = Vector2(bullet["position"]) + Vector2(bullet["velocity"]) * delta
        bullet["life"] = float(bullet["life"]) - delta
        var remove := float(bullet["life"]) <= 0.0
        if not remove and Vector2(bullet["position"]).distance_to(Vector2(player["position"])) <= float(bullet["radius"]) + PLAYER_RADIUS:
            _hurt_player(float(bullet["damage"]))
            remove = true
        if remove:
            enemy_bullets.remove_at(bullet_index)

func _kill_enemy(enemy: Dictionary) -> void:
    if bool(enemy["dead"]):
        return
    enemy["dead"] = true
    kills += 1
    _burst(Vector2(enemy["position"]), enemy["color"], 14 if not bool(enemy["boss"]) else 42)
    if bool(enemy["boss"]):
        level += 1
        player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + 28.0)
        player["reserve"] = int(player["reserve"]) + int(weapon.get("magazine", 10)) * 4
        SaveManager.mark_achievement("ACH_%02d" % mini(level - 1, 4))

func _hurt_player(amount: float) -> void:
    if float(player["invulnerable"]) > 0.0 or state != GameState.RUNNING:
        return
    var remaining := amount
    if float(player["shield"]) > 0.0:
        var absorbed := minf(float(player["shield"]), remaining)
        player["shield"] = float(player["shield"]) - absorbed
        remaining -= absorbed
    if remaining > 0.0:
        player["hp"] = float(player["hp"]) - remaining
    player["invulnerable"] = 0.62
    _burst(Vector2(player["position"]), Color("ff526b"), 18)
    if float(player["hp"]) <= 0.0:
        _end_run()

func _end_run() -> void:
    state = GameState.GAME_OVER
    SaveManager.profile["play_time"] = float(SaveManager.profile.get("play_time", 0.0)) + elapsed
    SaveManager.profile["highest_threat"] = maxi(int(SaveManager.profile.get("highest_threat", 0)), level - 1)
    SaveManager.profile["last_run"] = {"time": elapsed, "kills": kills, "level": level, "score": score}
    SaveManager.save_slot()

func _clamp_to_arena(position: Vector2, radius: float) -> Vector2:
    var size := get_viewport_rect().size
    return Vector2(
        clampf(position.x, ARENA_MARGIN + radius, size.x - ARENA_MARGIN - radius),
        clampf(position.y, ARENA_MARGIN + 42.0 + radius, size.y - ARENA_MARGIN - radius)
    )

func _burst(position: Vector2, color: Color, count: int) -> void:
    for i in count:
        var direction := Vector2.from_angle(randf() * TAU)
        particles.append({
            "position": position,
            "velocity": direction * randf_range(40.0, 170.0),
            "life": randf_range(0.18, 0.55),
            "max_life": 0.55,
            "radius": randf_range(1.5, 4.0),
            "color": color
        })

func _update_particles(delta: float) -> void:
    for index in range(particles.size() - 1, -1, -1):
        var particle := particles[index]
        particle["position"] = Vector2(particle["position"]) + Vector2(particle["velocity"]) * delta
        particle["velocity"] = Vector2(particle["velocity"]) * 0.95
        particle["life"] = float(particle["life"]) - delta
        if float(particle["life"]) <= 0.0:
            particles.remove_at(index)

func _draw() -> void:
    var size := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), Color("070b10"))
    _draw_grid(size)

    if state == GameState.TITLE:
        _draw_title(size)
        return

    _draw_arena(size)
    _draw_particles()
    _draw_projectiles()
    _draw_enemies()
    _draw_player()
    _draw_hud(size)

    if state == GameState.GAME_OVER:
        _draw_game_over(size)

func _draw_grid(size: Vector2) -> void:
    for x in range(0, int(size.x) + 40, 40):
        draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.4, 0.7, 0.9, 0.055), 1.0)
    for y in range(0, int(size.y) + 40, 40):
        draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.4, 0.7, 0.9, 0.055), 1.0)

func _draw_arena(size: Vector2) -> void:
    draw_rect(Rect2(Vector2(ARENA_MARGIN, ARENA_MARGIN + 42.0), size - Vector2(ARENA_MARGIN * 2.0, ARENA_MARGIN * 2.0 + 42.0)), Color(0.08, 0.15, 0.2, 0.35), true)
    draw_rect(Rect2(Vector2(ARENA_MARGIN, ARENA_MARGIN + 42.0), size - Vector2(ARENA_MARGIN * 2.0, ARENA_MARGIN * 2.0 + 42.0)), Color("355064"), false, 2.0)

func _draw_player() -> void:
    var position := Vector2(player["position"])
    var alpha := 0.35 if float(player["invulnerable"]) > 0.0 and int(elapsed * 20.0) % 2 == 0 else 1.0
    draw_circle(position, PLAYER_RADIUS + 7.0, Color(0.25, 0.9, 1.0, 0.13 * alpha))
    draw_circle(position, PLAYER_RADIUS, Color(0.38, 0.91, 1.0, alpha))
    draw_line(position + last_aim * 5.0, position + last_aim * 31.0, Color(0.8, 0.98, 1.0, alpha), 7.0)
    if float(player["dash_timer"]) > 0.0:
        draw_arc(position, PLAYER_RADIUS + 12.0, 0.0, TAU, 32, Color("9ff6ff"), 3.0)

func _draw_enemies() -> void:
    for enemy in enemies:
        if bool(enemy["dead"]):
            continue
        var position := Vector2(enemy["position"])
        var radius := float(enemy["radius"])
        draw_circle(position, radius + 5.0, Color(1.0, 0.25, 0.4, 0.1))
        draw_circle(position, radius, enemy["color"])
        if bool(enemy["boss"]):
            draw_arc(position, radius + 10.0, 0.0, TAU, 48, Color("ffc760"), 4.0)
            var bar_width := 300.0
            var ratio := clampf(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0)
            draw_rect(Rect2(position + Vector2(-bar_width * 0.5, -radius - 31.0), Vector2(bar_width, 10.0)), Color(0.0, 0.0, 0.0, 0.75))
            draw_rect(Rect2(position + Vector2(-bar_width * 0.5 + 2.0, -radius - 29.0), Vector2((bar_width - 4.0) * ratio, 6.0)), Color("ffc760"))

func _draw_projectiles() -> void:
    for bullet in bullets:
        draw_line(Vector2(bullet["previous"]), Vector2(bullet["position"]), Color("9cfaff"), 5.0)
    for bullet in enemy_bullets:
        draw_line(Vector2(bullet["previous"]), Vector2(bullet["position"]), Color("ff526b"), 6.0)
        draw_circle(Vector2(bullet["position"]), 2.0, Color.WHITE)

func _draw_particles() -> void:
    for particle in particles:
        var alpha := clampf(float(particle["life"]) / float(particle["max_life"]), 0.0, 1.0)
        var color: Color = particle["color"]
        color.a = alpha
        draw_circle(Vector2(particle["position"]), float(particle["radius"]), color)

func _draw_hud(size: Vector2) -> void:
    var hp_ratio := clampf(float(player["hp"]) / float(player["max_hp"]), 0.0, 1.0)
    draw_rect(Rect2(Vector2(18, 14), Vector2(240, 54)), Color(0.02, 0.06, 0.09, 0.88))
    draw_rect(Rect2(Vector2(28, 27), Vector2(210, 15)), Color("1b2630"))
    draw_rect(Rect2(Vector2(30, 29), Vector2(206 * hp_ratio, 11)), Color("ff526b"))
    _text(Vector2(29, 58), "HP %d/%d  SHIELD %d" % [ceili(float(player["hp"])), ceili(float(player["max_hp"])), ceili(float(player["shield"]))], 13, Color("d8e8ef"))

    var weapon_text := "%s  %d/%d" % [str(weapon.get("name", "무기")), int(player["ammo"]), int(player["reserve"])]
    _text(Vector2(size.x - 270, 34), weapon_text, 16, Color.WHITE)
    _text(Vector2(size.x - 270, 57), "LEVEL %d  KILLS %d  SCORE %d" % [level, kills, score], 12, Color("9eb6c4"))
    _text(Vector2(size.x * 0.5 - 80, 32), _format_time(elapsed), 18, Color("62e7ff"))

    if bool(player["reloading"]):
        var total := float(weapon.get("reload", 1.15))
        var progress := 1.0 - clampf(float(player["reload_timer"]) / total, 0.0, 1.0)
        draw_rect(Rect2(Vector2(size.x * 0.5 - 100, size.y - 34), Vector2(200, 10)), Color("1b2630"))
        draw_rect(Rect2(Vector2(size.x * 0.5 - 98, size.y - 32), Vector2(196 * progress, 6)), Color("ffc760"))

func _draw_title(size: Vector2) -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.025, 0.04, 0.6))
    var center := size * 0.5
    _text(center + Vector2(-235, -78), "LAST", 72, Color.WHITE)
    _text(center + Vector2(-235, -6), "MAGAZINE", 72, Color("62e7ff"))
    _text(center + Vector2(-230, 56), "총기를 조립하고, 탄막을 돌파하라.", 18, Color("a9bdc8"))
    _text(center + Vector2(-230, 102), "ENTER / A / 클릭 — 런 시작", 16, Color("ffc760"))
    _text(center + Vector2(-230, 132), SteamIntegration.status_text(), 11, Color("718894"))

func _draw_game_over(size: Vector2) -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.73))
    var center := size * 0.5
    _text(center + Vector2(-142, -42), "RUN TERMINATED", 34, Color("ff526b"))
    _text(center + Vector2(-138, 4), "%s · %d KILLS · SCORE %d" % [_format_time(elapsed), kills, score], 16, Color.WHITE)
    _text(center + Vector2(-138, 43), "ENTER / A / 클릭 — 다시 시작", 14, Color("ffc760"))

func _text(position: Vector2, text: String, font_size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _format_time(seconds: float) -> String:
    return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
