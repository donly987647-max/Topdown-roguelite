extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_test_character_catalog()
	_test_frontend_resources()
	_test_zone1_room_resources()
	_test_gr01_contract()
	_test_noncombat_reward_flow()
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

func _test_frontend_resources() -> void:
	for path in [
		"res://scenes/main/RunMain.tscn",
		"res://scenes/ui/main_menu_panel.tscn",
		"res://scenes/ui/character_select_panel.tscn",
		"res://scenes/ui/run_result_panel.tscn",
		"res://scenes/ui/run_ui_root.tscn",
	]:
		_expect(load(path) is PackedScene, "Failed to load frontend resource: %s" % path)

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
	var start := RoomNodeDefinition.new(); start.id=&"start"; start.room_type=&"start"
	var shop := RoomNodeDefinition.new(); shop.id=&"shop"; shop.room_type=&"shop"
	var boss := RoomNodeDefinition.new(); boss.id=&"boss"; boss.room_type=&"boss"
	graph.add_node(start); graph.add_node(shop); graph.add_node(boss)
	graph.start_id=start.id; graph.boss_id=boss.id
	graph.connect(start.id,shop.id); graph.connect(shop.id,boss.id)
	var state := RunStateController.new()
	state.reward_selector.set_pool(Zone1RewardCatalog.new().offers())
	_expect(state.start_run(graph, 1, {}), "Synthetic run failed to start")
	_expect(state.enter_room(&"shop"), "Synthetic shop room failed to enter")
	_expect(state.clear_current_room(false), "Shop room failed to clear")
	_expect(state.active_reward_choices.is_empty(), "Facility room must not create generic combat reward")
	_expect(&"boss" in state.available_routes(), "Facility room should expose next route")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
