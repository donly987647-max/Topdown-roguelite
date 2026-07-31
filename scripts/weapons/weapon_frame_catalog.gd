class_name WeaponFrameCatalog
extends RefCounted

static func all_frames() -> Array[WeaponFrameData]:
	return [service_pistol(), burst_carbine(), breach_shotgun()]

static func service_pistol() -> WeaponFrameData:
	var data := WeaponFrameData.new()
	data.frame_id = &"service_pistol"
	data.display_name = "SERVICE PISTOL"
	data.fire_mode = WeaponFrameData.FireMode.SEMI
	data.base_damage = 18.0
	data.fire_interval = 0.24
	data.magazine_capacity = 10
	data.reload_time = 1.15
	data.projectile_speed = 1000.0
	data.projectile_lifetime = 1.2
	data.projectile_radius = 3.0
	data.knockback = 45.0
	data.critical_chance = 0.05
	# P2 prototype limits. GDD defines the system but not per-frame values.
	data.max_power = 8
	data.max_weight = 6.0
	data.stability = 0.90
	return data

static func burst_carbine() -> WeaponFrameData:
	var data := WeaponFrameData.new()
	data.frame_id = &"burst_carbine"
	data.display_name = "BURST CARBINE"
	data.fire_mode = WeaponFrameData.FireMode.BURST
	data.base_damage = 11.0
	data.fire_interval = 0.32
	data.magazine_capacity = 24
	data.burst_count = 3
	data.burst_interval = 0.08
	data.burst_recovery = 0.32
	# P2 prototype tuning: reload and projectile values are not fixed in GDD 1.0.
	data.reload_time = 1.45
	data.projectile_speed = 960.0
	data.projectile_lifetime = 1.35
	data.projectile_radius = 3.0
	data.knockback = 32.0
	data.critical_chance = 0.04
	data.spread_degrees = 1.5
	data.max_power = 10
	data.max_weight = 8.0
	data.stability = 0.82
	return data

static func breach_shotgun() -> WeaponFrameData:
	var data := WeaponFrameData.new()
	data.frame_id = &"breach_shotgun"
	data.display_name = "BREACH SHOTGUN"
	data.fire_mode = WeaponFrameData.FireMode.SHOTGUN
	data.base_damage = 7.0
	data.fire_interval = 0.75
	data.magazine_capacity = 5
	data.pellet_count = 8
	# P2 prototype tuning: reload, projectile speed and spread are not fixed in GDD 1.0.
	data.reload_time = 1.80
	data.projectile_speed = 650.0
	data.projectile_lifetime = 0.62
	data.projectile_radius = 3.5
	data.knockback = 110.0
	data.critical_chance = 0.03
	data.spread_degrees = 22.0
	data.max_power = 9
	data.max_weight = 8.5
	data.stability = 0.68
	return data

static func by_id(frame_id: StringName) -> WeaponFrameData:
	for frame in all_frames():
		if frame.frame_id == frame_id:
			return frame
	return service_pistol()
