class_name RunGraphGenerator
extends RefCounted

var main_depth := 8
var branch_chance := 0.45
var shop_chance := 0.16
var event_chance := 0.18
var elite_chance := 0.14
var rest_chance := 0.12

func generate(seed_value: int = 0) -> RunGraph:
	var rng := RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var graph := RunGraph.new()
	var start := _make_node(&"start", &"start", 0, &"neutral")
	graph.add_node(start)
	graph.start_id = start.id
	var previous: Array[StringName] = [start.id]
	for depth in range(1, main_depth + 1):
		var width := 2 if rng.randf() < branch_chance else 1
		var layer: Array[StringName] = []
		for lane in range(width):
			var risk := _lane_risk(width, lane)
			var id := StringName("room_%02d_%d" % [depth, lane])
			var node := _make_node(id, _roll_room_type(rng, depth, risk), depth, risk)
			graph.add_node(node)
			layer.append(id)
		for from_id in previous:
			for to_id in layer:
				graph.connect(from_id, to_id)
		previous = layer
	var boss := _make_node(&"boss", &"boss", main_depth + 1, &"forced")
	graph.add_node(boss)
	graph.boss_id = boss.id
	for from_id in previous:
		graph.connect(from_id, boss.id)
	return graph

func validate(graph: RunGraph) -> Dictionary:
	var errors: Array[String] = []
	if graph == null:
		return {"valid": false, "errors": ["graph is null"]}
	if graph.start_id == &"" or not graph.nodes.has(graph.start_id):
		errors.append("missing start node")
	if graph.boss_id == &"" or not graph.nodes.has(graph.boss_id):
		errors.append("missing boss node")
	if graph.start_id != &"" and graph.boss_id != &"" and not graph.has_path(graph.start_id, graph.boss_id):
		errors.append("boss is unreachable from start")
	for id in graph.nodes.keys():
		if id == graph.boss_id:
			continue
		if graph.edges.get(id, []).is_empty():
			errors.append("dead-end node: %s" % String(id))
	return {"valid": errors.is_empty(), "errors": errors}

func _make_node(id: StringName, room_type: StringName, difficulty: int, route_risk: StringName) -> RoomNodeDefinition:
	var node := RoomNodeDefinition.new()
	node.id = id
	node.room_type = room_type
	node.difficulty = difficulty
	node.metadata = {
		"route_risk": route_risk,
		"reward_rarity_bonus": 0.18 if route_risk == &"risky" else -0.08 if route_risk == &"safe" else 0.0,
		"environment_hazard_multiplier": 1.25 if route_risk == &"risky" else 0.85 if route_risk == &"safe" else 1.0,
	}
	match room_type:
		&"combat", &"elite": node.reward_tags = PackedStringArray(["combat_reward"])
		&"shop": node.reward_tags = PackedStringArray(["shop"])
		&"event": node.reward_tags = PackedStringArray(["event"])
		&"rest": node.reward_tags = PackedStringArray(["recovery"])
		&"boss": node.reward_tags = PackedStringArray(["boss_reward"])
	return node

func _lane_risk(width: int, lane: int) -> StringName:
	if width < 2:
		return &"neutral"
	return &"safe" if lane == 0 else &"risky"

func _roll_room_type(rng: RandomNumberGenerator, depth: int, route_risk: StringName) -> StringName:
	if depth <= 1:
		return &"combat"
	var elite_weight := elite_chance
	var shop_weight := shop_chance
	var event_weight := event_chance
	var rest_weight := rest_chance
	if route_risk == &"safe":
		elite_weight *= 0.45
		shop_weight *= 1.45
		rest_weight *= 1.20
	elif route_risk == &"risky":
		elite_weight *= 1.80
		event_weight *= 1.20
		shop_weight *= 0.70
		rest_weight *= 0.65
	var roll := rng.randf()
	if roll < elite_weight:
		return &"elite"
	roll -= elite_weight
	if roll < shop_weight:
		return &"shop"
	roll -= shop_weight
	if roll < event_weight:
		return &"event"
	roll -= event_weight
	if roll < rest_weight:
		return &"rest"
	return &"combat"
