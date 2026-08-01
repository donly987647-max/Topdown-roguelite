class_name RunSaveService
extends RefCounted

const SAVE_VERSION := 1
const DEFAULT_PATH := "user://last_magazine_run.json"

func save_run(state: RunStateController, wallet: RunWallet, backpack: BackpackState = null, path: String = DEFAULT_PATH) -> bool:
	if state == null or state.graph == null:
		return false
	var payload := {
		"version": SAVE_VERSION,
		"graph": state.graph.serialize(),
		"run_state": state.serialize(),
		"wallet": wallet.serialize() if wallet != null else {},
		"backpack": backpack.serialize() if backpack != null else {},
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	return true

func load_payload(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary) or int(parsed.get("version", -1)) != SAVE_VERSION:
		return {}
	return parsed

func restore_run(state: RunStateController, wallet: RunWallet, context: Dictionary = {}, path: String = DEFAULT_PATH) -> bool:
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
	return true

func delete_save(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
