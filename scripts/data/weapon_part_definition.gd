class_name WeaponPartDefinition
extends Resource

enum PartType { BARREL, MAGAZINE, CORE }

@export var id: StringName
@export var display_name: String
@export var part_type: PartType
@export_multiline var description: String
@export var rarity: StringName = &"common"
@export var power_cost: float = 0.0
@export var weight: float = 0.0
@export var tags: PackedStringArray = []
@export var compatible_tags: PackedStringArray = []
@export var modifiers: Dictionary = {}
@export var effect_ids: PackedStringArray = []
