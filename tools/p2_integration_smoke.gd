extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_zone1_content()
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
	_expect(enemies.size() >= 7, "Zone 1 starter enemy catalog too small")
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
	_expect(state.start_run(graph, 12345, {"wallet":wallet, "owned_rewards":[], "weapon_controller":weapon}), "Run state failed to start")
	var service := RunSaveService.new()
	var path := "user://p2_integration_smoke.json"
	_expect(service.save_run(state, wallet, null, null, path), "Run save failed")
	var payload := service.load_payload(path)
	_expect(int(payload.get("version", 0)) == 5, "Run save should use schema v5")
	var weapon_state: Dictionary = payload.get("weapon_state", {})
	_expect(StringName(weapon_state.get("barrel_id", "")) == &"precision_barrel", "Run save should capture equipped barrel")
	_expect(StringName(weapon_state.get("magazine_id", "")) == &"extended_mag", "Run save should capture equipped magazine")
	_expect(StringName(weapon_state.get("core_id", "")) == &"fire_core", "Run save should capture equipped core")
	var restored_state := RunStateController.new()
	restored_state.reward_selector.set_pool(Zone1RewardCatalog.new().offers())
	var restored_wallet := RunWallet.new()
	_expect(service.restore_run(restored_state, restored_wallet, null, null, {"wallet":restored_wallet, "owned_rewards":[]}, path), "Run restore failed")
	_expect(restored_state.current_room_id == state.current_room_id, "Restored room mismatch")
	_expect(restored_wallet.scrap == 37, "Restored wallet mismatch")
	service.delete_save(path)
	weapon.free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
