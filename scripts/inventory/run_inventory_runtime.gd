class_name RunInventoryRuntime
extends Node

signal inventory_changed
signal build_changed(build: WeaponBuild)
signal action_failed(message: String)

const EQUIPMENT_CATEGORIES := [&"passive", &"active", &"item"]
const WEAPON_CATEGORIES := [&"frame", &"barrel", &"magazine", &"core"]

var backpack: BackpackState
var weapon: WeaponController
var owned_rewards: Array
var reward_offers: Dictionary = {}
var owned_by_category: Dictionary = {}
var starting_frame_id: StringName = &""
var frame_catalog := WeaponFrameCatalog.new()
var part_catalog := WeaponPartCatalog.new()
var starter_runtime := StarterWeaponRuntime.new()
var _undo_backpack: Dictionary = {}
var _undo_instances: Array[String] = []
var _undo_active_flags: Array[bool] = []

func configure(backpack_state: BackpackState, weapon_controller: WeaponController, reward_records: Array, catalog_offers: Array[RewardOffer], initial_frame_id: StringName = &"") -> bool:
	backpack = backpack_state
	weapon = weapon_controller
	owned_rewards = reward_records
	starting_frame_id = initial_frame_id
	_clear_undo()
	reward_offers.clear()
	for offer in catalog_offers:
		if offer == null:
			continue
		reward_offers[offer.id] = offer
		_register_backpack_definition(offer)
	_rebuild_owned_index()
	if starting_frame_id != &"":
		_add_owned_id(&"frame", starting_frame_id)
	_sync_record_instances()
	_sync_active_equipment_selection()
	inventory_changed.emit()
	return backpack != null

func add_reward_offer(offer: RewardOffer) -> bool:
	if offer == null or offer.id == &"" or owned_rewards == null:
		return false
	var record := offer.to_dictionary()
	record["backpack_instance_id"] = ""
	record["active_equipped"] = false
	owned_rewards.append(record)
	_add_owned_id(offer.category, offer.id)
	if offer.category in EQUIPMENT_CATEGORIES:
		_register_backpack_definition(offer)
		var instance_id := backpack.auto_place(offer.id)
		if instance_id != &"":
			record["backpack_instance_id"] = String(instance_id)
	elif offer.category in WEAPON_CATEGORIES:
		_equip_if_slot_empty(offer.id, offer.category)
	_sync_active_equipment_selection()
	inventory_changed.emit()
	return true

func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(owned_rewards.size()):
		var raw: Variant = owned_rewards[index]
		if not (raw is Dictionary):
			continue
		var record := raw as Dictionary
		var category := StringName(record.get("category", ""))
		if category not in EQUIPMENT_CATEGORIES:
			continue
		result.append({
			"record_index": index,
			"definition_id": StringName(record.get("id", "")),
			"instance_id": StringName(record.get("backpack_instance_id", "")),
			"category": category,
			"rarity": StringName(record.get("rarity", "common")),
			"payload": record.get("payload", {}),
			"active_equipped": bool(record.get("active_equipped", false)),
		})
	return result

func entry_for_instance(instance_id: StringName) -> Dictionary:
	for entry in entries():
		if entry["instance_id"] == instance_id:
			return entry
	return {}

func definition_for(id: StringName) -> BackpackItemDefinition:
	if backpack == null:
		return null
	return backpack.definitions.get(id)

func display_data(id: StringName) -> Dictionary:
	var offer: RewardOffer = reward_offers.get(id)
	if offer != null:
		return offer.to_dictionary()
	var frame := frame_catalog.get_frame(id)
	if frame != null:
		return {"id": id, "category": &"frame", "rarity": &"common", "payload": {"display_name": frame.display_name, "description": frame.role, "tags": Array(frame.compatibility_tags)}}
	for category in [&"barrel", &"magazine", &"core"]:
		var part := part_catalog.get_for_category(id, category)
		if part != null:
			return {"id": id, "category": category, "rarity": part.rarity, "payload": {"display_name": part.display_name, "description": part.description, "tags": Array(part.tags), "power": part.power_cost, "weight": part.weight}}
	return {"id": id, "category": &"item", "rarity": &"common", "payload": {"display_name": String(id), "description": ""}}

func place_record(record_index: int, origin: Vector2i) -> bool:
	if not _valid_equipment_record(record_index):
		return false
	_snapshot_for_undo()
	var record := owned_rewards[record_index] as Dictionary
	var definition_id := StringName(record.get("id", ""))
	var instance_id := StringName(record.get("backpack_instance_id", ""))
	var rotation := 0
	if instance_id != &"" and backpack.grid.placements.has(instance_id):
		rotation = int(backpack.grid.placement(instance_id).get("rotation", 0))
		backpack.remove_item(instance_id)
	else:
		instance_id = &""
	var placed := backpack.add_item(definition_id, origin, rotation, instance_id)
	if placed == &"":
		_restore_undo_snapshot(false)
		action_failed.emit("해당 위치에 배치할 수 없습니다.")
		return false
	record["backpack_instance_id"] = String(placed)
	_sync_active_equipment_selection()
	inventory_changed.emit()
	return true

func can_place_record(record_index: int, origin: Vector2i) -> bool:
	if not _valid_equipment_record(record_index):
		return false
	var record := owned_rewards[record_index] as Dictionary
	var definition := definition_for(StringName(record.get("id", "")))
	if definition == null:
		return false
	var instance_id := StringName(record.get("backpack_instance_id", ""))
	var rotation := 0
	if instance_id != &"" and backpack.grid.placements.has(instance_id):
		rotation = int(backpack.grid.placement(instance_id).get("rotation", 0))
	else:
		instance_id = &"__drag_probe__"
	var cells := backpack._rotated_cells(definition, rotation)
	return backpack.grid.can_place(instance_id, cells, origin)

func auto_place_record(record_index: int) -> bool:
	if not _valid_equipment_record(record_index):
		return false
	var record := owned_rewards[record_index] as Dictionary
	var current := StringName(record.get("backpack_instance_id", ""))
	if current != &"" and backpack.grid.placements.has(current):
		return true
	_snapshot_for_undo()
	var instance_id := backpack.auto_place(StringName(record.get("id", "")))
	if instance_id == &"":
		_restore_undo_snapshot(false)
		action_failed.emit("가방에 빈 공간이 없습니다.")
		return false
	record["backpack_instance_id"] = String(instance_id)
	_sync_active_equipment_selection()
	inventory_changed.emit()
	return true

func remove_record_to_stash(record_index: int) -> bool:
	if not _valid_equipment_record(record_index):
		return false
	var record := owned_rewards[record_index] as Dictionary
	var instance_id := StringName(record.get("backpack_instance_id", ""))
	if instance_id == &"":
		return false
	_snapshot_for_undo()
	if not backpack.remove_item(instance_id):
		_restore_undo_snapshot(false)
		return false
	record["backpack_instance_id"] = ""
	_sync_active_equipment_selection()
	inventory_changed.emit()
	return true

func rotate_record(record_index: int, clockwise: bool = true) -> bool:
	if not _valid_equipment_record(record_index):
		return false
	var record := owned_rewards[record_index] as Dictionary
	var instance_id := StringName(record.get("backpack_instance_id", ""))
	if instance_id == &"":
		return false
	_snapshot_for_undo()
	if not backpack.grid.rotate_item(instance_id, clockwise):
		_restore_undo_snapshot(false)
		action_failed.emit("현재 위치에서는 회전할 수 없습니다.")
		return false
	inventory_changed.emit()
	return true

func auto_sort() -> bool:
	if backpack == null:
		return false
	_snapshot_for_undo()
	var placed: Array[Dictionary] = []
	for entry in entries():
		var instance_id := StringName(entry["instance_id"])
		if instance_id == &"" or not backpack.grid.placements.has(instance_id):
			continue
		var definition := definition_for(StringName(entry["definition_id"]))
		placed.append({"record_index": int(entry["record_index"]), "instance_id": instance_id, "definition": definition})
	placed.sort_custom(func(a: Dictionary, b: Dictionary):
		var a_definition: BackpackItemDefinition = a.get("definition")
		var b_definition: BackpackItemDefinition = b.get("definition")
		var a_size := a_definition.cells.size() if a_definition != null else 0
		var b_size := b_definition.cells.size() if b_definition != null else 0
		return a_size > b_size
	)
	for item in placed:
		backpack.remove_item(StringName(item["instance_id"]))
	for item in placed:
		var record_index := int(item["record_index"])
		var record := owned_rewards[record_index] as Dictionary
		var definition_id := StringName(record.get("id", ""))
		var instance_id := StringName(item["instance_id"])
		var new_id := _auto_place_existing(definition_id, instance_id)
		if new_id == &"":
			_restore_undo_snapshot(false)
			action_failed.emit("자동 정렬에 실패해 이전 배치를 복원했습니다.")
			return false
		record["backpack_instance_id"] = String(new_id)
	inventory_changed.emit()
	return true

func undo() -> bool:
	if _undo_backpack.is_empty() or backpack == null:
		return false
	return _restore_undo_snapshot(true)

func can_undo() -> bool:
	return not _undo_backpack.is_empty()

func available_ids(category: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var raw: Variant = owned_by_category.get(category, [])
	if raw is Array:
		for value in raw:
			var id := StringName(value)
			if id != &"" and id not in result:
				result.append(id)
	return result

func first_removable_record_index() -> int:
	for index in range(owned_rewards.size()):
		if can_remove_owned_record(index):
			return index
	return -1

func can_remove_owned_record(index: int) -> bool:
	if owned_rewards == null or index < 0 or index >= owned_rewards.size():
		return false
	var raw: Variant = owned_rewards[index]
	if not (raw is Dictionary):
		return false
	var record := raw as Dictionary
	var category := StringName(record.get("category", ""))
	if category in [&"boss_part", &"zone_key", &"record"]:
		return false
	if category in WEAPON_CATEGORIES:
		var id := StringName(record.get("id", ""))
		var equipped := StringName(equipped_ids().get(String(category), ""))
		if id == equipped and _owned_record_count(id, category) <= 1:
			return false
	return true

func remove_owned_record(index: int) -> bool:
	if not can_remove_owned_record(index):
		return false
	var record := owned_rewards[index] as Dictionary
	var instance_id := StringName(record.get("backpack_instance_id", ""))
	if instance_id != &"" and backpack != null and backpack.grid.placements.has(instance_id):
		if not backpack.remove_item(instance_id):
			return false
	owned_rewards.remove_at(index)
	_clear_undo()
	_rebuild_owned_index()
	_sync_active_equipment_selection()
	inventory_changed.emit()
	return true

func equipped_ids() -> Dictionary:
	var result := {"frame": &"", "barrel": &"", "magazine": &"", "core": &""}
	if weapon == null or weapon.weapon_build == null:
		return result
	var build := weapon.weapon_build
	result["frame"] = build.frame.id if build.frame != null else &""
	result["barrel"] = build.barrel.id if build.barrel != null else &""
	result["magazine"] = build.magazine.id if build.magazine != null else &""
	result["core"] = build.core.id if build.core != null else &""
	return result

func cycle_equipped(category: StringName) -> bool:
	var ids := available_ids(category)
	if ids.is_empty():
		return false
	var current := StringName(equipped_ids().get(String(category), &""))
	var index := ids.find(current)
	var next_id := ids[posmod(index + 1, ids.size())]
	return equip(next_id, category)

func equip(id: StringName, category: StringName) -> bool:
	if weapon == null or id not in available_ids(category):
		return false
	var old := weapon.weapon_build
	var build := WeaponBuild.new()
	if old != null:
		build.frame = old.frame
		build.barrel = old.barrel
		build.magazine = old.magazine
		build.core = old.core
	match category:
		&"frame":
			var frame := frame_catalog.get_frame(id)
			if frame == null:
				return false
			build.frame = frame
		&"barrel": build.barrel = part_catalog.get_for_category(id, category)
		&"magazine": build.magazine = part_catalog.get_for_category(id, category)
		&"core": build.core = part_catalog.get_for_category(id, category)
		_: return false
	if build.frame == null:
		return false
	if build.is_complete():
		if not weapon.apply_build(build):
			action_failed.emit("호환되지 않는 무기 조합입니다.")
			return false
		weapon.ammo = mini(weapon.ammo, weapon.magazine_capacity)
		weapon.call("_emit_ammo")
	else:
		if category == &"frame":
			var barrel := build.barrel
			var magazine := build.magazine
			var core := build.core
			if not starter_runtime.apply(weapon, id):
				return false
			build = weapon.weapon_build
			build.barrel = barrel
			build.magazine = magazine
			build.core = core
		else:
			weapon.weapon_build = build
	build_changed.emit(build)
	inventory_changed.emit()
	return true

func restore_equipment(data: Dictionary) -> void:
	for category in [&"frame", &"barrel", &"magazine", &"core"]:
		var id := StringName(data.get(String(category) + "_id", ""))
		if id != &"" and id in available_ids(category):
			equip(id, category)

func active_equipment_entry() -> Dictionary:
	for entry in entries():
		if StringName(entry.get("category", "")) != &"active":
			continue
		if StringName(entry.get("instance_id", "")) == &"":
			continue
		if bool(entry.get("active_equipped", false)):
			return entry
	return {}

func equip_active_record(record_index: int) -> bool:
	if not _valid_equipment_record(record_index):
		return false
	var selected := owned_rewards[record_index] as Dictionary
	if StringName(selected.get("category", "")) != &"active" or StringName(selected.get("backpack_instance_id", "")) == &"":
		return false
	for raw in owned_rewards:
		if raw is Dictionary and StringName(raw.get("category", "")) == &"active":
			raw["active_equipped"] = false
	selected["active_equipped"] = true
	inventory_changed.emit()
	return true

func synergy_summary() -> Dictionary:
	if backpack == null:
		return {}
	return BackpackSynergyResolver.new().resolve(backpack.grid)

func _register_backpack_definition(offer: RewardOffer) -> void:
	if backpack == null or offer == null or offer.category not in EQUIPMENT_CATEGORIES:
		return
	var payload: Dictionary = offer.payload if offer.payload is Dictionary else {}
	var definition: BackpackItemDefinition
	if offer.category == &"active":
		definition = ActiveEquipmentDefinition.new()
	else:
		definition = PassiveModuleDefinition.new()
	definition.id = offer.id
	definition.display_name = String(payload.get("display_name", String(offer.id)))
	definition.description = String(payload.get("description", ""))
	definition.rarity = offer.rarity
	definition.cells = _cells_from_payload(payload.get("cells", [[0, 0]]))
	definition.rotatable = bool(payload.get("rotatable", true))
	var connectors: Variant = payload.get("connectors", {})
	definition.connector_types = connectors if connectors is Dictionary else {}
	var tags: Variant = payload.get("tags", [])
	definition.tags = PackedStringArray(tags if tags is Array or tags is PackedStringArray else [])
	definition.power_draw = float(payload.get("power_draw", 0.0))
	definition.power_supply = float(payload.get("power_supply", 0.0))
	definition.ammo_supply = float(payload.get("ammo_supply", 0.0))
	definition.cooling_supply = float(payload.get("cooling_supply", 0.0))
	definition.signal_strength = float(payload.get("signal_strength", 0.0))
	definition.requires_power = bool(payload.get("requires_power", false))
	var adjacency_effects: Variant = payload.get("adjacency_effect_ids", [])
	definition.adjacency_effect_ids = PackedStringArray(adjacency_effects if adjacency_effects is Array or adjacency_effects is PackedStringArray else [])
	var effect_ids: Variant = payload.get("effect_ids", [])
	definition.effect_ids = PackedStringArray(effect_ids if effect_ids is Array or effect_ids is PackedStringArray else [])
	if definition is PassiveModuleDefinition:
		var passive := definition as PassiveModuleDefinition
		var stat_modifiers: Variant = payload.get("stat_modifiers", {})
		passive.stat_modifiers = stat_modifiers if stat_modifiers is Dictionary else {}
		var trigger_effects: Variant = payload.get("trigger_effect_ids", [])
		passive.trigger_effect_ids = PackedStringArray(trigger_effects if trigger_effects is Array or trigger_effects is PackedStringArray else [])
		passive.max_stacks = maxi(1, int(payload.get("max_stacks", 1)))
	elif definition is ActiveEquipmentDefinition:
		var active := definition as ActiveEquipmentDefinition
		active.cooldown = maxf(0.0, float(payload.get("cooldown", 8.0)))
		active.charges = maxi(0, int(payload.get("charges", 0)))
		var activation_payload: Variant = payload.get("activation_payload", {})
		active.activation_payload = activation_payload if activation_payload is Dictionary else {}
	backpack.register_definition(definition)

func _cells_from_payload(value: Variant) -> PackedVector2Array:
	var result := PackedVector2Array()
	if value is Array:
		for raw in value:
			if raw is Array and raw.size() >= 2:
				result.append(Vector2(float(raw[0]), float(raw[1])))
	if result.is_empty():
		result.append(Vector2.ZERO)
	return result

func _rebuild_owned_index() -> void:
	owned_by_category.clear()
	if owned_rewards == null:
		return
	for raw in owned_rewards:
		if not (raw is Dictionary):
			continue
		_add_owned_id(StringName(raw.get("category", "")), StringName(raw.get("id", "")))

func _add_owned_id(category: StringName, id: StringName) -> void:
	if category == &"" or id == &"":
		return
	if not owned_by_category.has(category):
		owned_by_category[category] = []
	var ids: Array = owned_by_category[category]
	if id not in ids:
		ids.append(id)

func _sync_record_instances() -> void:
	if backpack == null or owned_rewards == null:
		return
	var claimed: Dictionary = {}
	for index in range(owned_rewards.size()):
		var raw: Variant = owned_rewards[index]
		if not (raw is Dictionary):
			continue
		var record := raw as Dictionary
		var category := StringName(record.get("category", ""))
		if category not in EQUIPMENT_CATEGORIES:
			continue
		var stored := StringName(record.get("backpack_instance_id", ""))
		if stored != &"" and backpack.grid.placements.has(stored):
			claimed[stored] = true
			continue
		var definition_id := StringName(record.get("id", ""))
		for instance_id in backpack.instance_to_definition.keys():
			if claimed.has(instance_id):
				continue
			if backpack.instance_to_definition[instance_id] == definition_id:
				record["backpack_instance_id"] = String(instance_id)
				claimed[instance_id] = true
				break

func _sync_active_equipment_selection() -> void:
	if owned_rewards == null:
		return
	var selected_index := -1
	var fallback_index := -1
	for index in range(owned_rewards.size()):
		var raw: Variant = owned_rewards[index]
		if not (raw is Dictionary):
			continue
		var record := raw as Dictionary
		if StringName(record.get("category", "")) != &"active":
			continue
		var placed := StringName(record.get("backpack_instance_id", "")) != &""
		if placed and fallback_index < 0:
			fallback_index = index
		if placed and bool(record.get("active_equipped", false)) and selected_index < 0:
			selected_index = index
		else:
			record["active_equipped"] = false
	if selected_index < 0:
		selected_index = fallback_index
	if selected_index >= 0 and owned_rewards[selected_index] is Dictionary:
		owned_rewards[selected_index]["active_equipped"] = true

func _valid_equipment_record(index: int) -> bool:
	if backpack == null or owned_rewards == null or index < 0 or index >= owned_rewards.size():
		return false
	var raw: Variant = owned_rewards[index]
	return raw is Dictionary and StringName(raw.get("category", "")) in EQUIPMENT_CATEGORIES

func _snapshot_for_undo() -> void:
	_undo_backpack = backpack.serialize().duplicate(true)
	_undo_instances.clear()
	_undo_active_flags.clear()
	for raw in owned_rewards:
		if raw is Dictionary:
			_undo_instances.append(String(raw.get("backpack_instance_id", "")))
			_undo_active_flags.append(bool(raw.get("active_equipped", false)))
		else:
			_undo_instances.append("")
			_undo_active_flags.append(false)

func _restore_undo_snapshot(clear_after: bool) -> bool:
	if backpack == null or _undo_backpack.is_empty() or not backpack.restore(_undo_backpack):
		return false
	for index in range(mini(owned_rewards.size(), _undo_instances.size())):
		if owned_rewards[index] is Dictionary:
			owned_rewards[index]["backpack_instance_id"] = _undo_instances[index]
			if index < _undo_active_flags.size():
				owned_rewards[index]["active_equipped"] = _undo_active_flags[index]
	_sync_active_equipment_selection()
	if clear_after:
		_undo_backpack.clear()
		_undo_instances.clear()
		_undo_active_flags.clear()
	inventory_changed.emit()
	return true

func _auto_place_existing(definition_id: StringName, instance_id: StringName) -> StringName:
	var definition: BackpackItemDefinition = backpack.definitions.get(definition_id)
	if definition == null:
		return &""
	var rotations := 4 if definition.rotatable else 1
	for turn in range(rotations):
		var cells := backpack._rotated_cells(definition, turn)
		for y in range(backpack.grid.height):
			for x in range(backpack.grid.width):
				if backpack.grid.can_place(instance_id, cells, Vector2i(x, y)):
					return backpack.add_item(definition_id, Vector2i(x, y), turn, instance_id)
	return &""

func _equip_if_slot_empty(id: StringName, category: StringName) -> void:
	var current := StringName(equipped_ids().get(String(category), &""))
	if current == &"":
		equip(id, category)

func _owned_record_count(id: StringName, category: StringName) -> int:
	var count := 0
	for raw in owned_rewards:
		if raw is Dictionary and StringName(raw.get("id", "")) == id and StringName(raw.get("category", "")) == category:
			count += 1
	return count

func _clear_undo() -> void:
	_undo_backpack.clear()
	_undo_instances.clear()
	_undo_active_flags.clear()
