class_name HealthComponent
extends Node

signal changed(snapshot: Dictionary)
signal damaged(health_damage: float, source_position: Vector2)
signal died(packet: DamagePacket)

@export var max_health := 100.0
@export var max_armor_plates := 3
@export var armor_per_plate := 20.0
@export var post_hit_invulnerability := 0.75

var health := 100.0
var temporary_shield := 0.0
var armor_plates: Array[float] = []
var invulnerability_remaining := 0.0
var _recent_attacks: Dictionary = {}

func _ready() -> void:
	health = max_health
	for _index in range(max_armor_plates):
		armor_plates.append(armor_per_plate)
	_emit_changed()

func _process(delta: float) -> void:
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)
	var now := Time.get_ticks_msec()
	for key in _recent_attacks.keys():
		if now - int(_recent_attacks[key]) > 1500:
			_recent_attacks.erase(key)

func apply_damage(packet: DamagePacket, bypass_invulnerability := false) -> Dictionary:
	if packet == null or packet.amount <= 0.0:
		return {"accepted": false, "health_damage": 0.0, "absorbed": 0.0}
	if packet.attack_id != &"" and _recent_attacks.has(packet.attack_id):
		return {"accepted": false, "health_damage": 0.0, "absorbed": 0.0}
	if invulnerability_remaining > 0.0 and not bypass_invulnerability:
		return {"accepted": false, "health_damage": 0.0, "absorbed": 0.0}
	if packet.attack_id != &"":
		_recent_attacks[packet.attack_id] = Time.get_ticks_msec()
	var remaining := packet.amount
	var absorbed := 0.0
	if temporary_shield > 0.0:
		var used := minf(temporary_shield, remaining)
		temporary_shield -= used
		remaining -= used
		absorbed += used
	for index in range(armor_plates.size()):
		if remaining <= 0.0:
			break
		if armor_plates[index] <= 0.0:
			continue
		var plate_used := minf(armor_plates[index], remaining)
		armor_plates[index] -= plate_used
		remaining -= plate_used
		absorbed += plate_used
	var health_damage := minf(health, remaining)
	health -= health_damage
	invulnerability_remaining = post_hit_invulnerability
	damaged.emit(health_damage, packet.source_position)
	_emit_changed()
	if health <= 0.0:
		died.emit(packet)
	return {"accepted": true, "health_damage": health_damage, "absorbed": absorbed}

func restore_full() -> void:
	health = max_health
	temporary_shield = 0.0
	armor_plates.clear()
	for _index in range(max_armor_plates):
		armor_plates.append(armor_per_plate)
	invulnerability_remaining = 0.0
	_recent_attacks.clear()
	_emit_changed()

func add_temporary_shield(amount: float) -> void:
	temporary_shield += maxf(0.0, amount)
	_emit_changed()

func get_snapshot() -> Dictionary:
	var armor_total := 0.0
	for value in armor_plates:
		armor_total += value
	return {
		"health": health,
		"max_health": max_health,
		"armor": armor_total,
		"max_armor": max_armor_plates * armor_per_plate,
		"temporary_shield": temporary_shield,
		"invulnerable": invulnerability_remaining > 0.0
	}

func _emit_changed() -> void:
	changed.emit(get_snapshot())
