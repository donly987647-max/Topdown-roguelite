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
		"explosion_damage_multiplier": float(stats.get("explosion_damage_multiplier", 1.0)),
		"status_id": StringName(stats.get("status_id", StringName())),
		"status_stacks": int(stats.get("status_stacks", 0)),
		"faction": &"player",
		"void_proc_chance": float(stats.get("void_proc_chance", 0.0)),
		"void_health_fraction": float(stats.get("void_health_fraction", 0.08)),
		"absorption_ratio": float(stats.get("absorption_ratio", 0.0)),
		"absorption_cap": float(stats.get("absorption_cap", 30.0)),
		"replication_chance": float(stats.get("replication_chance", 0.0)),
		"replication_damage_multiplier": float(stats.get("replication_damage_multiplier", 0.55)),
		"devour": bool(stats.get("devour", false)),
		"inverse_phase": bool(stats.get("inverse_phase", false)),
		"impact_multiplier": float(stats.get("impact_multiplier", 1.0)),
		"chain_count": int(stats.get("chain_count", 0)),
		"chain_range": float(stats.get("chain_range", 240.0)),
		"ignore_world_collision": bool(stats.get("ignore_world_collision", false)),
		"damage_multiplier": 1.0,
		"speed_multiplier": 1.0,
		"lifetime_multiplier": 1.0,
		"pierce_damage_decay": 0.0,
		"ricochet_damage_multiplier": 1.0,
		"distance_damage_bonus": 0.0,
		"close_damage_multiplier": 1.0,
		"clear_enemy_projectiles": false,
		"projectile_scale": 1.0,
		"split_count": 0,
		"split_damage_multiplier": 0.30,
		"player_recoil": 0.0,
		"resonance": false,
		"unstable_damage_min": 1.0,
		"unstable_damage_max": 1.0,
		"unstable_spread_degrees": 0.0,
		"last_round_explosion": false,
		"last_round_explosion_radius": 190.0,
		"reverse_order_mag": false,
		"compressed_mag": false,
		"regenerative_mag": false,
		"cross_mag": false,
	}
	if build == null:
		return payload
	for effect_id in build.effect_ids():
		_apply_effect(effect_id, payload)
	_apply_barrel_defaults(barrel_id(build), payload)
	_apply_magazine_defaults(magazine_id(build), payload)
	_apply_frame_defaults(frame_id(build), payload)
	return payload

static func pellet_count(build: WeaponBuild, stats: Dictionary) -> int:
	var count := maxi(1, int(stats.get("pellet_count", 1)))
	if frame_id(build) == &"breach_shotgun":
		count = maxi(count, 8)
	if barrel_id(build) == &"spread_barrel":
		count += 2
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
	if frame_id(build) == &"breach_shotgun":
		spread = maxf(spread, 18.0)
	match barrel_id(build):
		&"precision_barrel":
			spread *= 0.65
		&"spread_barrel":
			spread = maxf(spread, 22.0)
	return spread

static func frame_id(build: WeaponBuild) -> StringName:
	if build == null or build.frame == null:
		return StringName()
	return build.frame.id

static func barrel_id(build: WeaponBuild) -> StringName:
	if build == null or build.barrel == null:
		return StringName()
	return build.barrel.id

static func magazine_id(build: WeaponBuild) -> StringName:
	if build == null or build.magazine == null:
		return StringName()
	return build.magazine.id

static func core_id(build: WeaponBuild) -> StringName:
	if build == null or build.core == null:
		return StringName()
	return build.core.id

static func _apply_barrel_defaults(id: StringName, payload: Dictionary) -> void:
	match id:
		&"precision_barrel":
			payload["speed_multiplier"] = float(payload["speed_multiplier"]) * 1.15
		&"spread_barrel":
			payload["damage_multiplier"] = float(payload["damage_multiplier"]) * 0.75
		&"piercing_barrel":
			payload["pierce"] = int(payload["pierce"]) + 2
			payload["pierce_damage_decay"] = 0.15
		&"ricochet_barrel":
			payload["ricochet"] = int(payload["ricochet"]) + 2
			payload["ricochet_damage_multiplier"] = 1.20
			payload["speed_multiplier"] = float(payload["speed_multiplier"]) * 0.90
		&"explosive_barrel":
			payload["explosion_radius"] = maxf(float(payload["explosion_radius"]), 105.0)
			payload["damage_multiplier"] = float(payload["damage_multiplier"]) * 0.80
		&"long_range_barrel":
			payload["lifetime_multiplier"] = float(payload["lifetime_multiplier"]) * 1.40
			payload["distance_damage_bonus"] = 0.35
			payload["close_damage_multiplier"] = 0.85
		&"cutting_barrel":
			payload["clear_enemy_projectiles"] = true
			payload["projectile_scale"] = maxf(float(payload["projectile_scale"]), 1.35)
		&"homing_barrel":
			payload["homing"] = maxf(float(payload["homing"]), 2.5)
			payload["speed_multiplier"] = float(payload["speed_multiplier"]) * 0.90
			payload["critical_chance"] = maxf(0.0, float(payload["critical_chance"]) - 0.05)
		&"split_barrel":
			payload["split_count"] = maxi(int(payload["split_count"]), 2)
			payload["split_damage_multiplier"] = 0.30
		&"reverse_thrust_barrel":
			payload["damage_multiplier"] = float(payload["damage_multiplier"]) * 1.20
			payload["player_recoil"] = 150.0
		&"resonance_barrel":
			payload["resonance"] = true
		&"unstable_barrel":
			payload["unstable_damage_min"] = 0.70
			payload["unstable_damage_max"] = 1.60
			payload["unstable_spread_degrees"] = 7.0

static func _apply_magazine_defaults(id: StringName, payload: Dictionary) -> void:
	match id:
		&"explosive_mag":
			payload["last_round_explosion"] = true
			payload["last_round_explosion_radius"] = 190.0
		&"reverse_order_mag":
			payload["reverse_order_mag"] = true
		&"compressed_mag":
			payload["compressed_mag"] = true
			payload["damage_multiplier"] = float(payload["damage_multiplier"]) * 1.70
			payload["projectile_scale"] = maxf(float(payload["projectile_scale"]), 1.35)
		&"regenerative_mag":
			payload["regenerative_mag"] = true
		&"cross_mag":
			payload["cross_mag"] = true

static func _apply_frame_defaults(id: StringName, payload: Dictionary) -> void:
	match id:
		&"shrapnel_launcher":
			payload["explosion_radius"] = maxf(float(payload["explosion_radius"]), 145.0)
			payload["explosion_damage_multiplier"] = maxf(float(payload["explosion_damage_multiplier"]), 2.25)
			payload["ignore_world_collision"] = true
		&"arc_projector":
			payload["status_id"] = &"shock"
			payload["status_stacks"] = maxi(1, int(payload["status_stacks"]))
			payload["chain_count"] = maxi(3, int(payload["chain_count"]))
			payload["chain_range"] = maxf(260.0, float(payload["chain_range"]))
		&"sawblade_caster":
			payload["ricochet"] = maxi(3, int(payload["ricochet"]))

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
	if "void" in text or "percent_health_delete" in text:
		payload["void_proc_chance"] = maxf(float(payload["void_proc_chance"]), 0.08)
	if "absorption" in text or "shield_from_damage" in text:
		payload["absorption_ratio"] = maxf(float(payload["absorption_ratio"]), 0.08)
	if "replication" in text or "duplicate" in text or "clone_projectile" in text:
		payload["replication_chance"] = maxf(float(payload["replication_chance"]), 0.18)
	if "devour" in text or "kill_empower" in text:
		payload["devour"] = true
	if "inverse" in text or "phase_return" in text or "return_projectile" in text:
		payload["inverse_phase"] = true
		payload["pierce"] = maxi(int(payload["pierce"]), 1)
	if "impact" in text or "stagger" in text or "knockback" in text:
		payload["impact_multiplier"] = maxf(float(payload["impact_multiplier"]), 1.35)
	if "photon" in text:
		payload["critical_chance"] = maxf(float(payload["critical_chance"]), 0.12)
	if "fire" in text or "burn" in text or "flame" in text:
		_set_status(payload, &"burn", 1)
	elif "cold" in text or "frost" in text or "ice" in text or "chill" in text:
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
