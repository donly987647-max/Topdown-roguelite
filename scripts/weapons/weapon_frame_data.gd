class_name WeaponFrameData
extends Resource

enum FireMode {
	SEMI,
	BURST,
	SHOTGUN
}

@export var frame_id: StringName = &"service_pistol"
@export var display_name := "SERVICE PISTOL"
@export var fire_mode: FireMode = FireMode.SEMI
@export var base_damage := 18.0
@export var fire_interval := 0.24
@export var magazine_capacity := 10
@export var reload_time := 1.15
@export var projectile_speed := 1000.0
@export var projectile_lifetime := 1.2
@export var projectile_radius := 3.0
@export var knockback := 45.0
@export var critical_chance := 0.05
@export var spread_degrees := 0.0
@export var pellet_count := 1
@export var burst_count := 1
@export var burst_interval := 0.08
@export var burst_recovery := 0.32

func duplicate_frame() -> WeaponFrameData:
	return duplicate(true) as WeaponFrameData

func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if frame_id == &"":
		errors.append("frame_id is empty")
	if display_name.is_empty():
		errors.append("display_name is empty")
	if base_damage <= 0.0:
		errors.append("base_damage must be positive")
	if fire_interval <= 0.0:
		errors.append("fire_interval must be positive")
	if magazine_capacity <= 0:
		errors.append("magazine_capacity must be positive")
	if reload_time <= 0.0:
		errors.append("reload_time must be positive")
	if projectile_speed <= 0.0:
		errors.append("projectile_speed must be positive")
	if pellet_count <= 0:
		errors.append("pellet_count must be positive")
	if fire_mode == FireMode.BURST and burst_count < 2:
		errors.append("burst mode requires at least two shots")
	if fire_mode == FireMode.SHOTGUN and pellet_count < 2:
		errors.append("shotgun mode requires multiple pellets")
	return errors
