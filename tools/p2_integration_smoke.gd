extends SceneTree

var failures: Array[String] = []

class EquipmentStateStub:
	extends RefCounted
	var restored: Dictionary = {}

	func serialize() -> Dictionary:
		return {"active_instance_id":"repair_injector#1", "equipment_states":{"repair_injector#1":{"cooldown_remaining":7.5,"charges_remaining":0}}}

	func restore(data: Dictionary) -> void:
		restored = data.duplicate(true)

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_zone1_content()
	_test_zone1_module_content()
	_test_threat_budget()
	_test_wallet()
	_test_ui_resources()
	_test_save_roundtrip()
	if failures.is_empty():
		print("P2_INTEGRATION_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_zone1_content() -> void:
	var catalog := Zone1ContentCatalog.new()
	var rooms := catalog.room_templates()
	var enemies := catalog.enemy_profiles()
	_expect(rooms.size() >= 11, "Zone 1 starter room catalog too small")
	var regular_count := 0
	var elite_count := 0
	var regular_ids: Array[StringName] = []
	for profile in enemies:
		if &"boss" in profile.tags:
			continue
		if profile.elite:
			elite_count += 1
		else:
			regular_count += 1
			regular_ids.append(profile.id)
	_expect(regular_count >= 8, "Zone 1 P4 requires at least eight distinct regular enemies")
	_expect(elite_count >= 2, "Zone 1 content batch should retain at least two elite variants")
	for required_id in [&"scrap_runner", &"line_guard", &"bolt_spitter", &"fork_drone", &"crusher_brute", &"weld_hound", &"riveter", &"overwatch_turret"]:
		_expect(required_id in regular_ids, "Missing Zone 1 regular enemy: %s" % String(required_id))
	for room in rooms:
		_expect(room.validate_definition().is_empty(), "Invalid room template: %s" % String(room.id))
	var spawn_registry := EnemySpawnRegistry.new()
	var registry := RoomTemplateRegistry.new()
	var planner := ThreatBudgetPlanner.new()
	catalog.register_into(registry, planner, spawn_registry)
	for profile in enemies:
		_expect(spawn_registry.has_enemy(profile.id), "Enemy scene did not register: %s" % String(profile.id))
	var combat: RoomTemplateDefinition = registry.get_template(&"z1_line_a")
	var builder := AuthoredRoomShellBuilder.new()
	var shell := builder.build(combat)
	_expect(shell != null and shell.get_child_count() > 0, "Authored room shell failed to build")
	shell.free()

func _test_zone1_module_content() -> void:
	var offers := Zone1RewardCatalog.new().offers()
	var passive_ids: Array[StringName] = []
	var active_ids: Array[StringName] = []
	for offer in offers:
		if offer == null:
			continue
		if offer.category == &"passive":
			passive_ids.append(offer.id)
		elif offer.category == &"active":
			active_ids.append(offer.id)
	_expect(passive_ids.size() >= 18, "Zone 1 vertical slice requires at least 18 passive modules in the current 18+2 content split")
	_expect(active_ids.size() >= 2, "Zone 1 vertical slice requires at least two live active modules in the current 18+2 content split")
	_expect(passive_ids.size() + active_ids.size() >= 20, "GDD vertical-slice module target requires at least 20 modules")
	for required_id in [&"feed_ramp", &"cold_sink", &"impact_brace", &"shock_bus", &"crit_lens", &"blast_baffle", &"compact_cell", &"reload_actuator", &"thermal_buffer", &"servo_booster", &"recoil_compensator", &"rapid_cycler", &"high_voltage_cap", &"critical_amp", &"velocity_coil", &"reinforced_plating", &"inertia_damper", &"chain_relay"]:
		_expect(required_id in passive_ids, "Missing Zone 1 passive module: %s" % String(required_id))
	for required_id in [&"repair_injector", &"overclock_key"]:
		_expect(required_id in active_ids, "Missing Zone 1 active module: %s" % String(required_id))
	var backpack := BackpackState.new()
	var weapon := WeaponController.new()
	_expect(StarterWeaponRuntime.new().apply(weapon, &"service_pistol"), "Module content validation needs a starter weapon")
	var runtime := RunInventoryRuntime.new()
	_expect(runtime.configure(backpack, weapon, [], offers, &"service_pistol"), "Module content inventory should configure")
	var compact := runtime.definition_for(&"compact_cell") as PassiveModuleDefinition
	var plating := runtime.definition_for(&"reinforced_plating") as PassiveModuleDefinition
	var cycler := runtime.definition_for(&"rapid_cycler") as PassiveModuleDefinition
	_expect(compact != null and is_equal_approx(float(compact.stat_modifiers.get("magazine_add", 0.0)), 4.0), "Compact Cell must become a live +4 magazine passive definition")
	_expect(plating != null and plating.stat_modifiers.has("player_damage_taken_mult"), "Reinforced Plating must expose its live defensive modifier")
	_expect(cycler != null and cycler.requires_power and cycler.stat_modifiers.has("fire_rate_mult"), "Rapid Cycler must remain power-gated and affect fire rate")
	runtime.free()
	weapon.free()

func _test_threat_budget() -> void:
	var catalog := Zone1ContentCatalog.new()
	var registry := RoomTemplateRegistry.new()
	var planner := ThreatBudgetPlanner.new()
	catalog.register_into(registry, planner)
	var boss := registry.get_template(&"z1_boss_press")
	var waves := planner.build_waves(boss)
	_expect(waves.size() == 1, "Boss template should create one wave")
	if waves.size() == 1:
		_expect(waves[0].size() == 1, "Boss budget should not spawn duplicate GR-01 prototypes")

func _test_wallet() -> void:
	var wallet := RunWallet.new()
	wallet.add_currency(&"scrap", 50)
	_expect(wallet.get_currency(&"scrap") == 50, "Wallet add_currency failed")
	_expect(wallet.spend(20), "Wallet spend failed")
	_expect(wallet.scrap == 30, "Wallet balance mismatch")

func _test_ui_resources() -> void:
	_expect(load("res://scenes/ui/run_map_panel.tscn") is PackedScene, "Run map UI scene failed to load")
	_expect(load("res://scenes/ui/reward_choice_panel.tscn") is PackedScene, "Reward choice UI scene failed to load")
	_expect(load("res://scenes/ui/run_ui_root.tscn") is PackedScene, "Run UI root scene failed to load")
	var inventory_scene := load("res://scenes/ui/inventory_panel.tscn") as PackedScene
	_expect(inventory_scene != null, "Inventory UI scene failed to load")
	if inventory_scene != null:
		var panel := inventory_scene.instantiate()
		root.add_child(panel)
		var grid := panel.get_node_or_null("Dim/Panel/Margin/Root/Content/Left/Grid")
		_expect(grid != null and grid.get_child_count() == 30, "Inventory UI must build an exact 6x5 grid")
		panel.free()

func _test_save_roundtrip() -> void:
	var generator := RunGraphGenerator.new()
	var graph := generator.generate(12345)
	var state := RunStateController.new()
	var wallet := RunWallet.new()
	wallet.add(37)
	state.reward_selector.set_pool(Zone1RewardCatalog.new().offers())
	var weapon := WeaponController.new()
	var build := WeaponBuild.new()
	build.frame = WeaponFrameCatalog.new().get_frame(&"service_pistol")
	var parts := WeaponPartCatalog.new()
	build.barrel = parts.get_for_category(&"precision_barrel", &"barrel")
	build.magazine = parts.get_for_category(&"extended_mag", &"magazine")
	build.core = parts.get_for_category(&"fire_core", &"core")
	weapon.weapon_build = build
	var equipment_stub := EquipmentStateStub.new()
	_expect(state.start_run(graph, 12345, {"wallet":wallet, "owned_rewards":[], "weapon_controller":weapon, "equipment_runtime":equipment_stub}), "Run state failed to start")
	var service := RunSaveService.new()
	var path := "user://p2_integration_smoke.json"
	_expect(service.save_run(state, wallet, null, null, path), "Run save failed")
	var payload := service.load_payload(path)
	_expect(int(payload.get("version", 0)) == 6, "Run save should use schema v6")
	var weapon_state: Dictionary = payload.get("weapon_state", {})
	_expect(StringName(weapon_state.get("barrel_id", "")) == &"precision_barrel", "Run save should capture equipped barrel")
	_expect(StringName(weapon_state.get("magazine_id", "")) == &"extended_mag", "Run save should capture equipped magazine")
	_expect(StringName(weapon_state.get("core_id", "")) == &"fire_core", "Run save should capture equipped core")
	var equipment_state: Dictionary = payload.get("equipment_state", {})
	_expect(String(equipment_state.get("active_instance_id", "")) == "repair_injector#1", "Run save v6 should capture active equipment identity")
	var restored_state := RunStateController.new()
	restored_state.reward_selector.set_pool(Zone1RewardCatalog.new().offers())
	var restored_wallet := RunWallet.new()
	var restored_equipment_stub := EquipmentStateStub.new()
	var restored_context := {"wallet":restored_wallet, "owned_rewards":[], "equipment_runtime":restored_equipment_stub}
	_expect(service.restore_run(restored_state, restored_wallet, null, null, restored_context, path), "Run restore failed")
	service.apply_runtime_state(restored_state.run_context)
	_expect(restored_state.current_room_id == state.current_room_id, "Restored room mismatch")
	_expect(restored_wallet.scrap == 37, "Restored wallet mismatch")
	_expect(String(restored_equipment_stub.restored.get("active_instance_id", "")) == "repair_injector#1", "Run save v6 should restore active equipment cooldown state")
	service.delete_save(path)
	weapon.free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
