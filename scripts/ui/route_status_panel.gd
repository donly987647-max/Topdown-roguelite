class_name RouteStatusPanel
extends CanvasLayer

var _label: Label

func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := PanelContainer.new()
	panel.position = Vector2(356.0, 12.0)
	panel.size = Vector2(248.0, 58.0)
	add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color("ffbd55"))
	margin.add_child(_label)
	update_progress({})

func update_progress(snapshot: Dictionary) -> void:
	if _label == null:
		return
	var current: Dictionary = snapshot.get("current_room", {})
	var room_number := int(snapshot.get("room_number", 0))
	var total_rooms := int(snapshot.get("total_rooms", 8))
	_label.text = "ROOM %d/%d  |  %s\n%s  |  %s" % [
		room_number,
		total_rooms,
		String(current.get("path_label", "MAIN")),
		String(current.get("display_name", "ROUTE INITIALIZING")),
		String(current.get("type_label", "COMBAT"))
	]
