extends SceneTree

var failures: Array[String] = []
var captured_options: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_picker_contract()
	await _test_room_reward_contract()
	if failures.is_empty():
		print("[P2 REWARD TEST] PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("[P2 REWARD TEST] %s" % failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_picker_contract() -> void:
	var current := WeaponPartCatalog.prototype_loadout_for(&"service_pistol")
	var excluded := WeaponPartRewardPicker.equipped_ids(current)
	var options := WeaponPartRewardPicker.roll_options(3, excluded)
	_expect(options.size() == 3, "Reward picker must return three options")
	var option_ids: Dictionary = {}
	for option in options:
		_expect(not excluded.has(String(option.part_id)), "Reward options must exclude currently equipped parts")
		_expect(not option_ids.has(option.part_id), "Reward options must be unique")
		option_ids[option.part_id] = true

	var selected: WeaponPartData = options[0]
	var replaced := WeaponPartRewardPicker.replace_slot(current, selected)
	_expect(replaced.size() == 3, "Replacing a weapon slot must preserve a three-part loadout")
	var slot_counts: Dictionary = {}
	var selected_found := false
	for part in replaced:
		slot_counts[part.slot] = int(slot_counts.get(part.slot, 0)) + 1
		if part.part_id == selected.part_id:
			selected_found = true
	_expect(selected_found, "Selected reward must appear in the replaced loadout")
	_expect(int(slot_counts.get(WeaponPartData.Slot.BARREL, 0)) == 1, "Loadout must contain one barrel")
	_expect(int(slot_counts.get(WeaponPartData.Slot.MAGAZINE, 0)) == 1, "Loadout must contain one magazine")
	_expect(int(slot_counts.get(WeaponPartData.Slot.CORE, 0)) == 1, "Loadout must contain one core")

func _test_room_reward_contract() -> void:
	var world := Node2D.new()
	world.name = "P2RewardTestWorld"
	root.add_child(world)
	current_scene = world
	var room := TestCombatRoom.new()
	world.add_child(room)
	room.reward_requested.connect(_capture_reward)
	await process_frame

	for child in room.get_children():
		if child.is_in_group("enemy"):
			child.queue_free()
	await process_frame
	await process_frame

	_expect(captured_options.size() == 3, "Clearing the room must emit three weapon-part rewards")
	if captured_options.size() == 3:
		var selected := captured_options[0] as WeaponPartData
		var next_parts := WeaponPartRewardPicker.replace_slot(room.player.weapon.equipped_parts, selected)
		room.player.weapon.equip_parts(next_parts)
		var snapshot := room.player.weapon.get_build_snapshot()
		var part_ids: PackedStringArray = snapshot.get("part_ids", PackedStringArray())
		_expect(part_ids.has(String(selected.part_id)), "Selected room reward must equip on the active weapon")
		_expect(part_ids.size() == 3, "Reward equip must preserve one part per slot")

	world.queue_free()
	await process_frame

func _capture_reward(options: Array) -> void:
	captured_options = options.duplicate()
