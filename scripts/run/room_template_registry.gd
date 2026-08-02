class_name RoomTemplateRegistry
extends RefCounted

var templates: Dictionary = {}
var usage_counts: Dictionary = {}

func register(template: RoomTemplateDefinition) -> bool:
	if template == null or template.id == &"" or not template.validate_definition().is_empty():
		return false
	templates[template.id] = template
	if not usage_counts.has(template.id):
		usage_counts[template.id] = 0
	return true

func get_template(id: StringName) -> RoomTemplateDefinition:
	return templates.get(id)

func select(zone_id: StringName, room_type: StringName, target_threat: int, rng: RandomNumberGenerator = null) -> RoomTemplateDefinition:
	var probe := RoomNodeDefinition.new()
	probe.id = &"__selection_probe__"
	probe.room_type = room_type
	probe.difficulty = target_threat
	return choose_for_node(probe, zone_id, rng)

func choose_for_node(node: RoomNodeDefinition, zone_id: StringName, rng: RandomNumberGenerator = null) -> RoomTemplateDefinition:
	if node == null:
		return null
	var candidates: Array[RoomTemplateDefinition] = []
	for template in templates.values():
		if template.zone_id != zone_id:
			continue
		if not _room_types_compatible(node.room_type, template.room_type):
			continue
		candidates.append(template)
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(a: RoomTemplateDefinition, b: RoomTemplateDefinition):
		var a_score: int = absi(a.recommended_threat - node.difficulty) + int(usage_counts.get(a.id, 0)) * 2
		var b_score: int = absi(b.recommended_threat - node.difficulty) + int(usage_counts.get(b.id, 0)) * 2
		return a_score < b_score
	)
	var shortlist_count := mini(3, candidates.size())
	var index := 0
	if rng != null and shortlist_count > 1:
		index = rng.randi_range(0, shortlist_count - 1)
	var selected := candidates[index]
	usage_counts[selected.id] = int(usage_counts.get(selected.id, 0)) + 1
	return selected

func serialize_usage() -> Dictionary:
	var result: Dictionary = {}
	for id in usage_counts.keys():
		result[String(id)] = int(usage_counts[id])
	return result

func restore_usage(data: Dictionary) -> void:
	usage_counts.clear()
	for id in data.keys():
		usage_counts[StringName(id)] = maxi(0, int(data[id]))

func _room_types_compatible(node_type: StringName, template_type: StringName) -> bool:
	if node_type == template_type:
		return true
	if node_type == &"start":
		return template_type in [&"start", &"rest"]
	return false
