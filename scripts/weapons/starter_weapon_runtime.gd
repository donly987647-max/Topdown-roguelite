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
	if not weapon.apply_frame_build(build):
		return false
	weapon.ammo = weapon.magazine_capacity
	weapon.reserve_ammo = maxi(weapon.reserve_ammo, weapon.starting_reserve_ammo)
	weapon.call("_emit_ammo")
	return true
