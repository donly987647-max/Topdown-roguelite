class_name MagazineRuntime
extends Node

var _player: Player
var _weapon: WeaponController
var _reaction_window := 0.0
var _reaction_used := false
var _gamble_free_reload := false
var _gamble_failure := false
var _reserve_before_reload := 0
var _emergency_window_before := Vector2.ZERO
var _dual_half_loaded := false

static func attach_to_player(player: Player) -> MagazineRuntime:
	for child in player.get_children():
		if child is MagazineRuntime:
			return child as MagazineRuntime
	var runtime := MagazineRuntime.new()
	runtime.name = "MagazineRuntime"
	player.add_child(runtime)
	runtime._player = player
	return runtime

func _ready() -> void:
	set_process(true)
	call_deferred("_bind_weapon")
	if _player != null and _player.has_signal("damaged"):
		_player.damaged.connect(_on_player_damaged)

func _process(delta: float) -> void:
	if _weapon == null or not is_instance_valid(_weapon):
		_bind_weapon()
		return
	_reaction_window = maxf(0.0, _reaction_window - delta)
	if _magazine_id() == &"dual_mag":
		_update_dual_mag()

func _bind_weapon() -> void:
	if _player == null:
		_player = get_parent() as Player
	if _player == null:
		return
	_weapon = _find_weapon_controller(_player)
	if _weapon == null:
		return
	if not _weapon.reload_started.is_connected(_on_reload_started):
		_weapon.reload_started.connect(_on_reload_started)
	if not _weapon.reload_finished.is_connected(_on_reload_finished):
		_weapon.reload_finished.connect(_on_reload_finished)
	if not _weapon.reload_cancelled.is_connected(_on_reload_cancelled):
		_weapon.reload_cancelled.connect(_on_reload_cancelled)
	if not _weapon.perfect_reload.is_connected(_on_perfect_reload):
		_weapon.perfect_reload.connect(_on_perfect_reload)
	if _player.has_signal("damaged") and not _player.damaged.is_connected(_on_player_damaged):
		_player.damaged.connect(_on_player_damaged)

func _find_weapon_controller(root: Node) -> WeaponController:
	if root is WeaponController:
		return root as WeaponController
	for child in root.get_children():
		var result := _find_weapon_controller(child)
		if result != null:
			return result
	return null

func _magazine_id() -> StringName:
	if _weapon == null or _weapon.weapon_build == null or _weapon.weapon_build.magazine == null:
		return StringName()
	return _weapon.weapon_build.magazine.id

func _on_player_damaged(_amount: float) -> void:
	if _magazine_id() == &"reactive_mag" and not _reaction_used:
		_reaction_window = 0.75

func _on_reload_started(_duration: float) -> void:
	if _weapon == null:
		return
	_dual_half_loaded = false
	match _magazine_id():
		&"emergency_mag":
			_apply_emergency_reload()
		&"magnetic_mag":
			_collect_nearby_ammo()
		&"reactive_mag":
			if _reaction_window > 0.0 and not _reaction_used:
				_reaction_used = true
				_reaction_window = 0.0
				_weapon.set("_reload_left", 0.0)
				_weapon.call_deferred("_finish_reload")
		&"gamble_mag":
			_prepare_gamble_reload()

func _on_reload_finished() -> void:
	if _weapon == null:
		return
	_restore_emergency_window()
	if _magazine_id() == &"gamble_mag":
		_resolve_gamble_reload()
	if _magazine_id() == &"dual_mag" and not _dual_half_loaded:
		var current_bonus := float(_weapon.get("_perfect_reload_damage_bonus"))
		_weapon.set("_perfect_reload_damage_bonus", maxf(current_bonus, 1.20))

func _on_reload_cancelled() -> void:
	_restore_emergency_window()

func _on_perfect_reload() -> void:
	if _magazine_id() != &"magnetic_mag":
		return
	var removed := 0
	for node in get_tree().get_nodes_in_group("enemy_projectile"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		if _player.global_position.distance_squared_to(node.global_position) > 220.0 * 220.0:
			continue
		node.queue_free()
		removed += 1
		if removed >= 8:
			break
	if removed > 0:
		_player.add_temporary_shield(minf(20.0, float(removed) * 2.0))

func _apply_emergency_reload() -> void:
	if _player == null or _player.max_health <= 0.0:
		return
	if _player.health / _player.max_health > 0.30:
		return
	_weapon.set("_reload_left", float(_weapon.get("_reload_left")) * 0.50)
	_emergency_window_before = Vector2(_weapon.perfect_reload_window_start, _weapon.perfect_reload_window_end)
	_weapon.perfect_reload_window_start = maxf(0.0, _weapon.perfect_reload_window_start - 0.10)
	_weapon.perfect_reload_window_end = minf(1.0, _weapon.perfect_reload_window_end + 0.10)

func _restore_emergency_window() -> void:
	if _emergency_window_before == Vector2.ZERO or _weapon == null:
		return
	_weapon.perfect_reload_window_start = _emergency_window_before.x
	_weapon.perfect_reload_window_end = _emergency_window_before.y
	_emergency_window_before = Vector2.ZERO

func _collect_nearby_ammo() -> void:
	var collected := 0
	for group_name in [&"ammo_pickup", &"ammo"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not (node is Node2D) or not is_instance_valid(node):
				continue
			if _player.global_position.distance_squared_to(node.global_position) > 300.0 * 300.0:
				continue
			if node.has_method("collect"):
				node.call("collect", _player)
			else:
				_weapon.add_reserve_ammo(1)
				node.queue_free()
			collected += 1
			if collected >= 8:
				return

func _prepare_gamble_reload() -> void:
	_reserve_before_reload = _weapon.reserve_ammo
	_gamble_free_reload = randf() < 0.20
	_gamble_failure = not _gamble_free_reload

func _resolve_gamble_reload() -> void:
	if _gamble_free_reload and not _weapon.infinite_reserve_ammo:
		_weapon.reserve_ammo = maxi(_weapon.reserve_ammo, _reserve_before_reload)
	if _gamble_failure:
		var loss := maxi(1, int(ceil(float(_weapon.magazine_capacity) * 0.25)))
		_weapon.ammo = maxi(1, _weapon.ammo - loss)
	_weapon.call("_emit_ammo")
	_gamble_free_reload = false
	_gamble_failure = false

func _update_dual_mag() -> void:
	if not _weapon.is_reloading() or _dual_half_loaded:
		return
	if _weapon.reload_progress() < 0.50:
		return
	if not Input.is_action_just_pressed("fire"):
		return
	var target_ammo := maxi(1, int(ceil(float(_weapon.magazine_capacity) * 0.50)))
	var needed := maxi(0, target_ammo - _weapon.ammo)
	var loaded := needed if _weapon.infinite_reserve_ammo else mini(needed, _weapon.reserve_ammo)
	_weapon.ammo += loaded
	if not _weapon.infinite_reserve_ammo:
		_weapon.reserve_ammo -= loaded
	_dual_half_loaded = true
	_weapon.cancel_reload()
	_weapon.call("_emit_ammo")
	_weapon.call_deferred("try_fire")
