extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_frame_catalog_contract()
	_test_part_catalog_contract()
	_test_build_compiler_contract()
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

func _test_frame_catalog_contract() -> void:
	var frames := WeaponFrameCatalog.all_frames()
	_expect(frames.size() == 3, "P2 prototype requires exactly three weapon frames")
	var ids: Dictionary = {}
	for frame in frames:
		_expect(frame.validate_contract().is_empty(), "%s has an invalid data contract" % frame.display_name)
		_expect(not ids.has(frame.frame_id), "Weapon frame IDs must be unique")
		_expect(frame.max_power > 0 and frame.max_weight > 0.0, "%s must define assembly limits" % frame.display_name)
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
	_expect(shotgun.pellet_count == 8, "Breach shotgun must fire eight base pellets")
	_expect(is_equal_approx(shotgun.base_damage, 7.0), "Breach shotgun pellet damage must match GDD")
	_expect(is_equal_approx(shotgun.fire_interval, 0.75), "Breach shotgun interval must match GDD")
	_expect(shotgun.magazine_capacity == 5, "Breach shotgun magazine must match GDD")

func _test_part_catalog_contract() -> void:
	var parts := WeaponPartCatalog.all_parts()
	_expect(parts.size() == 12, "P2 prototype requires exactly twelve weapon parts")
	var ids: Dictionary = {}
	var slot_counts := {WeaponPartData.Slot.BARREL: 0, WeaponPartData.Slot.MAGAZINE: 0, WeaponPartData.Slot.CORE: 0}
	for part in parts:
		_expect(part.validate_contract().is_empty(), "%s has an invalid part contract" % part.display_name)
		_expect(not ids.has(part.part_id), "Weapon part IDs must be unique")
		ids[part.part_id] = true
		slot_counts[part.slot] = int(slot_counts.get(part.slot, 0)) + 1
	_expect(int(slot_counts[WeaponPartData.Slot.BARREL]) == 4, "Prototype requires four barrels")
	_expect(int(slot_counts[WeaponPartData.Slot.MAGAZINE]) == 4, "Prototype requires four magazines")
	_expect(int(slot_counts[WeaponPartData.Slot.CORE]) == 4, "Prototype requires four cores")
	_expect(is_equal_approx(float(WeaponPartCatalog.precision_barrel().stat_multipliers["spread_degrees"]), 0.65), "Precision barrel spread reduction must match GDD")
	_expect(int(WeaponPartCatalog.spread_barrel().stat_additions["pellet_count"]) == 2, "Spread barrel must add two projectiles")
	_expect(int(WeaponPartCatalog.piercing_barrel().stat_additions["pierce_count"]) == 2, "Piercing barrel must add two pierces")
	_expect(int(WeaponPartCatalog.ricochet_barrel().stat_additions["ricochet_count"]) == 2, "Ricochet barrel must add two bounces")
	_expect(is_equal_approx(float(WeaponPartCatalog.extended_magazine().stat_multipliers["magazine_capacity"]), 1.60), "Extended magazine capacity must match GDD")
	_expect(is_equal_approx(float(WeaponPartCatalog.lightweight_magazine().stat_multipliers["reload_time"]), 0.65), "Lightweight magazine reload modifier must match GDD")
	_expect(int(WeaponPartCatalog.compressed_magazine().effects["ammo_cost"]) == 2, "Compressed magazine must consume two rounds")
	_expect(is_equal_approx(float(WeaponPartCatalog.reverse_magazine().effects["reverse_round_damage_decay"]), 0.03), "Reverse magazine decay must match GDD")

func _test_build_compiler_contract() -> void:
	var pistol := WeaponFrameCatalog.service_pistol()
	var precision_build := WeaponBuildCalculator.compile(
		pistol,
		[WeaponPartCatalog.precision_barrel(), WeaponPartCatalog.lightweight_magazine(), WeaponPartCatalog.photon_core()]
	)
	var precision_stats: Dictionary = precision_build["stats"]
	var precision_overload: Dictionary = precision_build["overload"]
	_expect(int(precision_stats["magazine_capacity"]) == 8, "Lightweight prototype pistol must compile to eight rounds")
	_expect(is_equal_approx(float(precision_stats["reload_time"]), 1.15 * 0.65), "Lightweight magazine must reduce reload time")
	_expect(is_equal_approx(float(precision_stats["projectile_speed"]), 1000.0 * 1.15 * 1.20), "Precision and photon speed multipliers must stack")
	_expect(is_equal_approx(float(precision_stats["critical_chance"]), 0.10), "Photon core must add critical chance")
	_expect(not bool(precision_overload["power"]) and not bool(precision_overload["weight"]), "Default pistol build must remain inside both limits")

	var heavy_build := WeaponBuildCalculator.compile(
		pistol,
		[WeaponPartCatalog.ricochet_barrel(), WeaponPartCatalog.compressed_magazine(), WeaponPartCatalog.impact_core()]
	)
	var heavy_stats: Dictionary = heavy_build["stats"]
	var heavy_effects: Dictionary = heavy_build["effects"]
	var heavy_overload: Dictionary = heavy_build["overload"]
	_expect(is_equal_approx(float(heavy_stats["damage"]), 18.0 * 1.70), "Compressed magazine must increase damage by seventy percent")
	_expect(int(heavy_stats["ricochet_count"]) == 2, "Ricochet build must compile two bounces")
	_expect(int(heavy_effects["ammo_cost"]) == 2, "Compressed build must compile double ammunition cost")
	_expect(is_equal_approx(float(heavy_effects["ricochet_damage_multiplier"]), 1.20), "Ricochet damage bonus must match GDD")
	_expect(bool(heavy_overload["power"]), "High-power pistol build must trigger power overload")
	_expect(bool(heavy_overload["weight"]), "Heavy pistol build must trigger weight overload")
	_expect(float(heavy_stats["reload_time"]) > pistol.reload_time, "Power overload must increase reload time")
	_expect(float(heavy_effects["misfire_chance"]) > 0.0, "Power overload must create a low misfire chance")
	_expect(float(heavy_effects["move_speed_multiplier"]) < 1.0, "Weight overload must reduce movement speed")
	_expect(float(heavy_effects["dash_distance_multiplier"]) < 1.0, "Weight overload must reduce dash distance")

	var flame_build := WeaponBuildCalculator.compile(
		WeaponFrameCatalog.burst_carbine(),
		WeaponPartCatalog.prototype_loadout_for(&"burst_carbine")
	)
	_expect(StringName(flame_build["effects"]["status_type"]) == &"burn", "Burst prototype loadout must apply flame status")
	_expect(is_equal_approx(float(flame_build["stats"]["status_buildup"]), 25.0), "Flame core must compile burn buildup")

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
	_expect(weapon.current_ammo == 8, "Default prototype pistol loadout must start with eight rounds")
	_expect(weapon.try_fire(), "Service pistol must fire")
	_expect(weapon.current_ammo == 7, "Service pistol must consume one round")
	_clear_projectiles(world)

	weapon.equip_frame(WeaponFrameCatalog.burst_carbine())
	_expect(weapon.current_ammo == 38, "Extended burst carbine must start with 38 rounds")
	_expect(weapon.try_fire(), "Burst carbine must start a burst")
	weapon._process(0.09)
	weapon._process(0.09)
	_expect(weapon.current_ammo == 35, "Burst carbine must consume three rounds per burst")
	var carbine_projectile := _first_projectile(world)
	_expect(carbine_projectile != null, "Burst carbine must spawn projectiles")
	if carbine_projectile != null:
		_expect(carbine_projectile.data.pierce_count == 2, "Piercing barrel must reach projectile runtime")
		_expect(carbine_projectile.data.status_type == &"burn", "Flame core must reach projectile runtime")
		_expect(is_equal_approx(carbine_projectile.data.status_buildup, 25.0), "Flame buildup must reach projectile runtime")

	_clear_projectiles(world)
	weapon.equip_frame(WeaponFrameCatalog.breach_shotgun())
	var before_projectiles := _count_projectiles(world)
	_expect(weapon.try_fire(), "Breach shotgun must fire")
	var after_projectiles := _count_projectiles(world)
	_expect(after_projectiles - before_projectiles == 10, "Spread-barrel shotgun must spawn ten pellets")
	_expect(weapon.current_ammo == 4, "Breach shotgun must consume one shell")

	_clear_projectiles(world)
	var custom_weapon := PrototypeWeapon.new()
	wielder.add_child(custom_weapon)
	custom_weapon.wielder = wielder
	custom_weapon.equip_frame_with_parts(
		WeaponFrameCatalog.service_pistol(),
		[WeaponPartCatalog.compressed_magazine(), WeaponPartCatalog.impact_core()]
	)
	_expect(custom_weapon.try_fire(), "Compressed pistol build under its power limit must fire")
	_expect(custom_weapon.current_ammo == 8, "Compressed magazine must consume two rounds")
	var compressed_projectile := _first_projectile(world)
	_expect(compressed_projectile != null, "Compressed build must spawn a projectile")
	if compressed_projectile != null:
		_expect(is_equal_approx(compressed_projectile.data.damage, 30.6), "Compressed damage must reach projectile runtime")
		_expect(is_equal_approx(compressed_projectile.data.knockback, 45.0 * 1.75), "Impact knockback must reach projectile runtime")

	_clear_projectiles(world)
	custom_weapon.equip_frame_with_parts(
		WeaponFrameCatalog.service_pistol(),
		[WeaponPartCatalog.ricochet_barrel(), WeaponPartCatalog.lightweight_magazine(), WeaponPartCatalog.impact_core()]
	)
	custom_weapon.current_ammo = int(custom_weapon.get_snapshot()["capacity"])
	_expect(custom_weapon.try_fire(), "Ricochet pistol build under its power limit must fire")
	var ricochet_projectile := _first_projectile(world)
	_expect(ricochet_projectile != null, "Ricochet build must spawn a projectile")
	if ricochet_projectile != null:
		_expect(ricochet_projectile.data.ricochet_count == 2, "Ricochet count must reach projectile runtime")

	weapon.equip_frame(WeaponFrameCatalog.service_pistol())
	_expect(weapon.current_ammo == 7, "Switching frames must preserve assembled pistol ammunition")
	world.queue_free()
	await process_frame

func _count_projectiles(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is CombatProjectile:
			count += 1
	return count

func _first_projectile(parent: Node) -> CombatProjectile:
	for child in parent.get_children():
		if child is CombatProjectile:
			return child as CombatProjectile
	return null

func _clear_projectiles(parent: Node) -> void:
	for child in parent.get_children():
		if child is CombatProjectile:
			child.free()

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
