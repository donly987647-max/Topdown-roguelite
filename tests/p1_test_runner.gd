extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_project_resources()
	_test_movement_constants()
	_test_dash_constants()
	_test_health_order()
	_test_projectile_contract()
	_test_room_contract()
	_test_mobile_contract()
	if failures.is_empty():
		print("[P1 TEST] PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("[P1 TEST] %s" % failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_project_resources() -> void:
	_expect(ResourceLoader.exists("res://scenes/main/Main.tscn"), "Main scene missing")
	_expect(ResourceLoader.exists("res://scripts/player/player_controller.gd"), "Player controller missing")
	_expect(ResourceLoader.exists("res://scripts/enemies/training_gunner.gd"), "Training enemy missing")

func _test_movement_constants() -> void:
	_expect(is_equal_approx(PlayerController.MOVE_SPEED, 260.0), "Move speed must be 260 px/s")
	_expect(is_equal_approx(PlayerController.ACCELERATION_TIME, 0.08), "Acceleration must be 0.08 s")
	_expect(is_equal_approx(PlayerController.DECELERATION_TIME, 0.06), "Deceleration must be 0.06 s")

func _test_dash_constants() -> void:
	_expect(is_equal_approx(PlayerController.DASH_DURATION, 0.52), "Dash duration must be 0.52 s")
	_expect(is_equal_approx(PlayerController.DASH_DISTANCE, 150.0), "Dash distance must be 150 px")
	_expect(PlayerController.DASH_INVULN_START < PlayerController.DASH_INVULN_END, "Dash invulnerability interval invalid")
	_expect(is_equal_approx(PlayerController.DASH_COOLDOWN, 0.35), "Dash cooldown must be 0.35 s")

func _test_health_order() -> void:
	var health := HealthComponent.new()
	health.max_health = 100.0
	health.max_armor_plates = 1
	health.armor_per_plate = 20.0
	root.add_child(health)
	health.temporary_shield = 10.0
	var packet := DamagePacket.new()
	packet.amount = 35.0
	packet.attack_id = &"health-order-test"
	var result := health.apply_damage(packet, true)
	_expect(is_equal_approx(float(result.absorbed), 30.0), "Shield and armor must absorb 30")
	_expect(is_equal_approx(float(result.health_damage), 5.0), "Health must receive 5 overflow damage")
	health.queue_free()

func _test_projectile_contract() -> void:
	var data := ProjectileData.new()
	_expect(_has_property(data, &"damage"), "Projectile damage field missing")
	_expect(_has_property(data, &"pierce_count"), "Projectile pierce field missing")
	_expect(_has_property(data, &"faction"), "Projectile faction field missing")

func _has_property(object: Object, property_name: StringName) -> bool:
	for item in object.get_property_list():
		if StringName(item.get("name", "")) == property_name:
			return true
	return false

func _test_room_contract() -> void:
	_expect(TestCombatRoom.ROOM_RECT.size == Vector2(640.0, 384.0), "Test room must be 20x12 tiles at 32 px")
	_expect(TestCombatRoom.ENEMY_SPAWNS.size() >= 1, "Test room needs enemy spawn")

func _test_mobile_contract() -> void:
	_expect(ResourceLoader.exists("res://scripts/ui/mobile_touch_controls.gd"), "Mobile touch controls missing")
	var input_router := root.get_node_or_null("InputRouter")
	_expect(input_router != null, "InputRouter autoload missing")
	if input_router == null:
		return
	_expect(input_router.has_method("set_mobile_move"), "Mobile move bridge missing")
	_expect(input_router.has_method("set_mobile_aim"), "Mobile aim bridge missing")
	_expect(input_router.has_method("pulse_mobile_dash"), "Mobile dash bridge missing")
	_expect(input_router.has_method("pulse_mobile_reload"), "Mobile reload bridge missing")
