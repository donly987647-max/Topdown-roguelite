class_name DevourRoomRuntime
extends Node

var weapon: WeaponController
var room_runtime: RoomSceneRuntime
var _persistent_room_bonus := false

func _ready() -> void:
	add_to_group("room_lifecycle_listener")
	set_process(true)

func configure(controller: WeaponController, runtime: RoomSceneRuntime) -> void:
	weapon = controller
	room_runtime = runtime
	if room_runtime != null and not room_runtime.enemy_spawned.is_connected(_on_enemy_spawned):
		room_runtime.enemy_spawned.connect(_on_enemy_spawned)

func on_room_entered(_room_id: StringName, _room_type: StringName) -> void:
	_persistent_room_bonus = false

func on_room_cleared(_room_id: StringName) -> void:
	_persistent_room_bonus = false

func _process(_delta: float) -> void:
	if not _persistent_room_bonus or weapon == null or not is_instance_valid(weapon):
		return
	if not _weapon_has_devour():
		return
	weapon.set("_devour_multiplier", maxf(float(weapon.get("_devour_multiplier")), 1.35))

func _on_enemy_spawned(enemy: Node, enemy_id: StringName, _wave_index: int) -> void:
	if enemy == null:
		return
	var elite := enemy.is_in_group("elite") or bool(enemy.get_meta("elite", false)) or String(enemy_id).contains("elite")
	if not elite:
		return
	enemy.tree_exiting.connect(func(): _on_elite_removed(enemy), CONNECT_ONE_SHOT)

func _on_elite_removed(enemy: Node) -> void:
	if weapon == null or not _weapon_has_devour():
		return
	var health = enemy.get("health") if is_instance_valid(enemy) else null
	if health is float or health is int:
		if float(health) > 0.0:
			return
	_persistent_room_bonus = true
	weapon.set("_devour_multiplier", maxf(float(weapon.get("_devour_multiplier")), 1.35))

func _weapon_has_devour() -> bool:
	if weapon == null or weapon.weapon_build == null:
		return false
	var payload := WeaponEffectResolver.shot_payload(weapon.weapon_build, weapon.get("_build_stats"))
	return bool(payload.get("devour", false))
