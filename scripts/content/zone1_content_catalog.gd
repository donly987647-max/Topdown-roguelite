class_name Zone1ContentCatalog
extends RefCounted

const ZONE_ID := &"zone_1"
const MELEE_SCENE := "res://scenes/enemies/zone1_melee.tscn"
const RANGED_SCENE := "res://scenes/enemies/zone1_ranged.tscn"

func enemy_profiles() -> Array[EnemySpawnProfile]:
	return [
		_enemy(&"scrap_runner", "Scrap Runner", 1, ["melee", "biological"], MELEE_SCENE, false, {"max_health":45.0,"move_speed":185.0,"contact_damage":10.0,"biological":true,"mechanical":false}),
		_enemy(&"line_guard", "Line Guard", 2, ["melee", "mechanical"], MELEE_SCENE, false, {"max_health":78.0,"move_speed":145.0,"contact_damage":14.0,"biological":false,"mechanical":true}),
		_enemy(&"bolt_spitter", "Bolt Spitter", 2, ["ranged", "mechanical"], RANGED_SCENE, false, {"max_health":52.0,"move_speed":130.0,"fire_interval":1.25,"projectile_damage":10.0,"biological":false,"mechanical":true}),
		_enemy(&"fork_drone", "Fork Drone", 3, ["ranged", "flying", "mechanical"], RANGED_SCENE, false, {"max_health":44.0,"move_speed":175.0,"preferred_distance":480.0,"retreat_distance":300.0,"fire_interval":0.92,"projectile_damage":9.0,"biological":false,"mechanical":true}),
		_enemy(&"crusher_brute", "Crusher Brute", 4, ["melee", "heavy", "mechanical"], MELEE_SCENE, false, {"max_health":155.0,"move_speed":92.0,"contact_damage":22.0,"attack_cooldown":1.05,"biological":false,"mechanical":true}),
		_enemy(&"elite_line_guard", "Elite Line Guard", 6, ["elite", "melee", "mechanical"], MELEE_SCENE, true, {"max_health":190.0,"move_speed":158.0,"contact_damage":20.0,"attack_cooldown":0.68,"biological":false,"mechanical":true}),
	]

func room_templates() -> Array[RoomTemplateDefinition]:
	return [
		_room(&"z1_line_a", &"combat", Vector2i(26,16), 7, 1, [Vector2i(6,5),Vector2i(19,10)], ["melee","ranged"], [Vector2i(12,5),Vector2i(12,6),Vector2i(12,9),Vector2i(12,10)], []),
		_room(&"z1_line_b", &"combat", Vector2i(30,18), 9, 2, [Vector2i(7,5),Vector2i(22,12)], ["mechanical"], [Vector2i(10,5),Vector2i(10,6),Vector2i(19,11),Vector2i(19,12)], [Vector2i(14,8),Vector2i(15,8),Vector2i(14,9),Vector2i(15,9)]),
		_room(&"z1_sorter", &"combat", Vector2i(28,18), 10, 2, [Vector2i(8,5),Vector2i(20,12)], ["melee","ranged"], [Vector2i(9,8),Vector2i(10,8),Vector2i(17,9),Vector2i(18,9),Vector2i(13,5),Vector2i(14,12)], []),
		_room(&"z1_press_lane", &"combat", Vector2i(32,18), 12, 3, [Vector2i(8,4),Vector2i(24,13)], ["mechanical"], [Vector2i(12,4),Vector2i(12,5),Vector2i(12,12),Vector2i(12,13),Vector2i(20,4),Vector2i(20,5),Vector2i(20,12),Vector2i(20,13)], [Vector2i(15,8),Vector2i(16,8),Vector2i(17,8),Vector2i(15,9),Vector2i(16,9),Vector2i(17,9)]),
		_room(&"z1_elite_press", &"elite", Vector2i(30,20), 15, 2, [Vector2i(15,6),Vector2i(15,14)], ["elite","heavy"], [Vector2i(9,7),Vector2i(9,12),Vector2i(20,7),Vector2i(20,12)], [Vector2i(14,9),Vector2i(15,9),Vector2i(14,10),Vector2i(15,10)]),
		_room(&"z1_shop_bay", &"shop", Vector2i(24,14), 0, 1, [], [], [Vector2i(10,5),Vector2i(10,6),Vector2i(13,5),Vector2i(13,6)], []),
		_room(&"z1_crafting_bay", &"crafting", Vector2i(24,14), 0, 1, [], [], [Vector2i(8,5),Vector2i(8,6),Vector2i(15,5),Vector2i(15,6)], []),
		_room(&"z1_med_bay", &"medical", Vector2i(22,14), 0, 1, [], [], [Vector2i(10,4),Vector2i(10,9)], []),
		_room(&"z1_rest_bay", &"rest", Vector2i(22,14), 0, 1, [], [], [Vector2i(7,6),Vector2i(14,6)], []),
		_room(&"z1_event_scrapyard", &"event", Vector2i(26,16), 0, 1, [], [], [Vector2i(8,6),Vector2i(9,6),Vector2i(16,9),Vector2i(17,9)], [Vector2i(12,7),Vector2i(13,8)]),
	]

func register_into(registry: RoomTemplateRegistry, planner: ThreatBudgetPlanner, spawn_registry: EnemySpawnRegistry = null) -> void:
	if registry != null:
		for room in room_templates(): registry.register(room)
	for profile in enemy_profiles():
		if planner != null: planner.register_enemy(profile.id, profile.threat_cost, profile.tags)
		if spawn_registry != null: spawn_registry.register_profile(profile)

func _enemy(id: StringName, title: String, cost: int, tags: Array, scene_path: String, elite: bool, overrides: Dictionary) -> EnemySpawnProfile:
	var p := EnemySpawnProfile.new()
	p.id=id; p.display_name=title; p.threat_cost=cost; p.tags=PackedStringArray(tags); p.scene_path=scene_path; p.elite=elite; p.stat_overrides=overrides
	return p

func _room(id: StringName, type: StringName, size: Vector2i, threat: int, waves: int, spawns: Array[Vector2i], tags: Array, obstacles: Array[Vector2i], hazards: Array[Vector2i]) -> RoomTemplateDefinition:
	var r := RoomTemplateDefinition.new()
	r.id=id; r.zone_id=ZONE_ID; r.room_type=type; r.tile_size=size; r.camera_bounds=Rect2i(Vector2i.ZERO,size)
	r.entrance_cells=[Vector2i(1,size.y/2)]; r.exit_cells=[Vector2i(size.x-2,size.y/2)]
	r.enemy_spawn_cells=spawns; r.recommended_threat=threat; r.wave_count=waves; r.allowed_enemy_tags=PackedStringArray(tags)
	r.obstacle_cells=obstacles; r.hazard_cells=hazards
	r.environment_tags=PackedStringArray(["assembly_line"])
	return r
