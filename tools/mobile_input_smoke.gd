extends SceneTree

const MobileControlsScript = preload("res://scripts/ui/mobile_controls.gd")

class StubWeapon:
    extends RefCounted
    var reload_count := 0

    func request_reload() -> void:
        reload_count += 1

class StubPlayer:
    extends Node
    var mobile_move_input := Vector2.ZERO
    var mobile_aim_input := Vector2.ZERO
    var mobile_fire_held := false
    var dodge_count := 0
    var weapon := StubWeapon.new()

    func set_mobile_move(value: Vector2) -> void:
        mobile_move_input = value

    func set_mobile_aim(value: Vector2, firing: bool) -> void:
        mobile_aim_input = value
        mobile_fire_held = firing

    func clear_mobile_input() -> void:
        mobile_move_input = Vector2.ZERO
        mobile_aim_input = Vector2.ZERO
        mobile_fire_held = false

    func request_dodge() -> void:
        dodge_count += 1

var player: StubPlayer
var controls: CanvasLayer

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(720, 1280)

    player = StubPlayer.new()
    root.add_child(player)

    controls = MobileControlsScript.new()
    root.add_child(controls)
    controls.configure(player)

    await process_frame
    await process_frame

    var move_origin: Vector2 = controls.move_origin
    var aim_origin: Vector2 = controls.aim_origin

    _push_touch(0, move_origin + Vector2(58, 0), true)
    await process_frame
    _require(player.mobile_move_input.x > 0.45, "left stick touch did not set movement")

    _push_drag(0, move_origin + Vector2(0, -64))
    await process_frame
    _require(player.mobile_move_input.y < -0.45, "left stick drag did not update movement")

    _push_touch(1, aim_origin + Vector2(-64, 0), true)
    await process_frame
    _require(player.mobile_aim_input.x < -0.45, "right stick touch did not set aim")
    _require(player.mobile_fire_held, "right stick touch did not enable fire")

    _push_touch(0, move_origin, false)
    _push_touch(1, aim_origin, false)
    await process_frame
    _require(player.mobile_move_input.length() < 0.001, "movement stayed active after release")
    _require(not player.mobile_fire_held, "fire stayed active after release")

    var dodge_center: Vector2 = controls.dodge_button.position + controls.dodge_button.size * 0.5
    _push_touch(2, dodge_center, true)
    _push_touch(2, dodge_center, false)
    await process_frame
    _require(player.dodge_count == 1, "DODGE button touch did not fire")

    var reload_center: Vector2 = controls.reload_button.position + controls.reload_button.size * 0.5
    _push_touch(3, reload_center, true)
    _push_touch(3, reload_center, false)
    await process_frame
    _require(player.weapon.reload_count == 1, "RELOAD button touch did not fire")

    print("MOBILE_INPUT_SMOKE_OK move/aim/fire/dodge/reload")
    quit(0)

func _push_touch(index: int, position: Vector2, pressed: bool) -> void:
    var event := InputEventScreenTouch.new()
    event.index = index
    event.position = position
    event.pressed = pressed
    root.push_input(event, true)

func _push_drag(index: int, position: Vector2) -> void:
    var event := InputEventScreenDrag.new()
    event.index = index
    event.position = position
    root.push_input(event, true)

func _require(condition: bool, message: String) -> void:
    if condition:
        return
    push_error("MOBILE_INPUT_SMOKE_FAIL: " + message)
    quit(1)
