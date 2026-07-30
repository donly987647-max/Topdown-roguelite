class_name DamagePacket
extends RefCounted

var amount := 0.0
var attack_id: StringName = &""
var source: Node
var source_position := Vector2.ZERO
var critical := false
var strong_hit := false
var knockback := 0.0
var team: StringName = &"neutral"
