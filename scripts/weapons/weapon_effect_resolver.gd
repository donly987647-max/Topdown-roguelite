class_name WeaponEffectResolver
extends RefCounted

static func shot_payload(build: WeaponBuild, stats: Dictionary) -> Dictionary:
	var payload := {
		"pierce": int(stats.get("pierce", 0)),
		"ricochet": int(stats.get("ricochet", 0)),
		"homing": float(stats.get("homing", 0.0)),
		"critical_chance": float(stats.get("critical_chance", 0.0)),
		"critical_multiplier": float(stats.get("critical_multiplier", 2.0)),
		"explosion_radius": float(stats.get("explosion_radius", 0.0)),
		"status_id": StringName(stats.get("status_id", StringName())),
		"status_stacks": int(stats.get("status_stacks", 0)),
		"faction": &"player",
	}
	if build == null:
		return payload
	for effect_id in build.effect_ids():
		_apply_effect(effect_id, payload)
	return payload

static func pellet_count(build: WeaponBuild, stats: Dictionary) -> int:
	var count := maxi(1, int(stats.get("pellet_count", 1)))
	if build == null:
		return count
	for effect_id in build.effect_ids():
		var text := String(effect_id).to_lower()
		if "pellet" in text or "shotgun" in text or "scatter" in text:
			count = maxi(count, int(stats.get("pellet_count", 8)))
	return count

static func pellet_spread_degrees(build: WeaponBuild, stats: Dictionary, fallback: float) -> float:
	var spread := float(stats.get("spread", fallback))
	if pellet_count(build, stats) > 1:
		spread = maxf(spread, float(stats.get("pellet_spread", 16.0)))
	return spread

static func _apply_effect(effect_id: StringName, payload: Dictionary) -> void:
	var text := String(effect_id).to_lower()
	if "pierce" in text or "penetr" in text:
		payload["pierce"] = maxi(int(payload["pierce"]), 1)
	if "ricochet" in text or "reflect" in text or "bounce" in text:
		payload["ricochet"] = maxi(int(payload["ricochet"]), 1)
	if "homing" in text or "guided" in text:
		payload["homing"] = maxf(float(payload["homing"]), 2.5)
	if "explosive" in text or "explosion" in text or "blast" in text:
		payload["explosion_radius"] = maxf(float(payload["explosion_radius"]), 120.0)
	if "fire" in text or "burn" in text or "flame" in text:
		_set_status(payload, &"burn", 1)
	elif "cold" in text or "frost" in text or "ice" in text:
		_set_status(payload, &"cold", 1)
	elif "shock" in text or "electric" in text:
		_set_status(payload, &"shock", 1)
	elif "corrosion" in text or "corrosive" in text or "acid" in text:
		_set_status(payload, &"corrosion", 1)
	elif "bleed" in text or "bleeding" in text:
		_set_status(payload, &"bleed", 1)
	elif "confusion" in text or "confuse" in text:
		_set_status(payload, &"confusion", 1)
	elif "vulnerable" in text or "vulnerability" in text:
		_set_status(payload, &"vulnerable", 1)

static func _set_status(payload: Dictionary, id: StringName, stacks: int) -> void:
	payload["status_id"] = id
	payload["status_stacks"] = maxi(int(payload.get("status_stacks", 0)), stacks)
