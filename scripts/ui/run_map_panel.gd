class_name RunMapPanel
extends Control

signal route_selected(room_id: StringName)

@export var node_spacing := Vector2(170.0, 92.0)
@export var margin := Vector2(48.0, 48.0)

var view_model := RunMapViewModel.new()
var graph: RunGraph
var current_id: StringName = &""
var visited: Array[StringName] = []
var cleared: Dictionary = {}
var _buttons: Dictionary = {}

func bind_run(run_graph: RunGraph, current: StringName, visited_rooms: Array[StringName], cleared_rooms: Dictionary) -> void:
	graph = run_graph
	current_id = current
	visited = visited_rooms.duplicate()
	cleared = cleared_rooms.duplicate()
	rebuild()

func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_buttons.clear()
	if graph == null:
		return
	var model := view_model.build(graph, current_id, visited, cleared)
	var available: Array = graph.edges.get(current_id, [])
	for node_data in model.get("nodes", []):
		var button := Button.new()
		button.focus_mode = Control.FOCUS_ALL
		var id := StringName(node_data.get("id", ""))
		button.text = _label_for(node_data)
		button.position = margin + Vector2(float(node_data.get("depth", 0)) * node_spacing.x, float(node_data.get("lane", 0)) * node_spacing.y)
		button.custom_minimum_size = Vector2(132.0, 54.0)
		button.disabled = id not in available
		button.tooltip_text = _tooltip_for(node_data)
		button.pressed.connect(func(): route_selected.emit(id))
		add_child(button)
		_buttons[id] = button

func focus_first_available() -> void:
	for id in _buttons.keys():
		var button: Button = _buttons[id]
		if not button.disabled:
			button.grab_focus()
			return

func update_state(current: StringName, visited_rooms: Array[StringName], cleared_rooms: Dictionary) -> void:
	current_id = current
	visited = visited_rooms.duplicate()
	cleared = cleared_rooms.duplicate()
	rebuild()

func _label_for(data: Dictionary) -> String:
	var room_type := String(data.get("room_type", "room")).capitalize()
	if bool(data.get("current", false)):
		return "▶ %s" % room_type
	if bool(data.get("cleared", false)):
		return "✓ %s" % room_type
	return room_type

func _tooltip_for(data: Dictionary) -> String:
	var route_class := String(data.get("route_class", "normal"))
	var reward_grade := String(data.get("reward_grade", "normal"))
	return "Route: %s\nReward: %s" % [route_class.capitalize(), reward_grade.capitalize()]
