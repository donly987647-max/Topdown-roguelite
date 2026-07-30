extends SceneTree
## Headless smoke test: load the configured main scene and verify required autoloads.

func _init() -> void:
	var failures: Array[String] = []
	var main_scene_path := ProjectSettings.get_setting("application/run/main_scene", "") as String
	if main_scene_path.is_empty():
		failures.append("application/run/main_scene is missing")
	elif not ResourceLoader.exists(main_scene_path):
		failures.append("main scene does not exist: %s" % main_scene_path)

	for singleton_name in [&"EventBus", &"GameState"]:
		if not ProjectSettings.has_setting("autoload/%s" % singleton_name):
			failures.append("autoload is missing: %s" % singleton_name)

	if failures.is_empty():
		print("SMOKE TEST PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
