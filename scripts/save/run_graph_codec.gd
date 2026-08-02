class_name RunGraphCodec
extends RefCounted

static func deserialize(data: Dictionary) -> RunGraph:
	var graph := RunGraph.new()
	for raw in data.get("nodes", []):
		if not (raw is Dictionary): continue
		var node := RoomNodeDefinition.new()
		node.id = StringName(raw.get("id", "")); node.room_type = StringName(raw.get("room_type", "combat")); node.difficulty = int(raw.get("difficulty", 1))
		node.reward_tags = PackedStringArray(raw.get("reward_tags", [])); node.metadata = raw.get("metadata", {}).duplicate(true)
		graph.add_node(node)
	graph.start_id = StringName(data.get("start_id", "")); graph.boss_id = StringName(data.get("boss_id", ""))
	for from_raw in data.get("edges", {}).keys():
		for to_raw in data["edges"][from_raw]: graph.connect_nodes(StringName(from_raw), StringName(to_raw))
	return graph
