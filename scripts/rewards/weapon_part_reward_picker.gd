class_name WeaponPartRewardPicker
extends RefCounted

static func roll_options(count: int = 3, excluded_ids: PackedStringArray = PackedStringArray()) -> Array[WeaponPartData]:
	var pool: Array[WeaponPartData] = []
	for part in WeaponPartCatalog.all_parts():
		if excluded_ids.has(String(part.part_id)):
			continue
		pool.append(part)
	pool.shuffle()
	var result: Array[WeaponPartData] = []
	for index in mini(maxi(count, 0), pool.size()):
		result.append(pool[index].duplicate_part())
	return result

static func replace_slot(current_parts: Array[WeaponPartData], selected_part: WeaponPartData) -> Array[WeaponPartData]:
	var result: Array[WeaponPartData] = []
	var replaced := false
	for part in current_parts:
		if part == null:
			continue
		if part.slot == selected_part.slot:
			if not replaced:
				result.append(selected_part.duplicate_part())
				replaced = true
			continue
		result.append(part.duplicate_part())
	if not replaced:
		result.append(selected_part.duplicate_part())
	return result

static func equipped_ids(parts: Array[WeaponPartData]) -> PackedStringArray:
	var ids := PackedStringArray()
	for part in parts:
		if part != null:
			ids.append(String(part.part_id))
	return ids
