class_name WeaponController
extends Node2D

signal ammo_changed(current: int, capacity: int)
signal reload_started(duration: float)
signal reload_finished
signal shot_fired

@export var projectile_scene: PackedScene
@export var damage: float = 20.0
@export var rounds_per_second: float = 6.5
@export var magazine_capacity: int = 12
@export var reload_duration: float = 1.15
@export var spread_degrees: float = 1.5
@export var projectile_speed: float = 1250.0
@export var automatic: bool = true
@export var muzzle_flash_duration: float = 0.045

var ammo: int
var _fire_cooldown := 0.0
var _reload_left := 0.0
var _is_reloading := false

@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_flash: Polygon2D = get_node_or_null("MuzzleFlash") as Polygon2D

func _ready() -> void:
	ammo = magazine_capacity
	ammo_changed.emit(ammo, magazine_capacity)
	if muzzle_flash != null:
		muzzle_flash.visible = false

func _process(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)

	if _is_reloading:
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
	if _is_reloading or _fire_cooldown > 0.0:
		return false
	if ammo <= 0:
		start_reload()
		return false
	if projectile_scene == null:
		push_warning("WeaponController has no projectile_scene")
		return false

	ammo -= 1
	_fire_cooldown = 1.0 / maxf(rounds_per_second, 0.01)
	ammo_changed.emit(ammo, magazine_capacity)

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

func start_reload() -> bool:
	if _is_reloading or ammo >= magazine_capacity:
		return false
	_is_reloading = true
	_reload_left = reload_duration
	reload_started.emit(reload_duration)
	return true

func cancel_reload() -> void:
	_is_reloading = false
	_reload_left = 0.0

func _finish_reload() -> void:
	_is_reloading = false
	_reload_left = 0.0
	ammo = magazine_capacity
	ammo_changed.emit(ammo, magazine_capacity)
	reload_finished.emit()

func is_reloading() -> bool:
	return _is_reloading

func reload_progress() -> float:
	if not _is_reloading or reload_duration <= 0.0:
		return 0.0
	return 1.0 - clampf(_reload_left / reload_duration, 0.0, 1.0)
