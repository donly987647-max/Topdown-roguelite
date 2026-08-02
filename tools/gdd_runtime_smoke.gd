extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	_test_backpack_grid_contract()
	_test_directional_power_link()
	_test_duplicate_backpack_instances()
	_test_weapon_payload_contract()
	_test_run_inventory_contract()
	if _failures.is_empty():
		print("GDD runtime smoke: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("GDD runtime smoke: FAIL (%d)" % _failures.size())
	quit(1)

func _test_backpack_grid_contract() -> void:
	var grid := BackpackGrid.new()
	_assert(grid.place(&"legacy", [Vector2i.ZERO], Vector2i(0, 0)), "legacy BackpackGrid.place should work")
	_assert(grid.item_at(Vector2i.ZERO) == &"legacy", "occupancy lookup should return placed item")
	_assert(grid.remove(&"legacy"), "legacy placement should be removable")

func _test_directional_power_link() -> void:
	var source := BackpackItemDefinition.new()
	source.id = &"battery"
	source.cells = PackedVector2Array([Vector2.ZERO])
	source.power_supply = 10.0
	source.connector_types = {"right": "power_out"}
	var consumer := BackpackItemDefinition.new()
	consumer.id = &"module"
	consumer.cells = PackedVector2Array([Vector2.ZERO])
	consumer.power_draw = 6.0
	consumer.requires_power = true
	consumer.connector_types = {"left": "power_in"}
	var grid := BackpackGrid.new()
	_assert(grid.place_item(source, Vector2i(1, 1)), "power source should place")
	_assert(grid.place_item(consumer, Vector2i(2, 1)), "power consumer should place")
	var result := BackpackSynergyResolver.new().resolve(grid)
	_assert(result["connector_links"].size() == 1, "facing power terminals should create exactly one link")
	_assert(bool(result["powered_items"].get(&"module", false)), "consumer inside powered network should be powered")
	_assert(absf(float(result["power_supply"]) - 10.0) < 0.001, "power supply total should be 10")
	_assert(absf(float(result["power_draw"]) - 6.0) < 0.001, "power draw total should be 6")

func _test_duplicate_backpack_instances() -> void:
	var definition := BackpackItemDefinition.new()
	definition.id = &"duplicate_module"
	definition.cells = PackedVector2Array([Vector2.ZERO])
	var backpack := BackpackState.new()
	backpack.register_definition(definition)
	_assert(backpack.auto_place(definition.id) != &"", "first duplicate module should auto-place")
	_assert(backpack.auto_place(definition.id) != &"", "second duplicate module should auto-place")
	var result := BackpackSynergyResolver.new().resolve(backpack.grid)
	_assert(result["powered_items"].size() == 2, "duplicate definitions must retain distinct runtime network identities")

func _test_weapon_payload_contract() -> void:
	var frame := WeaponFrameDefinition.new()
	frame.id = &"service_pistol"
	var barrel := WeaponPartDefinition.new()
	barrel.id = &"piercing_barrel"
	barrel.part_type = WeaponPartDefinition.PartType.BARREL
	var magazine := WeaponPartDefinition.new()
	magazine.id = &"cross_mag"
	magazine.part_type = WeaponPartDefinition.PartType.MAGAZINE
	var core := WeaponPartDefinition.new()
	core.id = &"electric_core"
	core.part_type = WeaponPartDefinition.PartType.CORE
	core.effect_ids = PackedStringArray(["shock"])
	var build := WeaponBuild.new()
	build.frame = frame
	build.barrel = barrel
	build.magazine = magazine
	build.core = core
	var payload := WeaponEffectResolver.shot_payload(build, build.computed_stats())
	_assert(int(payload["pierce"]) >= 2, "piercing barrel should add two pierces")
	_assert(bool(payload["cross_mag"]), "cross magazine payload flag should be present")
	_assert(StringName(payload["status_id"]) == &"shock", "electric core should resolve shock payload")

func _test_run_inventory_contract() -> void:
	var offers := Zone1RewardCatalog.new().offers()
	var backpack := BackpackState.new()
	var weapon := WeaponController.new()
	_assert(StarterWeaponRuntime.new().apply(weapon, &"service_pistol"), "starter weapon should apply before inventory assembly")
	var owned: Array = []
	var runtime := RunInventoryRuntime.new()
	_assert(runtime.configure(backpack, weapon, owned, offers, &"service_pistol"), "run inventory should configure")
	var feed_ramp := _find_offer(offers, &"feed_ramp")
	_assert(feed_ramp != null and runtime.add_reward_offer(feed_ramp), "module reward should enter the run inventory")
	var entries := runtime.entries()
	_assert(entries.size() == 1, "module reward should create one backpack record")
	if not entries.is_empty():
		var record_index := int(entries[0]["record_index"])
		var instance_id := StringName(entries[0]["instance_id"])
		var original_origin: Vector2i = backpack.grid.placement(instance_id).get("origin", Vector2i.ZERO)
		_assert(runtime.place_record(record_index, Vector2i(3, 2)), "placed module should move to an empty target cell")
		_assert(runtime.undo(), "inventory placement should support one-step undo")
		var restored_id := StringName(runtime.entries()[0]["instance_id"])
		_assert(backpack.grid.placement(restored_id).get("origin", Vector2i(-1, -1)) == original_origin, "undo should restore the prior module origin")
	for id in [&"precision_barrel", &"extended_mag", &"fire_core"]:
		var offer := _find_offer(offers, id)
		_assert(offer != null and runtime.add_reward_offer(offer), "weapon part reward should be grantable: %s" % String(id))
	_assert(weapon.weapon_build != null and weapon.weapon_build.is_complete(), "three acquired parts should complete the equipped weapon build")
	if weapon.weapon_build != null and weapon.weapon_build.is_complete():
		var payload := WeaponEffectResolver.shot_payload(weapon.weapon_build, weapon.weapon_build.computed_stats())
		_assert(StringName(payload.get("status_id", "")) == &"burn", "equipped fire core should affect the live shot payload")
	var restored_weapon := WeaponController.new()
	_assert(StarterWeaponRuntime.new().apply(restored_weapon, &"service_pistol"), "restored inventory needs a starter frame baseline")
	var restored_runtime := RunInventoryRuntime.new()
	_assert(restored_runtime.configure(BackpackState.new(), restored_weapon, owned.duplicate(true), offers, &"service_pistol"), "restored inventory should configure")
	restored_runtime.restore_equipment({"frame_id":"service_pistol", "barrel_id":"precision_barrel", "magazine_id":"extended_mag", "core_id":"fire_core"})
	var restored_ids := restored_runtime.equipped_ids()
	_assert(StringName(restored_ids.get("barrel", "")) == &"precision_barrel" and StringName(restored_ids.get("magazine", "")) == &"extended_mag" and StringName(restored_ids.get("core", "")) == &"fire_core", "saved weapon part IDs should restore the assembled build")
	restored_runtime.free()
	restored_weapon.free()
	runtime.free()
	weapon.free()

func _find_offer(offers: Array[RewardOffer], id: StringName) -> RewardOffer:
	for offer in offers:
		if offer != null and offer.id == id:
			return offer
	return null

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
