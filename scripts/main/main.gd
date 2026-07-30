extends Node2D

var room: TestCombatRoom
var camera: CombatCamera
var hud: CombatHUD
var touch_layer: CanvasLayer
var touch_controls: MobileTouchControls

func _ready() -> void:
	GameState.reset_run()
	_build_prototype()
	EventBus.run_reset_requested.connect(_reset_prototype)
	print("[LAST MAGAZINE] P1 combat prototype booted.")

func _build_prototype() -> void:
	room = TestCombatRoom.new()
	room.name = "TestCombatRoom"
	add_child(room)
	camera = CombatCamera.new()
	camera.name = "CombatCamera"
	add_child(camera)
	camera.setup(room.player, room.get_camera_limits())
	camera.make_current()
	hud = CombatHUD.new()
	hud.name = "CombatHUD"
	add_child(hud)
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		touch_layer = CanvasLayer.new()
		touch_layer.name = "MobileTouchLayer"
		touch_layer.layer = 30
		add_child(touch_layer)
		touch_controls = MobileTouchControls.new()
		touch_controls.name = "MobileTouchControls"
		touch_layer.add_child(touch_controls)

func _reset_prototype() -> void:
	if is_instance_valid(room):
		room.queue_free()
	if is_instance_valid(camera):
		camera.queue_free()
	if is_instance_valid(hud):
		hud.queue_free()
	if is_instance_valid(touch_layer):
		touch_layer.queue_free()
	await get_tree().process_frame
	GameState.reset_run()
	_build_prototype()
