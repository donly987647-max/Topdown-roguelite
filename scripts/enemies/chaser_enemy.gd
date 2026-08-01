class_name ChaserEnemy
extends CharacterBody2D

@export var max_health: float = 70.0
@export var move_speed: float = 150.0
@export var acceleration: float = 900.0
@export var contact_damage: float = 14.0
@export var contact_knockback: float = 360.0
@export var attack_cooldown: float = 0.85
@export var knockback_decay: float = 1100.0

var health: float
var _target: Player
var _attack_cooldown_left := 0.0
var _external_knockback := Vector2.ZERO
var _dead := false

@onready var body_visual: Polygon2D = $BodyVisual
@onready var attack_area: Area2D = $AttackArea
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	call_deferred("_resolve_target")

func _resolve_target() -> void:
	_target = get_tree().get_first_node_in_group("player") as Player

func _physics_process(delta: float) -> void:
	_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
	_external_knockback = _external_knockback.move_toward(Vector2.ZERO, knockback_decay * delta)

	if _dead:
		velocity = _external_knockback
		move_and_slide()
		return

	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	else:
		var desired := global_position.direction_to(_target.global_position) * move_speed
		velocity = velocity.move_toward(desired, acceleration * delta)
		_try_contact_attack()

	velocity += _external_knockback
	move_and_slide()

func _try_contact_attack() -> void:
	if _attack_cooldown_left > 0.0:
		return
	for area in attack_area.get_overlapping_areas():
		var receiver := area.get_parent()
		if receiver is Player:
			var direction := global_position.direction_to(receiver.global_position)
			if receiver.take_damage(contact_damage, direction * contact_knockback):
				_attack_cooldown_left = attack_cooldown
			return

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> bool:
	if _dead or amount <= 0.0:
		return false
	health = maxf(0.0, health - amount)
	health_bar.value = health
	_external_knockback += knockback
	_flash_hit()
	if health <= 0.0:
		_die()
	return true

func _flash_hit() -> void:
	body_visual.modulate = Color(1.0, 0.4, 0.32, 1.0)
	var tween := create_tween()
	tween.tween_property(body_visual, "modulate", Color.WHITE, 0.08)

func _die() -> void:
	_dead = true
	collision_layer = 0
	collision_mask = 0
	attack_area.monitoring = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.14)
	tween.tween_property(self, "modulate:a", 0.0, 0.14)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
