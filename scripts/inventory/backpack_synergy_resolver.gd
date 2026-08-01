class_name BackpackSynergyResolver
extends RefCounted

func resolve(grid: BackpackGrid) -> Dictionary:
	var result := {
		"adjacency_pairs": [],
		"connector_links": [],
		"powered_items": {},
		"tags": {},
		"tag_tiers": {},
		"active_effect_ids": [],
		"power_networks": [],
		"power_supply": 0.0,
		"power_draw": 0.0,
		"unused_power": 0.0,
		"ammo_supply": 0.0,
		"cooling_supply": 0.0,
		"signal_strength": 0.0,
	}
	if grid == null:
		return result
	var items := grid.items()
	var ports_by_item := {}
	for placed in items:
		var item: BackpackItemDefinition = placed.get("item")
		if item == null:
			continue
		_collect_tags(result["tags"], item)
		ports_by_item[item.id] = grid.connector_world_ports(placed)
		result["power_supply"] += item.power_supply
		result["power_draw"] += item.power_draw
		result["ammo_supply"] += item.ammo_supply
		result["cooling_supply"] += item.cooling_supply
		result["signal_strength"] += item.signal_strength
	for i in range(items.size()):
		var a: Dictionary = items[i]
		for j in range(i + 1, items.size()):
			var b: Dictionary = items[j]
			if grid.are_adjacent(a, b):
				result["adjacency_pairs"].append([a, b])
				_collect_adjacency_effects(result["active_effect_ids"], a, b)
			var links := _matching_connector_links(a, b, ports_by_item)
			for link in links:
				result["connector_links"].append(link)
	_resolve_power(items, result)
	_resolve_tag_tiers(result)
	result["unused_power"] = maxf(0.0, float(result["power_supply"]) - float(result["power_draw"]))
	return result

func _matching_connector_links(a: Dictionary, b: Dictionary, ports_by_item: Dictionary) -> Array:
	var links: Array = []
	var item_a: BackpackItemDefinition = a.get("item")
	var item_b: BackpackItemDefinition = b.get("item")
	if item_a == null or item_b == null:
		return links
	for port_a in ports_by_item.get(item_a.id, []):
		for port_b in ports_by_item.get(item_b.id, []):
			if port_a["target_cell"] != port_b["cell"] or port_b["target_cell"] != port_a["cell"]:
				continue
			if not _connectors_compatible(port_a["type"], port_b["type"]):
				continue
			links.append({
				"a": item_a.id,
				"b": item_b.id,
				"a_type": port_a["type"],
				"b_type": port_b["type"],
				"a_cell": port_a["cell"],
				"b_cell": port_b["cell"],
				"channel": _channel_for_pair(port_a["type"], port_b["type"]),
			})
	return links

func _connectors_compatible(a: StringName, b: StringName) -> bool:
	if a == b and a in [&"power", &"signal", &"ammo", &"cooling"]:
		return true
	return _pair_matches(a, b, &"power") or _pair_matches(a, b, &"signal") or _pair_matches(a, b, &"ammo") or _pair_matches(a, b, &"cooling")

func _pair_matches(a: StringName, b: StringName, channel: StringName) -> bool:
	var input := StringName(String(channel) + "_in")
	var output := StringName(String(channel) + "_out")
	return (a == output and b == input) or (a == input and b == output)

func _channel_for_pair(a: StringName, b: StringName) -> StringName:
	for channel in [&"power", &"signal", &"ammo", &"cooling"]:
		if a == channel and b == channel:
			return channel
		if _pair_matches(a, b, channel):
			return channel
	return &"generic"

func _resolve_power(items: Array, result: Dictionary) -> void:
	var adjacency := {}
	for placed in items:
		var item: BackpackItemDefinition = placed.get("item")
		if item != null:
			adjacency[item.id] = []
	for link in result["connector_links"]:
		if link["channel"] != &"power":
			continue
		adjacency[link["a"]].append(link["b"])
		adjacency[link["b"]].append(link["a"])
	var visited := {}
	for placed in items:
		var item: BackpackItemDefinition = placed.get("item")
		if item == null or visited.has(item.id):
			continue
		var queue: Array[StringName] = [item.id]
		var network_ids: Array[StringName] = []
		visited[item.id] = true
		while not queue.is_empty():
			var current: StringName = queue.pop_front()
			network_ids.append(current)
			for neighbor in adjacency.get(current, []):
				if not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)
		var supply := 0.0
		var draw := 0.0
		for id in network_ids:
			var network_item := _item_by_id(items, id)
			if network_item != null:
				supply += network_item.power_supply
				draw += network_item.power_draw
		result["power_networks"].append({"items": network_ids, "supply": supply, "draw": draw, "overloaded": draw > supply and draw > 0.0})
		var remaining := supply
		var sorted_ids := network_ids.duplicate()
		sorted_ids.sort_custom(func(a: StringName, b: StringName):
			var ia := _item_by_id(items, a)
			var ib := _item_by_id(items, b)
			return (ia.power_draw if ia != null else 0.0) < (ib.power_draw if ib != null else 0.0)
		)
		for id in sorted_ids:
			var network_item := _item_by_id(items, id)
			if network_item == null:
				continue
			if network_item.power_draw <= 0.0 and not network_item.requires_power:
				result["powered_items"][id] = true
				continue
			var needed := maxf(0.0, network_item.power_draw)
			var powered := remaining >= needed and (supply > 0.0 or not network_item.requires_power)
			result["powered_items"][id] = powered
			if powered:
				remaining -= needed
	for placed in items:
		var item: BackpackItemDefinition = placed.get("item")
		if item != null and not result["powered_items"].has(item.id):
			result["powered_items"][item.id] = item.power_draw <= 0.0 and not item.requires_power

func _collect_adjacency_effects(active_effect_ids: Array, a: Dictionary, b: Dictionary) -> void:
	for placed in [a, b]:
		var item: BackpackItemDefinition = placed.get("item")
		if item == null:
			continue
		for effect_id in item.adjacency_effect_ids:
			var id := StringName(effect_id)
			if id not in active_effect_ids:
				active_effect_ids.append(id)

func _resolve_tag_tiers(result: Dictionary) -> void:
	for tag in result["tags"].keys():
		var count := int(result["tags"][tag])
		var tier := 0
		if count >= 6:
			tier = 3
		elif count >= 4:
			tier = 2
		elif count >= 2:
			tier = 1
		result["tag_tiers"][tag] = tier

func _item_by_id(items: Array, id: StringName) -> BackpackItemDefinition:
	for placed in items:
		var item: BackpackItemDefinition = placed.get("item")
		if item != null and item.id == id:
			return item
	return null

func _collect_tags(tag_counts: Dictionary, item: BackpackItemDefinition) -> void:
	if item == null:
		return
	for tag in item.tags:
		tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1
