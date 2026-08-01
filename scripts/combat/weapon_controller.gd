class_name WeaponController
extends Node2D

signal ammo_changed(current: int, capacity: int, reserve: int)
signal reload_started(duration: float)
signal reload_finished
signal reload_cancelled
signal perfect_reload
signal shot_fired
signal heat_changed(current: float, maximum: float)
signal overheated(duration: float)
signal overheat_recovered

@export_category("Projectile")
@export var projectile_scene: PackedScene
@export var damage: float = 20.0
@export var rounds_per_second: float = 6.5
@export var spread_degrees: float = 1.5
@export var projectile_speed: float = 1250.0
@export var automatic: bool = true

@export_category("Ammo / Reload")
@export var magazine_capacity: int = 12
@export var starting_reserve_ammo: int = 120
@export var infinite_reserve_ammo: bool = false
@export var auto_reload_when_empty: bool = true
@export var reload_duration: float = 1.15
@export_range(0.0, 1.0) var perfect_reload_window_start: float = 0.62
@export_range(0.0, 1.0) var perfect_reload_window_end: float = 0.78
@export var perfect_reload_time_reduction: float = 0.25
@export var cancel_reload_on_dash: bool = true

@export_category("Heat")
@export var uses_heat: bool = false
@export var max_heat: float = 100.0
@export var heat_per_shot: float = 10.0
@export var heat_cool_rate: float = 28.0
@export var overheat_lock_duration: float = 1.2

@export_category("Feedback")
@export var muzzle_flash_duration: float = 0.045

var ammo: int
var reserve_ammo: int
var heat := 0.0
var _fire_cooldown := 0.0
var _reload_left := 0.0
var _is_reloading := false
var _overheat_left := 0.0
var _overheated := false

@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_flash: Polygon2D = get_node_or_null("MuzzleFlash") as Polygon2D

func _ready() -> void:
	ammo = magazine_capacity
	reserve_ammo = maxi(0, starting_reserve_ammo)
	_emit_ammo()
	heat_changed.emit(heat, max_heat)
	if muzzle_flash != null:
		muzzle_flash.visible = false

func _process(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	_update_heat(delta)

	if _is_reloading:
		if cancel_reload_on_dash and Input.is_action_just_pressed("dash"):
			cancel_reload()
			return
		if Input.is_action_just_pressed("reload") and _is_in_perfect_reload_window():
			_trigger_perfect_reload()
			return
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()
		return

	if Input.is_action_just_pressed("reload"):
		start_reload()
		return

	var wants_fire := Input.is_action_pressed("fire") if automatic else Input.is_action_just_pressed("fire")
	if wants_fire:
		try_fire()

func try_fire() -> bool:
	if _is_reloading or _fire_cooldown > 0.0 or _overheated:
		return false
	if ammo <= 0:
		if auto_reload_when_empty:
			start_reload()
		return false
	if projectile_scene == null:
		push_warning("WeaponController has no projectile_scene")
		return false

	ammo -= 1
	_fire_cooldown = 1.0 / maxf(rounds_per_second, 0.01)
	if uses_heat:
		heat = minf(max_heat, heat + heat_per_shot)
		heat_changed.emit(heat, max_heat)
		if heat >= max_heat:
			_begin_overheat()
	_emit_ammo()

	var projectile := projectile_scene.instantiate() as Projectile
	if projectile == null:
		push_error("Projectile scene root must inherit Projectile")
		return false

	var base_direction := Vector2.RIGHT.rotated(global_rotation)
	var spread_radians := deg_to_rad(randf_range(-spread_degrees, spread_degrees))
	var shot_direction := base_direction.rotated(spread_radians)
	projectile.global_position = muzzle.global_position
	projectile.configure(shot_direction, damage, projectile_speed)
	get_tree().current_scene.add_child(projectile)
	_play_muzzle_flash()
	shot_fired.emit()
	return true

func start_reload() -> bool:
	if _is_reloading or ammo >= magazine_capacity:
		return false
	if not infinite_reserve_ammo and reserve_ammo <= 0:
		return false
	_is_reloading = true
	_reload_left = reload_duration
	reload_started.emit(reload_duration)
	return true

func cancel_reload() -> void:
	if not _is_reloading:
		return
	_is_reloading = false
	_reload_left = 0.0
	reload_cancelled.emit()

func _trigger_perfect_reload() -> void:
	perfect_reload.emit()
	_reload_left = minf(_reload_left, reload_duration * perfect_reload_time_reduction)

func _finish_reload() -> void:
	_is_reloading = false
	_reload_left = 0.0
	var needed := magazine_capacity - ammo
	var loaded := needed if infinite_reserve_ammo else mini(needed, reserve_ammo)
	ammo += loaded
	if not infinite_reserve_ammo:
		reserve_ammo -= loaded
	_emit_ammo()
	reload_finished.emit()

func add_reserve_ammo(amount: int) -> void:
	if amount <= 0 or infinite_reserve_ammo:
		return
	reserve_ammo += amount
	_emit_ammo()

func set_infinite_reserve(enabled: bool) -> void:
	infinite_reserve_ammo = enabled
	_emit_ammo()

func _is_in_perfect_reload_window() -> bool:
	var progress := reload_progress()
	return progress >= perfect_reload_window_start and progress <= perfect_reload_window_end

func _update_heat(delta: float) -> void:
	if not uses_heat:
		return
	if _overheated:
		_overheat_left -= delta
		if _overheat_left <= 0.0:
			_overheated = false
			heat = 0.0
			heat_changed.emit(heat, max_heat)
			overheat_recovered.emit()
		return
	if heat > 0.0 and not Input.is_action_pressed("fire"):
		heat = maxf(0.0, heat - heat_cool_rate * delta)
		heat_changed.emit(heat, max_heat)

func _begin_overheat() -> void:
	_overheated = true
	_overheat_left = overheat_lock_duration
	overheated.emit(overheat_lock_duration)

func _emit_ammo() -> void:
	ammo_changed.emit(ammo, magazine_capacity, -1 if infinite_reserve_ammo else reserve_ammo)

func _play_muzzle_flash() -> void:
	if muzzle_flash == null:
		return
	muzzle_flash.visible = true
	muzzle_flash.rotation = randf_range(-0.15, 0.15)
	var timer := get_tree().create_timer(muzzle_flash_duration)
	timer.timeout.connect(func():
		if is_instance_valid(muzzle_flash):
			muzzle_flash.visible = false
	)

func is_reloading() -> bool:
	return _is_reloading

func reload_progress() -> float:
	if not _is_reloading or reload_duration <= 0.0:
		return 0.0
	return 1.0 - clampf(_reload_left / reload_duration, 0.0, 1.0)

func is_perfect_reload_window_active() -> bool:
	return _is_reloading and _is_in_perfect_reload_window()

func is_overheated() -> bool:
	return _overheated
