class_name Zone1ContentCatalog
extends RefCounted

const ZONE_ID := &"zone_1"

func enemy_profiles() -> Array[EnemySpawnProfile]:
	return [
		_enemy(&"scrap_runner", "Scrap Runner", 1, ["melee", "biological"]),
		_enemy(&"line_guard", "Line Guard", 2, ["melee", "mechanical"]),
		_enemy(&"bolt_spitter", "Bolt Spitter", 2, ["ranged", "mechanical"]),
		_enemy(&"fork_drone", "Fork Drone", 3, ["ranged", "flying", "mechanical"]),
		_enemy(&"crusher_brute", "Crusher Brute", 4, ["melee", "heavy", "mechanical"]),
		_enemy(&"elite_line_guard", "Elite Line Guard", 6, ["elite", "melee", "mechanical"], true),
	]

func room_templates() -> Array[RoomTemplateDefinition]:
	return [
		_room(&"z1_line_a", &"combat", Vector2i(26,16), 7, 1, [Vector2i(6,5),Vector2i(19,10)], ["melee","ranged"]),
		_room(&"z1_line_b", &"combat", Vector2i(30,18), 9, 2, [Vector2i(7,5),Vector2i(22,12)], ["mechanical"]),
		_room(&"z1_sorter", &"combat", Vector2i(28,18), 10, 2, [Vector2i(8,5),Vector2i(20,12)], ["melee","ranged"]),
		_room(&"z1_press_lane", &"combat", Vector2i(32,18), 12, 3, [Vector2i(8,4),Vector2i(24,13)], ["mechanical"]),
		_room(&"z1_elite_press", &"elite", Vector2i(30,20), 15, 2, [Vector2i(15,6),Vector2i(15,14)], ["elite","heavy"]),
		_room(&"z1_shop_bay", &"shop", Vector2i(24,14), 0, 1, [], []),
		_room(&"z1_med_bay", &"rest", Vector2i(22,14), 0, 1, [], []),
		_room(&"z1_event_scrapyard", &"event", Vector2i(26,16), 0, 1, [], []),
	]

func register_into(registry: RoomTemplateRegistry, planner: ThreatBudgetPlanner) -> void:
	if registry != null:
		for room in room_templates(): registry.register(room)
	if planner != null:
		for profile in enemy_profiles(): planner.register_enemy(profile.id, profile.threat_cost, profile.tags)

func _enemy(id: StringName, title: String, cost: int, tags: PackedStringArray, elite: bool = false) -> EnemySpawnProfile:
	var p := EnemySpawnProfile.new(); p.id=id; p.display_name=title; p.threat_cost=cost; p.tags=tags; p.elite=elite; return p

func _room(id: StringName, type: StringName, size: Vector2i, threat: int, waves: int, spawns: Array[Vector2i], tags: PackedStringArray) -> RoomTemplateDefinition:
	var r := RoomTemplateDefinition.new()
	r.id=id; r.zone_id=ZONE_ID; r.room_type=type; r.tile_size=size; r.camera_bounds=Rect2i(Vector2i.ZERO,size)
	r.entrance_cells=[Vector2i(1,size.y/2)]; r.exit_cells=[Vector2i(size.x-2,size.y/2)]
	r.enemy_spawn_cells=spawns; r.recommended_threat=threat; r.wave_count=waves; r.allowed_enemy_tags=tags
	r.environment_tags=PackedStringArray(["assembly_line"])
	return r
