class_name Projectile
extends Area2D

@export var speed: float = 1250.0
@export var lifetime: float = 1.6
@export var damage: float = 20.0
@export var knockback_force: float = 180.0
@export var max_pierces: int = 0

var direction := Vector2.RIGHT
var _remaining_pierces := 0
var _alive := true

func _ready() -> void:
	_remaining_pierces = max_pierces
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func configure(new_direction: Vector2, new_damage: float, new_speed: float = -1.0) -> void:
	direction = new_direction.normalized()
	damage = new_damage
	if new_speed > 0.0:
		speed = new_speed
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if not _alive:
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
	if not _alive:
		return

	var receiver: Node = target
	if not receiver.has_method("take_damage") and target.get_parent() != null and target.get_parent().has_method("take_damage"):
		receiver = target.get_parent()

	if receiver.has_method("take_damage"):
		receiver.take_damage(damage, direction * knockback_force)
		_consume_hit()
	elif target is PhysicsBody2D:
		queue_free()

func _consume_hit() -> void:
	if _remaining_pierces > 0:
		_remaining_pierces -= 1
		return
	_alive = false
	queue_free()
