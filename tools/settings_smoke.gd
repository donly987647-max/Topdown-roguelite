extends SceneTree

var failures: Array[String] = []
const TEST_PATH := "user://settings_smoke.json"

func _init() -> void:
	_test_settings_scene()
	_test_defaults_and_sanitization()
	_test_save_restore()
	Engine.time_scale = 1.0
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	if failures.is_empty():
		print("SETTINGS_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_settings_scene() -> void:
	var scene := load("res://scenes/ui/settings_panel.tscn") as PackedScene
	_expect(scene != null, "Settings panel scene must load")
	var main_scene := load("res://scenes/main/RunMain.tscn") as PackedScene
	_expect(main_scene != null, "RunMain must still load with settings panel mounted")

func _test_defaults_and_sanitization() -> void:
	var service := GameSettingsService.new()
	var defaults := service.defaults()
	_expect(bool(defaults.get("auto_reload", false)), "Auto reload should default on")
	_expect(String(defaults.get("damage_numbers_mode", "")) == "all", "Damage numbers should default to all")
	service.set_value(&"screen_shake", 2.0, false)
	service.set_value(&"game_speed", 0.25, false)
	service.set_value(&"damage_numbers_mode", "invalid", false)
	_expect(is_equal_approx(float(service.get_value(&"screen_shake", -1.0)), 1.0), "Screen shake must clamp to 100%")
	_expect(is_equal_approx(float(service.get_value(&"game_speed", -1.0)), 0.8), "Game speed must clamp to the GDD 80% floor")
	_expect(String(service.get_value(&"damage_numbers_mode", "")) == "all", "Unknown damage number mode must fall back to all")

func _test_save_restore() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var service := GameSettingsService.new()
	service.set_value(&"master_volume", 0.42, false)
	service.set_value(&"screen_shake", 0.35, false)
	service.set_value(&"damage_numbers_mode", "critical_only", false)
	service.set_value(&"auto_reload", false, false)
	service.set_value(&"game_speed", 0.9, false)
	_expect(service.save_settings(TEST_PATH), "Settings service must save atomically")
	var restored := GameSettingsService.new()
	restored.load_settings(TEST_PATH)
	_expect(is_equal_approx(float(restored.get_value(&"master_volume", -1.0)), 0.42), "Master volume must restore")
	_expect(is_equal_approx(float(restored.get_value(&"screen_shake", -1.0)), 0.35), "Screen shake must restore")
	_expect(String(restored.get_value(&"damage_numbers_mode", "")) == "critical_only", "Damage number mode must restore")
	_expect(not bool(restored.get_value(&"auto_reload", true)), "Auto reload preference must restore")
	_expect(is_equal_approx(float(restored.get_value(&"game_speed", -1.0)), 0.9), "Game speed must restore")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
