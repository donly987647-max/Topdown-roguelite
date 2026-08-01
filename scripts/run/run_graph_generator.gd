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
	var start := _make_node(&"start", &"start", 0)
	graph.add_node(start)
	graph.start_id = start.id
	var previous: Array[StringName] = [start.id]
	for depth in range(1, main_depth + 1):
		var width := 2 if rng.randf() < branch_chance else 1
		var layer: Array[StringName] = []
		for lane in range(width):
			var id := StringName("room_%02d_%d" % [depth, lane])
			var node := _make_node(id, _roll_room_type(rng, depth), depth)
			graph.add_node(node)
			layer.append(id)
		for from_id in previous:
			for to_id in layer:
				graph.connect(from_id, to_id)
		previous = layer
	var boss := _make_node(&"boss", &"boss", main_depth + 1)
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

func _make_node(id: StringName, room_type: StringName, difficulty: int) -> RoomNodeDefinition:
	var node := RoomNodeDefinition.new()
	node.id = id
	node.room_type = room_type
	node.difficulty = difficulty
	match room_type:
		&"combat", &"elite": node.reward_tags = PackedStringArray(["combat_reward"])
		&"shop": node.reward_tags = PackedStringArray(["shop"])
		&"event": node.reward_tags = PackedStringArray(["event"])
		&"rest": node.reward_tags = PackedStringArray(["recovery"])
		&"boss": node.reward_tags = PackedStringArray(["boss_reward"])
	return node

func _roll_room_type(rng: RandomNumberGenerator, depth: int) -> StringName:
	if depth <= 1:
		return &"combat"
	var roll := rng.randf()
	if roll < elite_chance:
		return &"elite"
	roll -= elite_chance
	if roll < shop_chance:
		return &"shop"
	roll -= shop_chance
	if roll < event_chance:
		return &"event"
	roll -= event_chance
	if roll < rest_chance:
		return &"rest"
	return &"combat"
