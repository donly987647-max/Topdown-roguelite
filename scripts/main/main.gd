extends Node2D

var room: TestCombatRoom
var camera: CombatCamera
var hud: CombatHUD
var touch_layer: CanvasLayer
var touch_controls: MobileTouchControls
var reward_panel: WeaponRewardPanel

func _ready() -> void:
	GameState.reset_run()
	_build_prototype()
	EventBus.run_reset_requested.connect(_reset_prototype)
	print("[LAST MAGAZINE] P2 weapon and reward prototype booted.")

func _build_prototype() -> void:
	room = TestCombatRoom.new()
	room.name = "TestCombatRoom"
	add_child(room)
	room.reward_requested.connect(_on_reward_requested)
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

func _on_reward_requested(options: Array) -> void:
	if is_instance_valid(reward_panel):
		return
	var typed_options: Array[WeaponPartData] = []
	for option in options:
		if option is WeaponPartData:
			typed_options.append(option as WeaponPartData)
	if typed_options.is_empty():
		return
	reward_panel = WeaponRewardPanel.new()
	reward_panel.name = "WeaponRewardPanel"
	reward_panel.configure(typed_options)
	reward_panel.part_selected.connect(_on_reward_part_selected)
	add_child(reward_panel)

func _on_reward_part_selected(part: WeaponPartData) -> void:
	if not is_instance_valid(room) or not is_instance_valid(room.player) or room.player.weapon == null:
		return
	var next_parts := WeaponPartRewardPicker.replace_slot(room.player.weapon.equipped_parts, part)
	room.player.weapon.equip_parts(next_parts)
	reward_panel = null

func _reset_prototype() -> void:
	if is_instance_valid(reward_panel):
		reward_panel.queue_free()
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
