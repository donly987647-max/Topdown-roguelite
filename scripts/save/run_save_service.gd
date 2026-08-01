class_name RunSaveService
extends RefCounted

const SAVE_VERSION := 2
const DEFAULT_PATH := "user://last_magazine_run.json"

func save_run(state: RunStateController, wallet: RunWallet, backpack: BackpackState = null, registry: RoomTemplateRegistry = null, path: String = DEFAULT_PATH) -> bool:
	if state == null or state.graph == null:
		return false
	var payload := {
		"version": SAVE_VERSION,
		"graph": state.graph.serialize(),
		"run_state": state.serialize(),
		"wallet": wallet.serialize() if wallet != null else {},
		"backpack": backpack.serialize() if backpack != null else {},
		"room_template_usage": registry.serialize_usage() if registry != null else {},
	}
	return _write_atomic(path, JSON.stringify(payload))

func _write_atomic(path: String, text: String) -> bool:
	var temp_path := "%s.tmp" % path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	file.close()
	var absolute_target := ProjectSettings.globalize_path(path)
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(path):
		var remove_error := DirAccess.remove_absolute(absolute_target)
		if remove_error != OK:
			return false
	return DirAccess.rename_absolute(absolute_temp, absolute_target) == OK

func load_payload(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return {}
	var version := int(parsed.get("version", -1))
	if version < 1 or version > SAVE_VERSION:
		return {}
	return parsed

func restore_run(state: RunStateController, wallet: RunWallet, backpack: BackpackState = null, registry: RoomTemplateRegistry = null, context: Dictionary = {}, path: String = DEFAULT_PATH) -> bool:
	if state == null:
		return false
	var payload := load_payload(path)
	if payload.is_empty():
		return false
	var graph := RunGraphCodec.deserialize(payload.get("graph", {}))
	if graph.start_id == &"" or graph.boss_id == &"":
		return false
	if not state.restore(payload.get("run_state", {}), graph, context):
		return false
	if wallet != null and not wallet.restore(payload.get("wallet", {})):
		return false
	if backpack != null and payload.has("backpack") and not payload.get("backpack", {}).is_empty():
		if not backpack.restore(payload.get("backpack", {})):
			return false
	if registry != null:
		registry.restore_usage(payload.get("room_template_usage", {}))
		state.restore_registered_templates(registry)
	return true

func has_save(path: String = DEFAULT_PATH) -> bool:
	return not load_payload(path).is_empty()

func delete_save(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
