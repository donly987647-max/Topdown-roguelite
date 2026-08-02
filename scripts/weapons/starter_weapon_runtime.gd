class_name StarterWeaponRuntime
extends RefCounted

var catalog := WeaponFrameCatalog.new()

func apply(weapon: WeaponController, frame_id: StringName) -> bool:
	if weapon == null or frame_id == &"":
		return false
	var frame := catalog.get_frame(frame_id)
	if frame == null:
		return false
	var build := WeaponBuild.new()
	build.frame = frame
	var stats := build.computed_stats()
	weapon.weapon_build = build
	weapon.set("_build_stats", stats)
	weapon.damage = float(stats.get("damage", weapon.damage))
	var interval := maxf(0.01, float(stats.get("fire_interval", 1.0 / maxf(weapon.rounds_per_second, 0.01))))
	weapon.rounds_per_second = 1.0 / interval
	weapon.magazine_capacity = maxi(1, int(stats.get("magazine_size", weapon.magazine_capacity)))
	weapon.reload_duration = maxf(0.05, float(stats.get("reload_time", weapon.reload_duration)))
	weapon.uses_heat = bool(stats.get("uses_heat", weapon.uses_heat))
	weapon.ammo = weapon.magazine_capacity
	weapon.reserve_ammo = maxi(weapon.reserve_ammo, weapon.starting_reserve_ammo)
	weapon.call("_reset_frame_state")
	weapon.call("_emit_ammo")
	weapon.build_applied.emit(build)
	return true
