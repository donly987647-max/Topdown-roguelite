class_name WeaponFrameDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var weapon_class: StringName
@export var role: String
@export var base_damage: float = 10.0
@export var fire_interval: float = 0.2
@export var magazine_size: int = 10
@export var reload_time: float = 1.0
@export var max_power: float = 100.0
@export var max_weight: float = 100.0
@export var stability: float = 1.0
@export var compatibility_tags: PackedStringArray = []
@export var ammo_type: StringName = &"ballistic"
@export var uses_heat: bool = false
@export var heat_per_shot: float = 0.0
@export var special_rule: StringName
