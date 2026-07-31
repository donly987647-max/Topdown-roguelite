class_name PrototypeRouteRun
extends RefCounted

const TOTAL_ROOMS := 8

var stage_index := -1
var current_room: RouteRoomData
var history: Array[RouteRoomData] = []
var _stages: Array = []
var _seed_value := 0

func _init(seed_value := 0) -> void:
	_seed_value = seed_value
	_build_stages()

func start() -> RouteRoomData:
	stage_index = 0
	current_room = (_stages[0][0] as RouteRoomData).duplicate_room()
	history = [current_room.duplicate_room()]
	return current_room.duplicate_room()

func get_next_options() -> Array[RouteRoomData]:
	var result: Array[RouteRoomData] = []
	var next_stage := stage_index + 1
	if next_stage < 0 or next_stage >= _stages.size():
		return result
	for value in _stages[next_stage]:
		if value is RouteRoomData:
			result.append((value as RouteRoomData).duplicate_room())
	return result

func choose_next(room_id: StringName) -> RouteRoomData:
	for option in get_next_options():
		if option.room_id == room_id:
			stage_index += 1
			current_room = option.duplicate_room()
			history.append(current_room.duplicate_room())
			return current_room.duplicate_room()
	return null

func is_complete() -> bool:
	return history.size() >= TOTAL_ROOMS and stage_index >= TOTAL_ROOMS - 1

func get_progress_snapshot() -> Dictionary:
	var visited_ids := PackedStringArray()
	var danger_count := 0
	for room in history:
		visited_ids.append(String(room.room_id))
		if room.is_dangerous():
			danger_count += 1
	return {
		"current_room": current_room.get_snapshot() if current_room != null else {},
		"room_number": history.size(),
		"total_rooms": TOTAL_ROOMS,
		"visited_ids": visited_ids,
		"danger_count": danger_count,
		"complete": is_complete(),
		"seed": _seed_value
	}

func _build_stages() -> void:
	_stages = [
		[_room(&"assembly_entry", 0, RouteRoomData.RoomType.COMBAT, &"neutral", "ASSEMBLY ENTRY", "Initial production-line breach.", 3, 1.00, 1.00, 0, 0)],
		[
			_room(&"maintenance_lane", 1, RouteRoomData.RoomType.COMBAT, &"safe", "MAINTENANCE LANE", "Lower threat with standard salvage.", 3, 1.00, 1.00, 0, 0),
			_room(&"crusher_bypass", 1, RouteRoomData.RoomType.ELITE, &"danger", "CRUSHER BYPASS", "Armored response team near active presses.", 4, 1.25, 1.10, 1, 1)
		],
		[
			_room(&"coolant_gallery", 2, RouteRoomData.RoomType.COMBAT, &"safe", "COOLANT GALLERY", "Open lane with stable footing.", 3, 1.05, 1.00, 0, 0),
			_room(&"live_conveyor", 2, RouteRoomData.RoomType.COMBAT, &"danger", "LIVE CONVEYOR", "Dense opposition and active floor hazards.", 4, 1.10, 1.08, 2, 1)
		],
		[_room(&"sorting_core", 3, RouteRoomData.RoomType.COMBAT, &"neutral", "SORTING CORE", "Central junction with reinforced patrols.", 4, 1.12, 1.05, 1, 1)],
		[
			_room(&"inspection_route", 4, RouteRoomData.RoomType.COMBAT, &"safe", "INSPECTION ROUTE", "Predictable patrol pattern and light hazards.", 4, 1.12, 1.05, 0, 1),
			_room(&"overclocked_cell", 4, RouteRoomData.RoomType.ELITE, &"danger", "OVERCLOCKED CELL", "High-output defenders with boosted durability.", 5, 1.35, 1.15, 1, 2)
		],
		[
			_room(&"supply_transfer", 5, RouteRoomData.RoomType.COMBAT, &"safe", "SUPPLY TRANSFER", "Long sightlines and recoverable cover.", 4, 1.18, 1.08, 0, 1),
			_room(&"slag_channel", 5, RouteRoomData.RoomType.ELITE, &"danger", "SLAG CHANNEL", "Tight arena with severe environmental pressure.", 5, 1.42, 1.18, 2, 2)
		],
		[_room(&"foreman_gate", 6, RouteRoomData.RoomType.ELITE, &"neutral", "FOREMAN GATE", "Mandatory elite checkpoint before the core.", 5, 1.48, 1.20, 1, 2)],
		[_room(&"gr01_antechamber", 7, RouteRoomData.RoomType.BOSS_GATE, &"neutral", "GR-01 ANTECHAMBER", "Prototype boss gate using an overstrength guard formation.", 6, 1.65, 1.25, 1, 3)]
	]

func _room(
	room_id: StringName,
	index: int,
	type: RouteRoomData.RoomType,
	path_kind: StringName,
	display_name: String,
	description: String,
	enemy_count: int,
	health_multiplier: float,
	damage_multiplier: float,
	hazard_level: int,
	reward_tier: int
) -> RouteRoomData:
	var data := RouteRoomData.new()
	data.room_id = room_id
	data.stage_index = index
	data.room_type = type
	data.path_kind = path_kind
	data.display_name = display_name
	data.description = description
	data.enemy_count = enemy_count
	data.enemy_health_multiplier = health_multiplier
	data.enemy_damage_multiplier = damage_multiplier
	data.hazard_level = hazard_level
	data.reward_tier = reward_tier
	return data
