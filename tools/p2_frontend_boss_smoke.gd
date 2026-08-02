extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_test_character_catalog()
	_test_frontend_resources()
	_test_gamepad_actions()
	_test_reward_focus_tracking()
	_test_zone1_room_resources()
	_test_gr01_contract()
	_test_noncombat_reward_flow()
	_test_boss_reward_settlement()
	_test_rex_debt_wallet()
	if failures.is_empty():
		print("P2_FRONTEND_BOSS_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_character_catalog() -> void:
	var catalog := CharacterCatalog.new()
	var all := catalog.all()
	_expect(all.size() == 5, "Character catalog must contain 4 base + 1 secret")
	_expect(catalog.selectable().size() == 4, "Secret character must stay locked by default")
	var mara := catalog.get_by_id(&"mara")
	var kane := catalog.get_by_id(&"kane")
	var nova := catalog.get_by_id(&"nova")
	var rex := catalog.get_by_id(&"rex")
	_expect(mara != null and mara.starting_frame_id == &"service_pistol", "Mara starter frame mismatch")
	_expect(kane != null and kane.starting_frame_id == &"burst_carbine", "Kane starter frame mismatch")
	_expect(nova != null and nova.starting_frame_id == &"arc_projector", "Nova starter frame mismatch")
	_expect(rex != null and rex.starting_frame_id == &"sawblade_caster", "Rex starter frame mismatch")
	_expect(mara != null and mara.starting_guard == 1, "Mara must start with one guard plate")
	_expect(rex != null and rex.starting_scrap > 0, "Rex must start with additional scrap")

func _test_frontend_resources() -> void:
	for path in [
		"res://scenes/main/RunMain.tscn",
		"res://scenes/ui/main_menu_panel.tscn",
		"res://scenes/ui/character_select_panel.tscn",
		"res://scenes/ui/run_result_panel.tscn",
		"res://scenes/ui/run_ui_root.tscn",
		"res://scenes/ui/combat_hud.tscn",
		"res://scenes/ui/facility_panel.tscn",
		"res://scenes/ui/inventory_panel.tscn",
	]:
		_expect(load(path) is PackedScene, "Failed to load frontend resource: %s" % path)

func _test_gamepad_actions() -> void:
	GameInputSetup.configure()
	for action in [&"aim_left", &"aim_right", &"aim_up", &"aim_down", &"character_active", &"equipment_active", &"toggle_map", &"toggle_inventory", &"ui_accept", &"ui_cancel"]:
		_expect(InputMap.has_action(action), "Missing gamepad/UI input action: %s" % String(action))
	var has_joy_fire := false
	for event in InputMap.action_get_events(&"fire"):
		if event is InputEventJoypadMotion:
			has_joy_fire = true
	_expect(has_joy_fire, "Fire action needs a joypad trigger binding")

func _test_reward_focus_tracking() -> void:
	var offers := Zone1RewardCatalog.new().offers()
	_expect(offers.size() >= 3, "Reward catalog needs at least three offers for focus testing")
	if offers.size() < 3:
		return
	var panel := RewardChoicePanel.new()
	root.add_child(panel)
	var choices: Array[RewardOffer] = [offers[0], offers[1], offers[2]]
	panel.present(choices)
	panel.focus_choice(2)
	_expect(panel.focused_index() == 2, "Reward panel must retain the explicitly focused card index")
	panel.clear()
	panel.queue_free()

func _test_zone1_room_resources() -> void:
	var catalog := Zone1ContentCatalog.new()
	for template in catalog.room_templates():
		_expect(template.has_scene(), "Zone 1 template missing scene_path: %s" % String(template.id))
		_expect(load(template.scene_path) is PackedScene, "Zone 1 room scene failed to load: %s" % template.scene_path)
	var boss_profile: EnemySpawnProfile = null
	for profile in catalog.enemy_profiles():
		if profile.id == &"gr01_proto":
			boss_profile = profile
			break
	_expect(boss_profile != null, "GR-01 profile missing")
	if boss_profile != null:
		_expect(load(boss_profile.scene_path) is PackedScene, "GR-01 PackedScene failed to load")

func _test_gr01_contract() -> void:
	var boss := GR01Boss.new()
	boss.max_health = 1000.0
	boss.health = 1000.0
	boss.take_damage(410.0)
	_expect(boss.phase == 2, "GR-01 should enter phase 2 at <=60% HP")
	boss.take_damage(350.0)
	_expect(boss.phase == 3, "GR-01 should enter phase 3 at <=25% HP")
	boss.core_exposed = true
	var before := boss.health
	boss.take_damage(10.0)
	_expect(before - boss.health > 10.0, "GR-01 exposed core should amplify damage")
	boss.free()

func _test_noncombat_reward_flow() -> void:
	var graph := RunGraph.new()
	var start := RoomNodeDefinition.new()
	start.id = &"start"
	start.room_type = &"start"
	var shop := RoomNodeDefinition.new()
	shop.id = &"shop"
	shop.room_type = &"shop"
	var boss := RoomNodeDefinition.new()
	boss.id = &"boss"
	boss.room_type = &"boss"
	graph.add_node(start)
	graph.add_node(shop)
	graph.add_node(boss)
	graph.start_id = start.id
	graph.boss_id = boss.id
	graph.connect_rooms(start.id, shop.id)
	graph.connect_rooms(shop.id, boss.id)
	var state := RunStateController.new()
	state.reward_selector.set_pool(Zone1RewardCatalog.new().offers())
	_expect(state.start_run(graph, 1, {}), "Synthetic run failed to start")
	_expect(state.enter_room(&"shop"), "Synthetic shop room failed to enter")
	_expect(state.clear_current_room(false), "Shop room failed to clear")
	_expect(state.active_reward_choices.is_empty(), "Facility room must not create generic combat reward")
	_expect(&"boss" in state.available_routes(), "Facility room should expose next route")

func _test_boss_reward_settlement() -> void:
	var graph := RunGraph.new()
	var start := RoomNodeDefinition.new()
	start.id = &"start"
	start.room_type = &"start"
	var boss := RoomNodeDefinition.new()
	boss.id = &"boss"
	boss.room_type = &"boss"
	graph.add_node(start)
	graph.add_node(boss)
	graph.start_id = start.id
	graph.boss_id = boss.id
	graph.connect_rooms(start.id, boss.id)
	var owned: Array = []
	var backpack := BackpackState.new()
	var state := RunStateController.new()
	_expect(state.start_run(graph, 2, {"owned_rewards":owned, "backpack_state":backpack}), "Boss settlement run failed to start")
	_expect(state.enter_room(&"boss"), "Boss settlement room failed to enter")
	_expect(state.clear_current_room(true), "Boss settlement failed to start")
	_expect(state.boss_settlement_pending, "Boss should remain pending until the survival choice is claimed")
	_expect(state.active_reward_choices.size() == 2, "Boss must offer backpack expansion versus max-health choice")
	var has_part := false
	var has_key := false
	for raw in owned:
		if raw is Dictionary and StringName(raw.get("id", "")) == &"gr01_compressor_core": has_part = true
		if raw is Dictionary and StringName(raw.get("id", "")) == &"zone2_access_key": has_key = true
	_expect(has_part, "GR-01 mandatory boss-exclusive part missing")
	_expect(has_key, "GR-01 next-zone key missing")
	_expect(not state.finished, "Run must not finish before boss survival choice")
	_expect(state.claim_reward(0), "Boss survival choice failed to grant")
	_expect(state.finished and not state.boss_settlement_pending, "Run should finish after boss settlement choice")

func _test_rex_debt_wallet() -> void:
	var wallet := RunWallet.new()
	wallet.reset(10)
	wallet.configure_credit(true, 50)
	_expect(wallet.can_afford(45), "Rex credit should extend purchasing power")
	_expect(wallet.spend(45), "Rex debt purchase failed")
	_expect(wallet.scrap == 0 and wallet.debt == 35, "Rex debt balance mismatch")
	wallet.add(20)
	_expect(wallet.debt == 15 and wallet.scrap == 0, "Incoming scrap should repay debt first")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
