class_name StatusReceiver
extends Node

signal status_changed(status_id: StringName, stacks: int, remaining: float)
signal status_expired(status_id: StringName)

@export var biological: bool = true
@export var mechanical: bool = false
@export var boss: bool = false
@export var armored: bool = false
@export var shielded: bool = false

var _states: Dictionary = {}

func apply_status(status_id: StringName, stacks: int = 1) -> bool:
	var rule := _rule(status_id)
	if rule.is_empty():
		return false
	if status_id == &"bleed" and not biological:
		return false
	var applied_stacks := maxi(1, stacks)
	if status_id == &"shock" and mechanical:
		applied_stacks += 1
	var max_stacks := int(rule.get("max_stacks", 1))
	var state: Dictionary = _states.get(status_id, {"stacks": 0, "remaining": 0.0, "tick": 0.0})
	state["stacks"] = mini(max_stacks, int(state["stacks"]) + applied_stacks)
	state["remaining"] = maxf(float(state["remaining"]), float(rule.get("duration", 1.0)))
	state["tick"] = minf(float(state["tick"]), float(rule.get("tick_interval", 0.5))) if float(state["tick"]) > 0.0 else float(rule.get("tick_interval", 0.5))
	_states[status_id] = state
	status_changed.emit(status_id, int(state["stacks"]), float(state["remaining"]))
	return true

func _process(delta: float) -> void:
	var expired: Array[StringName] = []
	for id in _states.keys():
		var state: Dictionary = _states[id]
		var rule := _rule(id)
		state["remaining"] = float(state["remaining"]) - delta
		state["tick"] = float(state["tick"]) - delta
		if float(state["tick"]) <= 0.0:
			_tick_status(id, state, rule)
			state["tick"] = float(rule.get("tick_interval", 0.5))
		_states[id] = state
		if float(state["remaining"]) <= 0.0:
			expired.append(id)
	for id in expired:
		_states.erase(id)
		status_expired.emit(id)

func damage_taken_multiplier() -> float:
	var mult := 1.0
	if _states.has(&"vulnerable"):
		mult *= 1.25
	if _states.has(&"corrosion"):
		var stacks := int((_states[&"corrosion"] as Dictionary)["stacks"])
		var per_stack := 0.08
		if armored:
			per_stack = 0.12
		elif shielded:
			per_stack = 0.10
		mult *= 1.0 + stacks * per_stack
	return mult

func move_speed_multiplier() -> float:
	if not _states.has(&"cold"):
		return 1.0
	var stacks := int((_states[&"cold"] as Dictionary)["stacks"])
	return maxf(0.25, 1.0 - 0.12 * stacks)

func attack_speed_multiplier() -> float:
	return move_speed_multiplier() if _states.has(&"cold") else 1.0

func is_frozen() -> bool:
	return not boss and _states.has(&"cold") and int((_states[&"cold"] as Dictionary)["stacks"]) >= 5

func is_confused() -> bool:
	return _states.has(&"confusion")

func has_status(id: StringName) -> bool:
	return _states.has(id)

func stacks(id: StringName) -> int:
	if not _states.has(id):
		return 0
	return int((_states[id] as Dictionary)["stacks"])

func react_to_explosion(base_damage: float) -> float:
	if base_damage <= 0.0 or not _states.has(&"burn"):
		return 0.0
	var burn_stacks := stacks(&"burn")
	var bonus := base_damage * (0.12 + 0.04 * burn_stacks)
	var host := get_parent()
	if host != null and host.has_method("take_damage"):
		host.take_damage(bonus, Vector2.ZERO)
	return bonus

func react_to_strong_hit(base_damage: float) -> float:
	if base_damage <= 0.0 or not is_frozen():
		return 0.0
	var shatter := maxf(8.0, base_damage * 0.35)
	_states.erase(&"cold")
	status_expired.emit(&"cold")
	return shatter

func _tick_status(id: StringName, state: Dictionary, rule: Dictionary) -> void:
	var host := get_parent()
	if host == null or not host.has_method("take_damage"):
		return
	var stacks_count := int(state["stacks"])
	var tick_damage := float(rule.get("tick_damage", 0.0)) * stacks_count
	if id == &"shock" and mechanical:
		tick_damage *= 1.35
	if id == &"bleed":
		var moving := host is CharacterBody2D and (host as CharacterBody2D).velocity.length_squared() > 64.0
		if moving:
			tick_damage *= 1.6
	if tick_damage > 0.0:
		host.take_damage(tick_damage, Vector2.ZERO)
	if id == &"shock":
		_chain_shock(tick_damage * 0.6)

func _chain_shock(amount: float) -> void:
	if amount <= 0.0:
		return
	var host := get_parent() as Node2D
	if host == null:
		return
	var best: Node2D
	var best_distance := 240.0 * 240.0
	for candidate in get_tree().get_nodes_in_group("enemy"):
		if candidate == host or not (candidate is Node2D):
			continue
		var distance := host.global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	if best != null and best.has_method("take_damage"):
		best.take_damage(amount, Vector2.ZERO)

func _rule(id: StringName) -> Dictionary:
	match id:
		&"burn": return {"duration": 4.0, "max_stacks": 5, "tick_interval": 0.5, "tick_damage": 1.8}
		&"cold": return {"duration": 3.5, "max_stacks": 5, "tick_interval": 0.5, "tick_damage": 0.0}
		&"shock": return {"duration": 3.0, "max_stacks": 5, "tick_interval": 0.75, "tick_damage": 1.2}
		&"corrosion": return {"duration": 5.0, "max_stacks": 5, "tick_interval": 0.75, "tick_damage": 0.8}
		&"bleed": return {"duration": 4.0, "max_stacks": 5, "tick_interval": 0.5, "tick_damage": 1.5}
		&"confusion": return {"duration": 3.0 if not boss else 1.5, "max_stacks": 1, "tick_interval": 0.5, "tick_damage": 0.0}
		&"vulnerable": return {"duration": 2.0, "max_stacks": 1, "tick_interval": 0.5, "tick_damage": 0.0}
	return {}
