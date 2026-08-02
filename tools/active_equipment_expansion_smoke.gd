extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_catalog_contract()
	_test_instant_active_effects()
	if failures.is_empty():
		print("ACTIVE_EQUIPMENT_EXPANSION_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_catalog_contract() -> void:
	var offers := Zone1RewardCatalog.new().offers()
	var active_ids: Array[StringName] = []
	for offer in offers:
		if offer != null and offer.category == &"active":
			active_ids.append(offer.id)
	_expect(active_ids.size() >= 4, "Zone 1 active equipment pool should contain at least four live items")
	for required_id in [&"repair_injector", &"overclock_key", &"shield_emitter", &"vent_purge"]:
		_expect(required_id in active_ids, "Missing live active equipment: %s" % String(required_id))

	var backpack := BackpackState.new()
	var weapon := WeaponController.new()
	var inventory := RunInventoryRuntime.new()
	_expect(StarterWeaponRuntime.new().apply(weapon, &"service_pistol"), "Active catalog smoke needs a starter weapon")
	_expect(inventory.configure(backpack, weapon, [], offers, &"service_pistol"), "Active catalog inventory should configure")
	var shield := inventory.definition_for(&"shield_emitter") as ActiveEquipmentDefinition
	var vent := inventory.definition_for(&"vent_purge") as ActiveEquipmentDefinition
	_expect(shield != null and StringName(shield.activation_payload.get("effect", "")) == &"shield_pulse", "Shield Emitter must convert into a shield_pulse active definition")
	_expect(vent != null and StringName(vent.activation_payload.get("effect", "")) == &"vent_purge", "Vent Purge must convert into a vent_purge active definition")
	inventory.free()
	weapon.free()

func _test_instant_active_effects() -> void:
	var player := Player.new()
	var weapon := WeaponController.new()
	var equipment := RunEquipmentRuntime.new()
	root.add_child(equipment)
	equipment.player = player
	equipment.weapon = weapon

	player.temporary_shield = 0.0
	equipment.call("_on_equipment_activated", &"shield_emitter", {"effect":"shield_pulse", "amount":25.0})
	_expect(is_equal_approx(player.temporary_shield, 25.0), "Shield Emitter must grant 25 temporary shield")

	weapon.heat = 80.0
	equipment.call("_on_equipment_activated", &"vent_purge", {"effect":"vent_purge", "heat_removed":55.0})
	_expect(is_equal_approx(weapon.heat, 25.0), "Vent Purge must remove 55 heat without going below zero")

	equipment.free()
	player.free()
	weapon.free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
