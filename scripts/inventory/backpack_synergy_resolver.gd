class_name BackpackSynergyResolver
extends RefCounted

const CARDINALS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]

func resolve(grid: BackpackGrid) -> Dictionary:
	var result := {
		"adjacency_pairs": [],
		"connector_links": [],
		"powered_items": {},
		"tags": {},
	}
	if grid == null:
		return result
	var items := grid.items()
	for i in range(items.size()):
		var a = items[i]
		_collect_tags(result["tags"], a.item)
		for j in range(i + 1, items.size()):
			var b = items[j]
			if grid.are_adjacent(a, b):
				result["adjacency_pairs"].append([a, b])
				var links := _matching_connector_links(a, b)
				for link in links:
					result["connector_links"].append(link)
	for placed in items:
		var id := placed.item.id
		result["powered_items"][id] = _is_powered(placed, result["connector_links"])
	return result

func _matching_connector_links(a, b) -> Array:
	var links: Array = []
	if a.item == null or b.item == null:
		return links
	for ca in a.item.connectors:
		for cb in b.item.connectors:
			if _connectors_compatible(ca, cb):
				links.append({"a": a.item.id, "b": b.item.id, "type": ca})
	return links

func _connectors_compatible(a: StringName, b: StringName) -> bool:
	if a == b and a != &"":
		return true
	var power_pair := (a == &"power_out" and b == &"power_in") or (a == &"power_in" and b == &"power_out")
	var signal_pair := (a == &"signal_out" and b == &"signal_in") or (a == &"signal_in" and b == &"signal_out")
	return power_pair or signal_pair

func _is_powered(placed, links: Array) -> bool:
	if placed.item == null:
		return false
	if placed.item.power_draw <= 0.0:
		return true
	for link in links:
		if link["a"] == placed.item.id or link["b"] == placed.item.id:
			if link["type"] in [&"power", &"power_in", &"power_out"]:
				return true
	return false

func _collect_tags(tag_counts: Dictionary, item: BackpackItemDefinition) -> void:
	if item == null:
		return
	for tag in item.tags:
		tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1
