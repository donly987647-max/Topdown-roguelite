extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	_test_room_template(failures)
	_test_threat_planner(failures)
	_test_run_lifecycle(failures)
	if failures.is_empty():
		print("RUN_LIFECYCLE_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_room_template(failures: Array[String]) -> void:
	var template := RoomTemplateDefinition.new()
	template.id = &"test_room"
	template.zone_id = &"zone_1"
	template.room_type = &"combat"
	template.enemy_spawn_cells = [Vector2i(3, 3), Vector2i(10, 6)]
	template.wave_count = 2
	template.recommended_threat = 8
	if not template.validate_definition().is_empty():
		failures.append("valid combat room template rejected")

func _test_threat_planner(failures: Array[String]) -> void:
	var template := RoomTemplateDefinition.new()
	template.id = &"threat_room"
	template.zone_id = &"zone_1"
	template.room_type = &"combat"
	template.enemy_spawn_cells = [Vector2i(2, 2)]
	template.wave_count = 2
	template.recommended_threat = 8
	template.allowed_enemy_tags = PackedStringArray(["basic"])
	var planner := ThreatBudgetPlanner.new()
	planner.register_enemy(&"grunt", 2, PackedStringArray(["basic"]))
	planner.register_enemy(&"heavy", 4, PackedStringArray(["basic", "armored"]))
	var waves := planner.build_waves(template)
	if waves.size() != 2:
		failures.append("threat planner did not create configured wave count")
	var spawned := 0
	for wave in waves:
		spawned += wave.size()
	if spawned <= 0:
		failures.append("threat planner produced no enemies")

func _test_run_lifecycle(failures: Array[String]) -> void:
	var generator := RunGraphGenerator.new()
	generator.main_depth = 3
	var graph := generator.generate(12345)
	var validation := generator.validate(graph)
	if not bool(validation.get("valid", false)):
		failures.append("generated run graph is invalid")
		return
	var selector := RewardSelector.new()
	for i in range(5):
		var tags := ["fire"] if i == 0 else ["new_direction_%d" % i]
		selector.add_offer(RewardOffer.new(StringName("reward_%d" % i), &"item", &"common", {"tags": tags}, 1.0))
	var controller := RunStateController.new()
	controller.reward_selector = selector
	controller.set_build_tags(PackedStringArray(["fire"]))
	controller.run_context = {"owned_rewards": []}
	if not controller.start_run(graph, 12345, controller.run_context):
		failures.append("run state failed to start")
		return
	if not controller.clear_current_room(true):
		failures.append("run state failed to clear start room")
	if controller.active_reward_choices.size() != 3:
		failures.append("major reward did not produce three choices")
	if not controller.claim_reward(0):
		failures.append("reward claim/grant failed")
	var routes := controller.available_routes()
	if routes.is_empty():
		failures.append("no next route after reward")
	elif not controller.enter_room(routes[0]):
		failures.append("failed to enter allowed next room")
	var saved := controller.serialize()
	var restored := RunStateController.new()
	restored.reward_selector = selector
	if not restored.restore(saved, graph, {"owned_rewards": []}):
		failures.append("run state restore failed")
	elif restored.current_room_id != controller.current_room_id:
		failures.append("restored current room mismatch")
