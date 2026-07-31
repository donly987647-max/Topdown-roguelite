class_name WeaponPartCatalog
extends RefCounted

static func all_parts() -> Array[WeaponPartData]:
	return [
		precision_barrel(), spread_barrel(), piercing_barrel(), ricochet_barrel(),
		extended_magazine(), lightweight_magazine(), compressed_magazine(), reverse_magazine(),
		impact_core(), photon_core(), clone_core(), flame_core()
	]

static func precision_barrel() -> WeaponPartData:
	return _part(
		&"precision_barrel", "PRECISION BARREL", WeaponPartData.Slot.BARREL, 2, 1.5,
		{"spread_degrees": 0.65, "projectile_speed": 1.15, "fire_interval": 1.08},
		{}, {}, PackedStringArray(["precision", "ballistic"])
	)

static func spread_barrel() -> WeaponPartData:
	return _part(
		&"spread_barrel", "SPREAD BARREL", WeaponPartData.Slot.BARREL, 3, 2.1,
		{"damage": 0.75},
		{"pellet_count": 2.0, "spread_degrees": 12.0},
		{}, PackedStringArray(["spread", "multishot"])
	)

static func piercing_barrel() -> WeaponPartData:
	return _part(
		&"piercing_barrel", "PIERCING BARREL", WeaponPartData.Slot.BARREL, 3, 2.4,
		{}, {"pierce_count": 2.0},
		{"pierce_damage_decay": 0.15}, PackedStringArray(["pierce", "ballistic"])
	)

static func ricochet_barrel() -> WeaponPartData:
	return _part(
		&"ricochet_barrel", "RICOCHET BARREL", WeaponPartData.Slot.BARREL, 3, 2.2,
		{"projectile_speed": 0.90}, {"ricochet_count": 2.0},
		{"ricochet_damage_multiplier": 1.20}, PackedStringArray(["ricochet", "terrain"])
	)

static func extended_magazine() -> WeaponPartData:
	return _part(
		&"extended_magazine", "EXTENDED MAGAZINE", WeaponPartData.Slot.MAGAZINE, 1, 2.6,
		{"magazine_capacity": 1.60, "reload_time": 1.25},
		{}, {}, PackedStringArray(["capacity", "sustain"])
	)

static func lightweight_magazine() -> WeaponPartData:
	return _part(
		&"lightweight_magazine", "LIGHTWEIGHT MAGAZINE", WeaponPartData.Slot.MAGAZINE, 1, 0.9,
		{"magazine_capacity": 0.75, "reload_time": 0.65},
		{}, {"swap_speed_multiplier": 1.20}, PackedStringArray(["reload", "handling"])
	)

static func compressed_magazine() -> WeaponPartData:
	return _part(
		&"compressed_magazine", "COMPRESSED MAGAZINE", WeaponPartData.Slot.MAGAZINE, 4, 2.5,
		{"damage": 1.70, "projectile_radius": 1.30},
		{}, {"ammo_cost": 2}, PackedStringArray(["heavy_ammo", "burst_damage"])
	)

static func reverse_magazine() -> WeaponPartData:
	return _part(
		&"reverse_magazine", "REVERSE MAGAZINE", WeaponPartData.Slot.MAGAZINE, 2, 1.7,
		{}, {}, {"reverse_round_damage_decay": 0.03},
		PackedStringArray(["first_shot", "reload"])
	)

static func impact_core() -> WeaponPartData:
	return _part(
		&"impact_core", "IMPACT CORE", WeaponPartData.Slot.CORE, 3, 2.0,
		{"knockback": 1.75, "projectile_radius": 1.10},
		{}, {}, PackedStringArray(["impact", "stagger"])
	)

static func photon_core() -> WeaponPartData:
	return _part(
		&"photon_core", "PHOTON CORE", WeaponPartData.Slot.CORE, 4, 1.4,
		{"projectile_speed": 1.20, "damage": 0.92},
		{"critical_chance": 0.05}, {}, PackedStringArray(["critical", "velocity"])
	)

static func clone_core() -> WeaponPartData:
	return _part(
		&"clone_core", "CLONE CORE", WeaponPartData.Slot.CORE, 5, 2.2,
		{}, {}, {"clone_chance": 0.18, "clone_damage_multiplier": 0.55},
		PackedStringArray(["clone", "multishot"])
	)

static func flame_core() -> WeaponPartData:
	return _part(
		&"flame_core", "FLAME CORE", WeaponPartData.Slot.CORE, 3, 1.8,
		{}, {"status_buildup": 25.0}, {"status_type": &"burn"},
		PackedStringArray(["burn", "elemental"])
	)

static func by_id(part_id: StringName) -> WeaponPartData:
	for part in all_parts():
		if part.part_id == part_id:
			return part
	return null

static func prototype_loadout_for(frame_id: StringName) -> Array[WeaponPartData]:
	match frame_id:
		&"burst_carbine":
			return [piercing_barrel(), extended_magazine(), flame_core()]
		&"breach_shotgun":
			return [spread_barrel(), reverse_magazine(), impact_core()]
		_:
			return [precision_barrel(), lightweight_magazine(), photon_core()]

static func _part(
	part_id: StringName,
	display_name: String,
	slot: WeaponPartData.Slot,
	power_cost: int,
	weight: float,
	stat_multipliers: Dictionary,
	stat_additions: Dictionary,
	effects: Dictionary,
	tags: PackedStringArray
) -> WeaponPartData:
	var data := WeaponPartData.new()
	data.part_id = part_id
	data.display_name = display_name
	data.slot = slot
	data.power_cost = power_cost
	data.weight = weight
	data.stat_multipliers = stat_multipliers
	data.stat_additions = stat_additions
	data.effects = effects
	data.tags = tags
	return data
