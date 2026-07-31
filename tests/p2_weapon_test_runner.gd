extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_catalog_contract()
	await _test_runtime_contract()
	_test_input_contract()
	if failures.is_empty():
		print("[P2 WEAPON TEST] PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("[P2 WEAPON TEST] %s" % failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_catalog_contract() -> void:
	var frames := WeaponFrameCatalog.all_frames()
	_expect(frames.size() == 3, "P2 prototype requires exactly three weapon frames")
	var ids: Dictionary = {}
	for frame in frames:
		_expect(frame.validate_contract().is_empty(), "%s has an invalid data contract" % frame.display_name)
		_expect(not ids.has(frame.frame_id), "Weapon frame IDs must be unique")
		ids[frame.frame_id] = true
	var pistol := WeaponFrameCatalog.service_pistol()
	_expect(pistol.fire_mode == WeaponFrameData.FireMode.SEMI, "Service pistol must be semi-automatic")
	_expect(is_equal_approx(pistol.base_damage, 18.0), "Service pistol damage must match GDD")
	_expect(is_equal_approx(pistol.fire_interval, 0.24), "Service pistol interval must match GDD")
	_expect(pistol.magazine_capacity == 10, "Service pistol magazine must match GDD")
	var carbine := WeaponFrameCatalog.burst_carbine()
	_expect(carbine.fire_mode == WeaponFrameData.FireMode.BURST, "Burst carbine must use burst mode")
	_expect(carbine.burst_count == 3, "Burst carbine must fire three-round bursts")
	_expect(is_equal_approx(carbine.burst_interval, 0.08), "Burst interval must match GDD")
	_expect(is_equal_approx(carbine.burst_recovery, 0.32), "Burst recovery must match GDD")
	_expect(carbine.magazine_capacity == 24, "Burst carbine magazine must match GDD")
	var shotgun := WeaponFrameCatalog.breach_shotgun()
	_expect(shotgun.fire_mode == WeaponFrameData.FireMode.SHOTGUN, "Breach shotgun must use shotgun mode")
	_expect(shotgun.pellet_count == 8, "Breach shotgun must fire eight pellets")
	_expect(is_equal_approx(shotgun.base_damage, 7.0), "Breach shotgun pellet damage must match GDD")
	_expect(is_equal_approx(shotgun.fire_interval, 0.75), "Breach shotgun interval must match GDD")
	_expect(shotgun.magazine_capacity == 5, "Breach shotgun magazine must match GDD")

func _test_runtime_contract() -> void:
	var world := Node2D.new()
	world.name = "P2WeaponTestWorld"
	root.add_child(world)
	current_scene = world
	var wielder := Node2D.new()
	world.add_child(wielder)
	var weapon := PrototypeWeapon.new()
	wielder.add_child(weapon)
	weapon.setup(wielder, WeaponFrameCatalog.service_pistol())
	_expect(weapon.try_fire(), "Service pistol must fire")
	_expect(weapon.current_ammo == 9, "Service pistol must consume one round")

	weapon.equip_frame(WeaponFrameCatalog.burst_carbine())
	_expect(weapon.current_ammo == 24, "Burst carbine must start with 24 rounds")
	_expect(weapon.try_fire(), "Burst carbine must start a burst")
	weapon._process(0.09)
	weapon._process(0.09)
	_expect(weapon.current_ammo == 21, "Burst carbine must consume three rounds per burst")

	weapon.equip_frame(WeaponFrameCatalog.breach_shotgun())
	var before_projectiles := _count_projectiles(world)
	_expect(weapon.try_fire(), "Breach shotgun must fire")
	var after_projectiles := _count_projectiles(world)
	_expect(after_projectiles - before_projectiles == 8, "Breach shotgun must spawn eight pellets")
	_expect(weapon.current_ammo == 4, "Breach shotgun must consume one shell")

	weapon.equip_frame(WeaponFrameCatalog.service_pistol())
	_expect(weapon.current_ammo == 9, "Switching frames must preserve per-frame ammunition")
	world.queue_free()
	await process_frame

func _count_projectiles(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is CombatProjectile:
			count += 1
	return count

func _test_input_contract() -> void:
	var input_router := root.get_node_or_null("InputRouter")
	_expect(input_router != null, "InputRouter autoload missing")
	if input_router == null:
		return
	_expect(InputMap.has_action("weapon_slot_1"), "Weapon slot 1 action missing")
	_expect(InputMap.has_action("weapon_slot_2"), "Weapon slot 2 action missing")
	_expect(InputMap.has_action("weapon_slot_3"), "Weapon slot 3 action missing")
	_expect(InputMap.has_action("weapon_next"), "Weapon-next action missing")
	_expect(input_router.has_method("pulse_mobile_weapon_next"), "Mobile weapon-cycle bridge missing")
