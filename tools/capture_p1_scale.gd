extends SceneTree

const CAPTURE_SIZES: Array[Vector2i] = [Vector2i(640, 360), Vector2i(960, 540)]
const OUTPUT_DIR := "res://builds/captures"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_scene := load("res://scenes/main/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("[P1 CAPTURE] Main scene could not be loaded")
		quit(1)
		return
	var absolute_output := ProjectSettings.globalize_path(OUTPUT_DIR)
	if DirAccess.make_dir_recursive_absolute(absolute_output) != OK:
		push_error("[P1 CAPTURE] Output directory could not be created")
		quit(1)
		return
	for capture_size in CAPTURE_SIZES:
		root.content_scale_size = capture_size
		root.size = capture_size
		var instance := main_scene.instantiate()
		root.add_child(instance)
		current_scene = instance
		await process_frame
		await process_frame
		await create_timer(0.25).timeout
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			push_error("[P1 CAPTURE] Empty viewport image at %s" % capture_size)
			quit(1)
			return
		var output_path := "%s/p1_%dx%d.png" % [OUTPUT_DIR, capture_size.x, capture_size.y]
		var save_error := image.save_png(output_path)
		if save_error != OK:
			push_error("[P1 CAPTURE] Failed to save %s: %s" % [output_path, save_error])
			quit(1)
			return
		instance.queue_free()
		await process_frame
	print("[P1 CAPTURE] PASS")
	quit(0)
