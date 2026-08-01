class_name BackpackItemDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity: StringName = &"common"
@export var cells: PackedVector2Array = [Vector2(0, 0)]
@export var rotatable: bool = true
@export var connector_types: Dictionary = {}
@export var tags: PackedStringArray = []
@export var adjacency_effect_ids: PackedStringArray = []
@export var effect_ids: PackedStringArray = []
@export var power_draw: float = 0.0
@export var power_supply: float = 0.0
@export var ammo_supply: float = 0.0
@export var cooling_supply: float = 0.0
@export var signal_strength: float = 0.0
@export var requires_power: bool = false
