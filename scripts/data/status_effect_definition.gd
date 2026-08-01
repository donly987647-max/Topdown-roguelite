class_name StatusEffectDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var max_stacks: int = 1
@export var duration: float = 0.0
@export var tick_interval: float = 0.0
@export var tags: PackedStringArray = []
@export var boss_behavior: StringName
@export var effect_parameters: Dictionary = {}
