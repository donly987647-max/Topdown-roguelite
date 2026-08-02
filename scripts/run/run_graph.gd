class_name RunGraph
extends RefCounted

var nodes: Dictionary = {}
var edges: Dictionary = {}
var start_id: StringName
var boss_id: StringName

func clear() -> void:
	nodes.clear()
	edges.clear()
	start_id = &""
	boss_id = &""

func add_node(node: RoomNodeDefinition) -> bool:
	if node == null or node.id == &"" or nodes.has(node.id):
		return false
	nodes[node.id] = node
	edges[node.id] = []
	return true

func connect_nodes(from_id: StringName, to_id: StringName) -> bool:
	if not nodes.has(from_id) or not nodes.has(to_id) or from_id == to_id:
		return false
	var list: Array = edges.get(from_id, [])
	if to_id in list:
		return false
	list.append(to_id)
	edges[from_id] = list
	return true

func next_nodes(from_id: StringName) -> Array[RoomNodeDefinition]:
	var result: Array[RoomNodeDefinition] = []
	for id in edges.get(from_id, []):
		var node: RoomNodeDefinition = nodes.get(id)
		if node != null:
			result.append(node)
	return result

func has_path(from_id: StringName, to_id: StringName) -> bool:
	if from_id == to_id:
		return nodes.has(from_id)
	var visited: Dictionary = {}
	var queue: Array[StringName] = [from_id]
	while not queue.is_empty():
		var current: StringName = StringName(queue.pop_front())
		if visited.has(current):
			continue
		visited[current] = true
		for next_id in edges.get(current, []):
			if next_id == to_id:
				return true
			if not visited.has(next_id):
				queue.append(next_id)
	return false

func serialize() -> Dictionary:
	var serialized_nodes: Array = []
	for id in nodes.keys():
		var node: RoomNodeDefinition = nodes[id]
		serialized_nodes.append({
			"id": String(node.id),
			"room_type": String(node.room_type),
			"difficulty": node.difficulty,
			"reward_tags": Array(node.reward_tags),
			"metadata": node.metadata.duplicate(true),
		})
	var serialized_edges: Dictionary = {}
	for id in edges.keys():
		serialized_edges[String(id)] = []
		for target in edges[id]:
			serialized_edges[String(id)].append(String(target))
	return {"start_id": String(start_id), "boss_id": String(boss_id), "nodes": serialized_nodes, "edges": serialized_edges}
