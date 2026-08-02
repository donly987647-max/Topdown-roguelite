class_name GameSettingsService
extends RefCounted

const SETTINGS_PATH := "user://last_magazine_settings.json"
const DAMAGE_NUMBER_MODES := ["all", "critical_only", "boss_only", "off"]

var values: Dictionary = {}

func _init() -> void:
	values = defaults()

func defaults() -> Dictionary:
	return {
		"master_volume": 1.0,
		"music_volume": 0.80,
		"sfx_volume": 0.90,
		"dialogue_volume": 0.90,
		"fullscreen": false,
		"screen_shake": 1.0,
		"damage_numbers_mode": "all",
		"auto_reload": true,
		"auto_fire": false,
		"aim_assist": 0.0,
		"game_speed": 1.0,
		"subtitles": true,
		"reduced_flashing": false,
		"background_brightness": 1.0,
	}

func load_settings(path: String = SETTINGS_PATH) -> Dictionary:
	values = defaults()
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				for key in parsed.keys():
					if values.has(key):
						values[key] = parsed[key]
	_sanitize()
	apply_settings()
	return values.duplicate(true)

func save_settings(path: String = SETTINGS_PATH) -> bool:
	_sanitize()
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(values, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK

func reset_to_defaults() -> void:
	values = defaults()
	apply_settings()

func set_value(key: StringName, value: Variant, apply_now: bool = true) -> bool:
	var text_key := String(key)
	if not values.has(text_key):
		return false
	values[text_key] = value
	_sanitize()
	if apply_now:
		apply_settings()
	return true

func get_value(key: StringName, fallback: Variant = null) -> Variant:
	return values.get(String(key), fallback)

func apply_settings() -> void:
	_apply_bus_volume("Master", float(values.get("master_volume", 1.0)))
	_apply_bus_volume("Music", float(values.get("music_volume", 0.8)))
	_apply_bus_volume("SFX", float(values.get("sfx_volume", 0.9)))
	_apply_bus_volume("Dialogue", float(values.get("dialogue_volume", 0.9)))
	Engine.time_scale = clampf(float(values.get("game_speed", 1.0)), 0.80, 1.0)
	if DisplayServer.get_name().to_lower() != "headless":
		var fullscreen := bool(values.get("fullscreen", false))
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func runtime_accessibility() -> Dictionary:
	return {
		"screen_shake": float(values.get("screen_shake", 1.0)),
		"damage_numbers_mode": String(values.get("damage_numbers_mode", "all")),
		"auto_reload": bool(values.get("auto_reload", true)),
		"auto_fire": bool(values.get("auto_fire", false)),
		"aim_assist": float(values.get("aim_assist", 0.0)),
		"game_speed": float(values.get("game_speed", 1.0)),
		"subtitles": bool(values.get("subtitles", true)),
		"reduced_flashing": bool(values.get("reduced_flashing", false)),
		"background_brightness": float(values.get("background_brightness", 1.0)),
	}

func _sanitize() -> void:
	for key in ["master_volume", "music_volume", "sfx_volume", "dialogue_volume"]:
		values[key] = clampf(float(values.get(key, 1.0)), 0.0, 1.0)
	values["screen_shake"] = clampf(float(values.get("screen_shake", 1.0)), 0.0, 1.0)
	values["aim_assist"] = clampf(float(values.get("aim_assist", 0.0)), 0.0, 1.0)
	values["game_speed"] = clampf(float(values.get("game_speed", 1.0)), 0.80, 1.0)
	values["background_brightness"] = clampf(float(values.get("background_brightness", 1.0)), 0.35, 1.0)
	var mode := String(values.get("damage_numbers_mode", "all"))
	values["damage_numbers_mode"] = mode if mode in DAMAGE_NUMBER_MODES else "all"
	for key in ["fullscreen", "auto_reload", "auto_fire", "subtitles", "reduced_flashing"]:
		values[key] = bool(values.get(key, defaults().get(key, false)))

func _apply_bus_volume(bus_name: String, linear: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var normalized := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, -80.0 if normalized <= 0.0001 else linear_to_db(normalized))
