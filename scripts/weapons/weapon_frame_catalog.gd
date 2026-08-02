class_name WeaponFrameCatalog
extends RefCounted

const DATA_PATH := "res://data/weapons/weapon_frames.json"

var _cache: Dictionary = {}

func get_frame(id: StringName) -> WeaponFrameDefinition:
	if _cache.has(id):
		return _cache[id]
	var data := _load_data()
	var raw = data.get(String(id), {})
	if not (raw is Dictionary) or raw.is_empty():
		return null
	var frame := WeaponFrameDefinition.new()
	frame.id = id
	frame.display_name = String(raw.get("name", String(id)))
	frame.weapon_class = StringName(raw.get("class", "unknown"))
	frame.role = String(raw.get("role", ""))
	frame.base_damage = float(raw.get("base_damage", raw.get("pellet_damage", raw.get("direct_damage", raw.get("tick_damage", 10.0)))))
	frame.fire_interval = maxf(0.01, float(raw.get("fire_interval", raw.get("burst_recovery", 0.2))))
	frame.magazine_size = maxi(1, int(raw.get("magazine", 10)))
	frame.reload_time = maxf(0.05, float(raw.get("reload", 1.0)))
	frame.uses_heat = bool(raw.get("uses_heat", false))
	frame.special_rule = StringName(raw.get("special", ""))
	frame.compatibility_tags = _default_tags(frame.weapon_class)
	_cache[id] = frame
	return frame

func _load_data() -> Dictionary:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func _default_tags(weapon_class: StringName) -> PackedStringArray:
	var tags := PackedStringArray(["weapon"])
	var text := String(weapon_class)
	if "pistol" in text or "rifle" in text or "smg" in text or "shotgun" in text or "machine" in text or "sniper" in text:
		tags.append("ballistic")
	if "electric" in text:
		tags.append("electric")
	if "laser" in text:
		tags.append("energy")
	if "summon" in text:
		tags.append("summon")
	return tags
