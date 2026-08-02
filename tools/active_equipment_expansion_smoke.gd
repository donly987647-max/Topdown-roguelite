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
	var shield_payload: Dictionary = {}
	var vent_payload: Dictionary = {}
	for offer in offers:
		if offer == null or offer.category != &"active":
			continue
		active_ids.append(offer.id)
		if offer.id == &"shield_emitter":
			shield_payload = offer.payload.duplicate(true)
		elif offer.id == &"vent_purge":
			vent_payload = offer.payload.duplicate(true)
	_expect(active_ids.size() >= 4, "Zone 1 active equipment pool should contain at least four live items")
	for required_id in [&"repair_injector", &"overclock_key", &"shield_emitter", &"vent_purge"]:
		_expect(required_id in active_ids, "Missing live active equipment: %s" % String(required_id))
	var shield_activation: Dictionary = shield_payload.get("activation_payload", {})
	var vent_activation: Dictionary = vent_payload.get("activation_payload", {})
	_expect(StringName(shield_activation.get("effect", "")) == &"shield_pulse", "Shield Emitter catalog payload must use shield_pulse")
	_expect(StringName(vent_activation.get("effect", "")) == &"vent_purge", "Vent Purge catalog payload must use vent_purge")
	offers.clear()

func _test_instant_active_effects() -> void:
	var player := Player.new()
	var weapon := WeaponController.new()
	var inventory := RunInventoryRuntime.new()
	var backpack := BackpackState.new()
	_expect(inventory.configure(backpack, weapon, [], [], &"service_pistol"), "Active effect fixture inventory should configure")
	var equipment := RunEquipmentRuntime.new()
	root.add_child(equipment)
	_expect(equipment.configure(inventory, player, weapon), "Active effect fixture should use the normal configure path")

	player.temporary_shield = 0.0
	equipment.call("_on_equipment_activated", &"shield_emitter", {"effect":"shield_pulse", "amount":25.0})
	_expect(is_equal_approx(player.temporary_shield, 25.0), "Shield Emitter must grant 25 temporary shield")

	weapon.heat = 80.0
	equipment.call("_on_equipment_activated", &"vent_purge", {"effect":"vent_purge", "heat_removed":55.0})
	_expect(is_equal_approx(weapon.heat, 25.0), "Vent Purge must remove 55 heat without going below zero")

	equipment.free()
	inventory.free()
	player.free()
	weapon.free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
