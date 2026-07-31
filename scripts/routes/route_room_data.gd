class_name RouteRoomData
extends Resource

enum RoomType { COMBAT, ELITE, BOSS_GATE }

var room_id: StringName = &""
var stage_index := 0
var room_type: RoomType = RoomType.COMBAT
var path_kind: StringName = &"neutral"
var display_name := ""
var description := ""
var enemy_count := 3
var enemy_health_multiplier := 1.0
var enemy_damage_multiplier := 1.0
var hazard_level := 0
var reward_tier := 0

func duplicate_room() -> RouteRoomData:
	var result := RouteRoomData.new()
	result.room_id = room_id
	result.stage_index = stage_index
	result.room_type = room_type
	result.path_kind = path_kind
	result.display_name = display_name
	result.description = description
	result.enemy_count = enemy_count
	result.enemy_health_multiplier = enemy_health_multiplier
	result.enemy_damage_multiplier = enemy_damage_multiplier
	result.hazard_level = hazard_level
	result.reward_tier = reward_tier
	return result

func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if room_id == &"":
		errors.append("room_id is required")
	if stage_index < 0 or stage_index >= 8:
		errors.append("stage_index must be between 0 and 7")
	if display_name.is_empty():
		errors.append("display_name is required")
	if enemy_count < 1:
		errors.append("enemy_count must be positive")
	if enemy_health_multiplier <= 0.0 or enemy_damage_multiplier <= 0.0:
		errors.append("enemy multipliers must be positive")
	return errors

func is_dangerous() -> bool:
	return path_kind == &"danger" or room_type != RoomType.COMBAT

func type_label() -> String:
	match room_type:
		RoomType.ELITE:
			return "ELITE"
		RoomType.BOSS_GATE:
			return "BOSS GATE"
	return "COMBAT"

func path_label() -> String:
	match path_kind:
		&"safe":
			return "SAFE"
		&"danger":
			return "DANGER"
	return "MAIN"

func get_snapshot() -> Dictionary:
	return {
		"room_id": room_id,
		"stage_index": stage_index,
		"room_number": stage_index + 1,
		"room_type": room_type,
		"type_label": type_label(),
		"path_kind": path_kind,
		"path_label": path_label(),
		"display_name": display_name,
		"description": description,
		"enemy_count": enemy_count,
		"enemy_health_multiplier": enemy_health_multiplier,
		"enemy_damage_multiplier": enemy_damage_multiplier,
		"hazard_level": hazard_level,
		"reward_tier": reward_tier
	}
