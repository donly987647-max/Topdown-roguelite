extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world
	var wielder := Node2D.new()
	world.add_child(wielder)
	var weapon := PrototypeWeapon.new()
	wielder.add_child(weapon)
	weapon.setup(wielder, WeaponFrameCatalog.service_pistol())
	var custom_parts: Array[WeaponPartData] = [
		WeaponPartCatalog.ricochet_barrel(),
		WeaponPartCatalog.lightweight_magazine(),
		WeaponPartCatalog.impact_core()
	]
	weapon.equip_parts(custom_parts)
	weapon.equip_frame(WeaponFrameCatalog.burst_carbine())
	weapon.equip_frame(WeaponFrameCatalog.service_pistol())
	var restored_ids := _part_ids(weapon.equipped_parts)
	_expect(restored_ids.has("ricochet_barrel"), "Pistol barrel must persist across frame switching")
	_expect(restored_ids.has("lightweight_magazine"), "Pistol magazine must persist across frame switching")
	_expect(restored_ids.has("impact_core"), "Pistol core must persist across frame switching")
	_expect(int(weapon.get_snapshot().get("capacity", 0)) == 8, "Restored pistol loadout must recompile capacity")
	var saved_copy := weapon.get_parts_for_frame(&"service_pistol")
	saved_copy.clear()
	_expect(weapon.get_parts_for_frame(&"service_pistol").size() == 3, "Saved loadouts must return defensive copies")
	if failures.is_empty():
		print("[P2 LOADOUT PERSISTENCE TEST] PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("[P2 LOADOUT PERSISTENCE TEST] %s" % failure)
		quit(1)

func _part_ids(parts: Array[WeaponPartData]) -> PackedStringArray:
	var ids := PackedStringArray()
	for part in parts:
		if part != null:
			ids.append(String(part.part_id))
	return ids

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
