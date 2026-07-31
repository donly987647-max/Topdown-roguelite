extends SceneTree

const OUTPUT_PATH := "res://builds/captures/p2_backpack_960x540.png"

func _initialize() -> void:
	print("[P2 BACKPACK CAPTURE] START")
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(960, 540)
	var absolute_output := ProjectSettings.globalize_path("res://builds/captures")
	if DirAccess.make_dir_recursive_absolute(absolute_output) != OK:
		push_error("[P2 BACKPACK CAPTURE] Output directory could not be created")
		quit(1)
		return

	print("[P2 BACKPACK CAPTURE] BUILD WORLD")
	var world := Node2D.new()
	world.name = "BackpackCaptureWorld"
	root.add_child(world)
	current_scene = world

	var player := PlayerController.new()
	player.name = "Player"
	world.add_child(player)
	await process_frame

	var backpack := BackpackGrid.new()
	var sample_parts := [
		WeaponPartCatalog.precision_barrel(),
		WeaponPartCatalog.extended_magazine(),
		WeaponPartCatalog.compressed_magazine(),
		WeaponPartCatalog.impact_core(),
		WeaponPartCatalog.clone_core(),
		WeaponPartCatalog.flame_core()
	]
	for index in sample_parts.size():
		var item_id := backpack.add_part(sample_parts[index], StringName("capture_%02d" % index))
		if index < sample_parts.size() - 1:
			backpack.auto_place(item_id)

	print("[P2 BACKPACK CAPTURE] BUILD PANEL")
	var panel := BackpackPanel.new()
	panel.name = "BackpackPanel"
	panel.configure(backpack, player)
	world.add_child(panel)
	await process_frame
	await process_frame
	paused = false
	await process_frame

	print("[P2 BACKPACK CAPTURE] SAVE IMAGE")
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("[P2 BACKPACK CAPTURE] Empty viewport image")
		quit(1)
		return
	var save_error := image.save_png(OUTPUT_PATH)
	if save_error != OK:
		push_error("[P2 BACKPACK CAPTURE] Failed to save image: %s" % save_error)
		quit(1)
		return
	print("[P2 BACKPACK CAPTURE] PASS")
	quit(0)
