class_name RangedEnemy
extends CharacterBody2D

@export var max_health: float = 55.0
@export var move_speed: float = 135.0
@export var preferred_distance: float = 410.0
@export var retreat_distance: float = 250.0
@export var fire_interval: float = 1.15
@export var projectile_damage: float = 11.0
@export var projectile_scene: PackedScene

var health: float
var _player: Player
var _fire_cooldown := 0.45
var _dead := false

@onready var body_visual: Polygon2D = $BodyVisual
@onready var muzzle: Marker2D = $Muzzle
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	call_deferred("_resolve_player")

func _resolve_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
		velocity = Vector2.ZERO
		return

	var offset := _player.global_position - global_position
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.01 else Vector2.ZERO

	if distance > preferred_distance:
		velocity = direction * move_speed
	elif distance < retreat_distance:
		velocity = -direction * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	if direction != Vector2.ZERO:
		rotation = direction.angle()

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0 and distance <= preferred_distance * 1.25:
		_fire(direction)
		_fire_cooldown = fire_interval

func _fire(direction: Vector2) -> void:
	if projectile_scene == null or direction == Vector2.ZERO:
		return
	var projectile := projectile_scene.instantiate() as EnemyProjectile
	if projectile == null:
		return
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.configure(direction, projectile_damage)

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> bool:
	if _dead or amount <= 0.0:
		return false
	health = maxf(0.0, health - amount)
	velocity += knockback
	health_bar.value = health
	body_visual.modulate = Color(1.0, 0.6, 0.6, 1.0)
	get_tree().create_timer(0.07).timeout.connect(_restore_visual)
	if health <= 0.0:
		_die()
	return true

func _restore_visual() -> void:
	if is_instance_valid(body_visual) and not _dead:
		body_visual.modulate = Color.WHITE

func _die() -> void:
	_dead = true
	queue_free()
