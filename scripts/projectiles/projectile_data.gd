class_name ProjectileData
extends Resource

@export var damage := 18.0
@export var speed := 900.0
@export var lifetime := 1.5
@export var radius := 3.0
@export var pierce_count := 0
@export var pierce_damage_decay := 0.0
@export var ricochet_count := 0
@export var ricochet_damage_multiplier := 1.0
@export var homing_strength := 0.0
@export var knockback := 35.0
@export var critical_chance := 0.05
@export var status_type: StringName = &""
@export var status_buildup := 0.0
@export var explosion_radius := 0.0
@export var faction: StringName = &"player"
@export var collision_mask := GameConstants.LAYER_WORLD | GameConstants.LAYER_ENEMY
