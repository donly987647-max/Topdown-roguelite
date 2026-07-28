extends Node

const SAVE_VERSION := 1
const SLOT_COUNT := 3
const ROOT := "user://saves"
var current_slot := 0
var profile: Dictionary = {}

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
    profile = load_slot(current_slot)

func default_profile() -> Dictionary:
    return {
        "version": SAVE_VERSION, "play_time": 0.0,
        "unlocked_characters": ["mara", "kane", "nova", "rex"],
        "unlocked_weapons": ["pistol", "carbine", "shotgun"],
        "unlocked_modules": [], "achievements": [], "highest_threat": 0,
        "runs": 0, "wins": 0, "last_character": "mara", "last_weapon": "pistol",
        "settings": {"master":1.0,"music":0.8,"sfx":0.9,"screen_shake":0.75,"flash_reduction":false,"auto_fire":false,"auto_reload":false,"aim_assist":0.2,"game_speed":1.0,"bullet_palette":"default","ui_scale":1.0},
        "last_run": {}, "updated_at": Time.get_datetime_string_from_system()
    }

func save_slot(slot: int = current_slot, payload: Dictionary = profile) -> bool:
    current_slot = clampi(slot, 0, SLOT_COUNT - 1)
    payload["updated_at"] = Time.get_datetime_string_from_system()
    var payload_text := JSON.stringify(payload)
    var envelope := {"version": SAVE_VERSION, "checksum": payload_text.sha256_text(), "payload": payload}
    var path := _slot_path(current_slot)
    if FileAccess.file_exists(path):
        var backup_file := FileAccess.open(_backup_path(current_slot), FileAccess.WRITE)
        if backup_file: backup_file.store_string(FileAccess.get_file_as_string(path))
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null: push_error("Unable to write save slot"); return false
    var encoded := JSON.stringify(envelope)
    file.store_string(encoded); file.flush(); profile = payload.duplicate(true)
    SteamIntegration.write_cloud_file("save_%d.json" % current_slot, encoded.to_utf8_buffer())
    return true

func load_slot(slot: int) -> Dictionary:
    current_slot = clampi(slot, 0, SLOT_COUNT - 1)
    var loaded := _load_envelope(_slot_path(current_slot))
    if loaded.is_empty(): loaded = _load_envelope(_backup_path(current_slot))
    if loaded.is_empty(): loaded = default_profile()
    profile = loaded.duplicate(true); return profile

func mark_achievement(id: String) -> void:
    var list: Array = profile.get("achievements", [])
    if id in list: return
    list.append(id); profile["achievements"] = list
    SteamIntegration.unlock_achievement(id); save_slot()

func update_last_run(snapshot: Dictionary) -> void: profile["last_run"] = snapshot; save_slot()
func clear_last_run() -> void: profile["last_run"] = {}; save_slot()

func _load_envelope(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY: return {}
    var payload = parsed.get("payload", {})
    if typeof(payload) != TYPE_DICTIONARY: return {}
    if parsed.get("checksum", "") != JSON.stringify(payload).sha256_text(): return {}
    return payload
func _slot_path(slot: int) -> String: return "%s/slot_%d.json" % [ROOT, slot]
func _backup_path(slot: int) -> String: return "%s/slot_%d.backup.json" % [ROOT, slot]
