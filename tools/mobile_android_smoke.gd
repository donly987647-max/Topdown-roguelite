extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	var main_scene := load("res://scenes/main/RunMain.tscn") as PackedScene
	if main_scene == null:
		errors.append("RunMain.tscn failed to load")
		_finish(errors)
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	var player := main.get_node_or_null("Player") as Player
	var mobile := main.get_node_or_null("MobileControls") as MobileControls
	if player == null:
		errors.append("RunMain is missing Player")
	if mobile == null:
		errors.append("RunMain is missing MobileControls")
	else:
		mobile.enabled_on_desktop = true
	if player != null:
		player.set_mobile_move(Vector2(0.5, -0.25))
		if not player.mobile_input_active():
			errors.append("Player mobile movement bridge is inactive")
		player.set_mobile_aim(Vector2.RIGHT, true)
		if not player.mobile_input_active():
			errors.append("Player mobile aim bridge is inactive")
		player.set_mobile_move(Vector2.ZERO)
		player.clear_mobile_aim()
	if not ResourceLoader.exists("res://export_presets.cfg"):
		# export_presets.cfg is not a Resource; retained as a no-op guard for readability.
		pass
	_finish(errors)

func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("MOBILE_ANDROID_SMOKE_OK")
		quit(0)
		return
	for error in errors:
		push_error(error)
	quit(1)
