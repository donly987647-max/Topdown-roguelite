class_name ServicePistol
extends Node2D

signal ammo_state_changed(current: int, capacity: int, reloading: bool)

const BASE_DAMAGE := 18.0
const FIRE_INTERVAL := 0.24
const MAGAZINE_CAPACITY := 10
const RELOAD_TIME := 1.15

var wielder: Node2D
var current_ammo := MAGAZINE_CAPACITY
var fire_cooldown := 0.0
var reload_remaining := 0.0
var aim_direction := Vector2.RIGHT

func setup(owner_actor: Node2D) -> void:
	wielder = owner_actor
	ammo_state_changed.emit(current_ammo, MAGAZINE_CAPACITY, false)

func _process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if reload_remaining > 0.0:
		reload_remaining -= delta
		if reload_remaining <= 0.0:
			current_ammo = MAGAZINE_CAPACITY
			ammo_state_changed.emit(current_ammo, MAGAZINE_CAPACITY, false)

func set_aim(direction: Vector2) -> void:
	if direction.length_squared() > 0.001:
		aim_direction = direction.normalized()
	rotation = aim_direction.angle()

func try_fire() -> bool:
	if wielder == null or fire_cooldown > 0.0 or reload_remaining > 0.0:
		return false
	if current_ammo <= 0:
		start_reload()
		return false
	current_ammo -= 1
	fire_cooldown = FIRE_INTERVAL
	var data := ProjectileData.new()
	data.damage = BASE_DAMAGE
	data.speed = 1000.0
	data.lifetime = 1.2
	data.radius = 3.0
	data.knockback = 45.0
	data.critical_chance = 0.05
	data.faction = &"player"
	data.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_ENEMY
	var projectile := CombatProjectile.new()
	get_tree().current_scene.add_child(projectile)
	projectile.setup(data, wielder.global_position + aim_direction * 24.0, aim_direction, wielder)
	AudioManager.play_cue(&"fire", -7.0, 0.03)
	ammo_state_changed.emit(current_ammo, MAGAZINE_CAPACITY, false)
	return true

func start_reload() -> bool:
	if reload_remaining > 0.0 or current_ammo >= MAGAZINE_CAPACITY:
		return false
	reload_remaining = RELOAD_TIME
	AudioManager.play_cue(&"reload", -8.0)
	ammo_state_changed.emit(current_ammo, MAGAZINE_CAPACITY, true)
	return true

func get_snapshot() -> Dictionary:
	return {
		"current": current_ammo,
		"capacity": MAGAZINE_CAPACITY,
		"reloading": reload_remaining > 0.0,
		"reload_progress": 1.0 - clampf(reload_remaining / RELOAD_TIME, 0.0, 1.0)
	}
