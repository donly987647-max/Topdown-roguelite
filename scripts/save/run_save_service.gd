class_name RunSaveService
extends RefCounted

const SAVE_VERSION := 6
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
		"owned_rewards": _json_safe(state.run_context.get("owned_rewards", [])),
		"player_state": _capture_player(state.run_context.get("player")),
		"weapon_state": _capture_weapon(state.run_context.get("weapon_controller")),
		"character_ability_state": _capture_character_ability(state.run_context.get("character_ability_runtime")),
		"equipment_state": _capture_equipment(state.run_context.get("equipment_runtime")),
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
	_restore_owned_rewards(context, payload.get("owned_rewards", []))
	context["_restored_player_state"] = payload.get("player_state", {})
	context["_restored_weapon_state"] = payload.get("weapon_state", {})
	context["_restored_character_ability_state"] = payload.get("character_ability_state", {})
	context["_restored_equipment_state"] = payload.get("equipment_state", {})
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

func apply_runtime_state(context: Dictionary) -> void:
	_apply_player(context.get("player"), context.get("_restored_player_state", {}))
	_apply_weapon(context.get("weapon_controller"), context.get("_restored_weapon_state", {}))
	_apply_character_ability(context.get("character_ability_runtime"), context.get("_restored_character_ability_state", {}))
	_apply_equipment(context.get("equipment_runtime"), context.get("_restored_equipment_state", {}))
	context.erase("_restored_player_state")
	context.erase("_restored_weapon_state")
	context.erase("_restored_character_ability_state")
	context.erase("_restored_equipment_state")

func _capture_player(player: Variant) -> Dictionary:
	if player == null:
		return {}
	return {
		"health": float(player.get("health")),
		"guard": int(player.get("guard")),
		"temporary_shield": float(player.get("temporary_shield")),
	}

func _capture_weapon(weapon: Variant) -> Dictionary:
	if weapon == null:
		return {}
	var frame_id := ""
	var barrel_id := ""
	var magazine_id := ""
	var core_id := ""
	var build = weapon.get("weapon_build")
	if build is WeaponBuild:
		frame_id = String(build.frame.id) if build.frame != null else ""
		barrel_id = String(build.barrel.id) if build.barrel != null else ""
		magazine_id = String(build.magazine.id) if build.magazine != null else ""
		core_id = String(build.core.id) if build.core != null else ""
	return {
		"frame_id": frame_id,
		"barrel_id": barrel_id,
		"magazine_id": magazine_id,
		"core_id": core_id,
		"ammo": int(weapon.get("ammo")),
		"reserve_ammo": int(weapon.get("reserve_ammo")),
		"heat": float(weapon.get("heat")),
	}

func _capture_character_ability(runtime: Variant) -> Dictionary:
	if runtime == null:
		return {}
	return {
		"active_cooldown": float(runtime.get("_active_cooldown")),
		"mara_kill_charge": int(runtime.get("_mara_kill_charge")),
		"kane_focus": int(runtime.get("_kane_focus")),
		"kane_chain_left": float(runtime.get("_kane_chain_left")),
		"kane_decay_left": float(runtime.get("_kane_decay_left")),
		"kane_free_shots": int(runtime.get("_kane_free_shots")),
	}

func _capture_equipment(runtime: Variant) -> Dictionary:
	if runtime == null or not runtime.has_method("serialize"):
		return {}
	var data: Variant = runtime.call("serialize")
	return data if data is Dictionary else {}

func _apply_player(player: Variant, data: Dictionary) -> void:
	if player == null or data.is_empty():
		return
	var max_health := float(player.get("max_health"))
	player.set("health", clampf(float(data.get("health", max_health)), 0.0, max_health))
	if player.has_signal("health_changed"):
		player.emit_signal("health_changed", player.get("health"), max_health)
	if player.has_method("set_guard"):
		player.call("set_guard", int(data.get("guard", player.get("guard"))))
	var max_shield := float(player.get("max_temporary_shield"))
	player.set("temporary_shield", clampf(float(data.get("temporary_shield", 0.0)), 0.0, max_shield))
	if player.has_signal("temporary_shield_changed"):
		player.emit_signal("temporary_shield_changed", player.get("temporary_shield"), max_shield)

func _apply_weapon(weapon: Variant, data: Dictionary) -> void:
	if weapon == null or data.is_empty():
		return
	weapon.set("ammo", clampi(int(data.get("ammo", weapon.get("ammo"))), 0, int(weapon.get("magazine_capacity"))))
	weapon.set("reserve_ammo", maxi(0, int(data.get("reserve_ammo", weapon.get("reserve_ammo")))))
	weapon.set("heat", maxf(0.0, float(data.get("heat", weapon.get("heat")))))
	if weapon.has_method("_emit_ammo"):
		weapon.call("_emit_ammo")
	if weapon.has_signal("heat_changed"):
		weapon.emit_signal("heat_changed", weapon.get("heat"), weapon.get("max_heat"))

func _apply_character_ability(runtime: Variant, data: Dictionary) -> void:
	if runtime == null or data.is_empty():
		return
	runtime.set("_active_cooldown", maxf(0.0, float(data.get("active_cooldown", 0.0))))
	runtime.set("_mara_kill_charge", maxi(0, int(data.get("mara_kill_charge", 0))))
	runtime.set("_kane_focus", maxi(0, int(data.get("kane_focus", 0))))
	runtime.set("_kane_chain_left", maxf(0.0, float(data.get("kane_chain_left", 0.0))))
	runtime.set("_kane_decay_left", maxf(0.0, float(data.get("kane_decay_left", 0.0))))
	runtime.set("_kane_free_shots", maxi(0, int(data.get("kane_free_shots", 0))))
	if runtime.has_method("_emit_active_state"):
		runtime.call("_emit_active_state")

func _apply_equipment(runtime: Variant, data: Dictionary) -> void:
	if runtime == null or data.is_empty() or not runtime.has_method("restore"):
		return
	runtime.call("restore", data)

func _restore_owned_rewards(context: Dictionary, raw_rewards: Variant) -> void:
	var owned = context.get("owned_rewards")
	if not (owned is Array) or not (raw_rewards is Array):
		return
	owned.clear()
	for reward in raw_rewards:
		owned.append(reward)

func _json_safe(value: Variant) -> Variant:
	if value is StringName:
		return String(value)
	if value is PackedStringArray:
		return Array(value)
	if value is Vector2i:
		return [value.x, value.y]
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value.keys():
			result[String(key)] = _json_safe(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_json_safe(item))
		return result
	return value

func has_save(path: String = DEFAULT_PATH) -> bool:
	return not load_payload(path).is_empty()

func delete_save(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
