extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_test_room_template_scene_contract()
	_test_exit_gate_contract()
	_test_enemy_registry_missing_contract()
	if failures.is_empty():
		print("ROOM_SCENE_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_room_template_scene_contract() -> void:
	var template := RoomTemplateDefinition.new()
	template.id = &"smoke_room"
	template.zone_id = &"zone_1"
	template.room_type = &"combat"
	template.enemy_spawn_cells = [Vector2i(3, 3)]
	template.scene_path = ""
	_assert(template.validate_definition().is_empty(), "room template should validate with fallback shell")
	_assert(not template.has_scene(), "empty scene path should use generated shell")

func _test_exit_gate_contract() -> void:
	var gate := RoomExitGate.new()
	root.add_child(gate)
	gate.set_locked(true)
	_assert(gate.is_locked(), "exit gate should lock")
	gate.set_target_room(&"next_room")
	_assert(gate.target_room_id == &"next_room", "exit target should be assignable")
	gate.set_locked(false)
	_assert(not gate.is_locked(), "exit gate should unlock")
	gate.queue_free()

func _test_enemy_registry_missing_contract() -> void:
	var registry := EnemySpawnRegistry.new()
	var missing := registry.missing_ids([{"enemy_id": &"chaser"}, {"enemy_id": &"ranged"}])
	_assert(missing.size() == 2, "unregistered enemy ids should be reported")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
