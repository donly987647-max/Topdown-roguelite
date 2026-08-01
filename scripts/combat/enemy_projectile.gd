class_name EnemyProjectile
extends Area2D

@export var speed: float = 520.0
@export var lifetime: float = 4.0
@export var damage: float = 12.0
@export var knockback_force: float = 130.0

var direction := Vector2.RIGHT
var _active := true

func _ready() -> void:
	add_to_group("enemy_projectile")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func configure(new_direction: Vector2, new_damage: float = -1.0, new_speed: float = -1.0) -> void:
	direction = new_direction.normalized()
	if new_damage > 0.0:
		damage = new_damage
	if new_speed > 0.0:
		speed = new_speed
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if not _active:
		return
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _try_hit(target: Node) -> void:
	if not _active:
		return

	var receiver: Node = target
	if not receiver.has_method("take_damage") and target.get_parent() != null and target.get_parent().has_method("take_damage"):
		receiver = target.get_parent()

	if receiver is Player:
		receiver.take_damage(damage, direction * knockback_force)
		_active = false
		queue_free()
	elif target is StaticBody2D:
		_active = false
		queue_free()
