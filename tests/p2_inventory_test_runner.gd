extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_item_profiles()
	_test_placement_rotation_and_overlap()
	_test_connection_propagation()
	_test_snapshot_and_auto_arrange()
	_test_equipped_part_swap_storage()
	if failures.is_empty():
		print("[P2 INVENTORY TEST] PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("[P2 INVENTORY TEST] %s" % failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_item_profiles() -> void:
	var items: Array[BackpackItemData] = []
	for index in WeaponPartCatalog.all_parts().size():
		var part := WeaponPartCatalog.all_parts()[index]
		var item := BackpackItemData.from_weapon_part(part, StringName("item_%02d" % index))
		items.append(item)
		_expect(item.validate_contract().is_empty(), "%s backpack profile is invalid" % part.display_name)
	_expect(items.size() == 12, "All twelve P2 parts require backpack profiles")
	_expect(items[5].cell_count() == 1, "Lightweight magazine must be a 1x1 item")
	_expect(items[6].cell_count() == 4, "Compressed magazine must be a 2x2 item")
	_expect(items[10].cell_count() == 4, "Clone core must use a T-shaped four-cell profile")
	var precision := BackpackItemData.from_weapon_part(WeaponPartCatalog.precision_barrel(), &"precision")
	var rotated := precision.cells_for_rotation(1)
	_expect(rotated.has(Vector2i(1, 0)), "Rotating a 1x2 item must produce a 2x1 footprint")
	_expect(not rotated.has(Vector2i(0, 1)), "Rotated precision barrel must no longer be vertical")

func _test_placement_rotation_and_overlap() -> void:
	var grid := BackpackGrid.new()
	var precision_id := grid.add_part(WeaponPartCatalog.precision_barrel(), &"precision")
	var magazine_id := grid.add_part(WeaponPartCatalog.extended_magazine(), &"magazine")
	_expect(grid.place_item(precision_id, Vector2i(0, 0)), "Precision barrel must fit at the top-left")
	_expect(not grid.place_item(magazine_id, Vector2i(0, 0)), "Items must not overlap")
	_expect(not grid.place_item(magazine_id, Vector2i(5, 4)), "Items must not extend outside the 6x5 bag")
	_expect(grid.place_item(magazine_id, Vector2i(2, 0), 1), "Rotated magazine must fit horizontally")
	_expect(grid.get_occupied_map().size() == 4, "Two 1x2 items must occupy four cells")
	_expect(grid.unplace_item(magazine_id), "Placed items must be removable from the grid")
	_expect(grid.get_unplaced_ids().has(magazine_id), "Unplaced items must remain owned")
	_expect(grid.auto_place(magazine_id), "Unplaced items must support automatic placement")

func _test_connection_propagation() -> void:
	var grid := BackpackGrid.new()
	var precision_id := grid.add_part(WeaponPartCatalog.precision_barrel(), &"precision")
	var impact_id := grid.add_part(WeaponPartCatalog.impact_core(), &"impact")
	var magazine_id := grid.add_part(WeaponPartCatalog.lightweight_magazine(), &"ammo")
	_expect(grid.place_item(precision_id, Vector2i(0, 0)), "Power seed item must fit on the power terminal")
	_expect(grid.place_item(impact_id, Vector2i(1, 0)), "Power neighbor must fit next to the seed")
	_expect(grid.place_item(magazine_id, Vector2i(5, 1)), "Ammo item must fit on the ammo terminal")
	var connections := grid.evaluate_connections()
	_expect(connections.has(precision_id), "Item touching power terminal must activate")
	_expect((connections[precision_id] as PackedStringArray).has("power"), "Power terminal must report power connection")
	_expect(connections.has(impact_id), "Matching adjacent connector must propagate activation")
	_expect((connections[impact_id] as PackedStringArray).has("power"), "Adjacent impact core must receive power")
	_expect(connections.has(magazine_id), "Ammo terminal item must activate")
	_expect((connections[magazine_id] as PackedStringArray).has("ammo"), "Ammo terminal must report ammo connection")

func _test_snapshot_and_auto_arrange() -> void:
	var grid := BackpackGrid.new()
	var subset := [
		WeaponPartCatalog.precision_barrel(),
		WeaponPartCatalog.spread_barrel(),
		WeaponPartCatalog.piercing_barrel(),
		WeaponPartCatalog.extended_magazine(),
		WeaponPartCatalog.lightweight_magazine(),
		WeaponPartCatalog.impact_core(),
		WeaponPartCatalog.photon_core(),
		WeaponPartCatalog.flame_core()
	]
	for index in subset.size():
		grid.add_part(subset[index], StringName("subset_%02d" % index))
	_expect(grid.auto_arrange(), "Prototype subset must auto-arrange into 6x5")
	_expect(not grid.has_unplaced_items(), "Successful auto-arrange must place every item")
	var snapshot := grid.create_snapshot()
	var occupied_before := grid.get_occupied_map().duplicate()
	var first_id := grid.get_item_ids()[0]
	grid.unplace_item(first_id)
	_expect(grid.has_unplaced_items(), "Manual unplacement must change inventory state")
	grid.restore_snapshot(snapshot)
	_expect(not grid.has_unplaced_items(), "Snapshot restore must recover all placements")
	_expect(grid.get_occupied_map() == occupied_before, "Snapshot restore must recover exact occupied cells")

	var full_grid := BackpackGrid.new()
	for index in WeaponPartCatalog.all_parts().size():
		full_grid.add_part(WeaponPartCatalog.all_parts()[index], StringName("full_%02d" % index))
	var full_snapshot := full_grid.create_snapshot()
	_expect(not full_grid.auto_arrange(), "Thirty-one cells of parts must not fit into a thirty-cell bag")
	_expect(full_grid.get_unplaced_ids().size() == 12, "Failed auto-arrange must restore the previous unplaced state")
	_expect((full_snapshot["placements"] as Dictionary).is_empty(), "Full-grid baseline must begin unplaced")

func _test_equipped_part_swap_storage() -> void:
	var grid := BackpackGrid.new()
	var spare_id := grid.add_part(WeaponPartCatalog.ricochet_barrel(), &"spare")
	_expect(grid.place_item(spare_id, Vector2i(1, 1)), "Spare barrel must be placeable")
	var selected := grid.remove_item(spare_id)
	_expect(selected != null and selected.part_id == &"ricochet_barrel", "Removing a backpack item must return its weapon part")
	var current_parts := WeaponPartCatalog.prototype_loadout_for(&"service_pistol")
	var old_barrel: WeaponPartData
	for part in current_parts:
		if part.slot == WeaponPartData.Slot.BARREL:
			old_barrel = part.duplicate_part()
	var next_parts := WeaponPartRewardPicker.replace_slot(current_parts, selected)
	_expect(WeaponPartRewardPicker.equipped_ids(next_parts).has("ricochet_barrel"), "Backpack part must replace the matching equipped slot")
	var returned_id := grid.add_and_auto_place(old_barrel, &"returned")
	_expect(returned_id != &"" and grid.get_placement(returned_id).size() > 0, "Replaced equipped part must return to available backpack space")
