class_name RunMapViewModel
extends RefCounted

func build(graph: RunGraph, current_id: StringName, visited: Array[StringName], cleared: Dictionary) -> Dictionary:
	if graph == null:
		return {"nodes": [], "edges": [], "current": ""}
	var depth_by_id := _calculate_depths(graph)
	var lanes: Dictionary = {}
	var nodes_out: Array = []
	var ids := graph.nodes.keys()
	ids.sort_custom(func(a, b):
		var da := int(depth_by_id.get(a, 0))
		var db := int(depth_by_id.get(b, 0))
		return da < db if da != db else String(a) < String(b)
	)
	for id in ids:
		var node: RoomNodeDefinition = graph.nodes[id]
		var depth := int(depth_by_id.get(id, 0))
		var lane := int(lanes.get(depth, 0))
		lanes[depth] = lane + 1
		var route_risk := StringName(node.metadata.get("route_risk", node.metadata.get("route_class", "neutral")))
		var rarity_bonus := float(node.metadata.get("reward_rarity_bonus", 0.0))
		nodes_out.append({
			"id": id,
			"room_type": node.room_type,
			"depth": depth,
			"lane": lane,
			"visited": id in visited,
			"cleared": cleared.has(id),
			"current": id == current_id,
			"route_class": route_risk,
			"reward_grade": _reward_grade(rarity_bonus),
			"reward_rarity_bonus": rarity_bonus,
		})
	var edges_out: Array = []
	for from_id in graph.edges.keys():
		for to_id in graph.edges[from_id]:
			edges_out.append({"from": from_id, "to": to_id, "available": from_id == current_id})
	return {"nodes": nodes_out, "edges": edges_out, "current": current_id}

func _reward_grade(bonus: float) -> StringName:
	if bonus >= 0.15: return &"high"
	if bonus <= -0.05: return &"low"
	return &"normal"

func _calculate_depths(graph: RunGraph) -> Dictionary:
	var depths: Dictionary = {}
	if graph.start_id == &"":
		return depths
	depths[graph.start_id] = 0
	var queue: Array[StringName] = [graph.start_id]
	while not queue.is_empty():
		var current: StringName = StringName(queue.pop_front())
		var next_depth := int(depths[current]) + 1
		for next_id in graph.edges.get(current, []):
			if not depths.has(next_id) or next_depth < int(depths[next_id]):
				depths[next_id] = next_depth
				queue.append(next_id)
	return depths
