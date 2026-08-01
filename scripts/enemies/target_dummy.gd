class_name TargetDummy
extends CharacterBody2D

@export var max_health: float = 100.0
@export var knockback_decay: float = 900.0

var health: float
var _dead := false

@onready var body_visual: Polygon2D = $BodyVisual
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health

func _physics_process(delta: float) -> void:
	if velocity.length_squared() > 0.0:
		move_and_slide()
		velocity = velocity.move_toward(Vector2.ZERO, knockback_decay * delta)

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> bool:
	if _dead or amount <= 0.0:
		return false

	health = maxf(0.0, health - amount)
	velocity += knockback
	health_bar.value = health
	_flash_hit()

	if health <= 0.0:
		_die()
	return true

func _flash_hit() -> void:
	body_visual.modulate = Color(1.0, 0.35, 0.3, 1.0)
	var tween := create_tween()
	tween.tween_property(body_visual, "modulate", Color.WHITE, 0.09)

func _die() -> void:
	_dead = true
	collision_layer = 0
	collision_mask = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
