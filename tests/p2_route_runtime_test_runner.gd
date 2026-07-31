extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node2D.new()
	world.name = "P2RouteRuntimeWorld"
	root.add_child(world)
	current_scene = world

	var route := PrototypeRouteRun.new(1234)
	var first_profile := route.start()
	var first_room := TestCombatRoom.new()
	first_room.configure(first_profile)
	world.add_child(first_room)
	await process_frame

	var carried_player := first_room.player
	_expect(carried_player != null, "First route room must spawn a player")
	if carried_player == null:
		_finish(world)
		return

	var custom_parts: Array[WeaponPartData] = [
		WeaponPartCatalog.ricochet_barrel(),
		WeaponPartCatalog.lightweight_magazine(),
		WeaponPartCatalog.impact_core()
	]
	carried_player.weapon.equip_parts(custom_parts)
	carried_player.weapon.current_ammo = 4
	var original_weapon := carried_player.weapon
	var original_part_ids: PackedStringArray = original_weapon.get_build_snapshot().get("part_ids", PackedStringArray())

	var second_profile := route.choose_next(&"maintenance_lane")
	var second_room := TestCombatRoom.new()
	second_room.configure(second_profile, carried_player)
	world.add_child(second_room)
	await process_frame

	_expect(second_room.player == carried_player, "Room transition must preserve the same player instance")
	_expect(carried_player.get_parent() == second_room, "Carried player must be reparented into the next room")
	_expect(carried_player.weapon == original_weapon, "Room transition must preserve the weapon runtime instance")
	_expect(carried_player.weapon.current_ammo == 4, "Room transition must preserve current ammunition")
	var next_part_ids: PackedStringArray = carried_player.weapon.get_build_snapshot().get("part_ids", PackedStringArray())
	_expect(next_part_ids == original_part_ids, "Room transition must preserve assembled weapon parts")
	_expect(StringName(second_room.get_route_snapshot().get("room_id", &"")) == &"maintenance_lane", "Next room must expose the selected route profile")
	_expect(second_room.route_room.enemy_count == 3, "Safe route profile must configure its enemy count")

	_finish(world)

func _finish(world: Node) -> void:
	world.queue_free()
	await process_frame
	if failures.is_empty():
		print("[P2 ROUTE RUNTIME TEST] PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("[P2 ROUTE RUNTIME TEST] %s" % failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
