class_name RouteChoicePanel
extends CanvasLayer

signal route_selected(room_id: StringName)

const RESTART_ID: StringName = &"__restart__"

var options: Array[RouteRoomData] = []
var progress: Dictionary = {}

func configure(next_options: Array[RouteRoomData], progress_snapshot: Dictionary) -> void:
	options.clear()
	for option in next_options:
		if option != null:
			options.append(option.duplicate_room())
	progress = progress_snapshot.duplicate(true)

func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if options.is_empty() and (key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_SPACE):
			_select(RESTART_ID)
		elif key.physical_keycode == KEY_1 and options.size() >= 1:
			_select(options[0].room_id)
		elif key.physical_keycode == KEY_2 and options.size() >= 2:
			_select(options[1].room_id)

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.004, 0.009, 0.014, 0.94)
	root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-390.0, -205.0)
	panel.size = Vector2(780.0, 410.0)
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	margin.add_child(outer)

	var room_number := int(progress.get("room_number", 0))
	var total_rooms := int(progress.get("total_rooms", 8))
	var title := Label.new()
	title.text = "ROUTE COMPLETE" if options.is_empty() else "SELECT NEXT ROUTE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("ffbd55"))
	outer.add_child(title)

	var progress_label := Label.new()
	progress_label.text = "ROOM %d/%d  |  DANGER ROOMS %d" % [room_number, total_rooms, int(progress.get("danger_count", 0))]
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 15)
	progress_label.add_theme_color_override("font_color", Color("9fb7c4"))
	outer.add_child(progress_label)

	if options.is_empty():
		_build_complete_content(outer)
	else:
		_build_option_content(outer)

func _build_option_content(outer: VBoxContainer) -> void:
	var choices := HBoxContainer.new()
	choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", 14)
	outer.add_child(choices)
	for index in range(options.size()):
		var option := options[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(350.0, 245.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = _option_text(option, index)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_select.bind(option.room_id))
		if option.is_dangerous():
			button.add_theme_color_override("font_color", Color("ff8b72"))
		else:
			button.add_theme_color_override("font_color", Color("8bd8ff"))
		choices.add_child(button)

	var hint := Label.new()
	hint.text = "KEYBOARD: 1 / 2    TOUCH: SELECT CARD"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	outer.add_child(hint)

func _build_complete_content(outer: VBoxContainer) -> void:
	var current: Dictionary = progress.get("current_room", {})
	var summary := Label.new()
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.text = "P2 EIGHT-ROOM ROUTE CLEARED\n\nFINAL ROOM: %s\nVISITED: %d ROOMS\nDANGER CHOICES: %d\n\nThe prototype route loop is complete." % [
		String(current.get("display_name", "UNKNOWN")),
		int(progress.get("room_number", 0)),
		int(progress.get("danger_count", 0))
	]
	summary.add_theme_font_size_override("font_size", 18)
	summary.add_theme_color_override("font_color", Color("dce8ed"))
	outer.add_child(summary)

	var restart := Button.new()
	restart.text = "RESTART RUN [ENTER]"
	restart.custom_minimum_size = Vector2(0.0, 54.0)
	restart.add_theme_font_size_override("font_size", 17)
	restart.pressed.connect(_select.bind(RESTART_ID))
	outer.add_child(restart)

func _option_text(option: RouteRoomData, index: int) -> String:
	return "%d  |  %s\n%s\n%s\n\nENEMIES %d\nHP x%.2f  |  DMG x%.2f\nHAZARD %d  |  REWARD TIER %d\n\n%s" % [
		index + 1,
		option.path_label(),
		option.display_name,
		option.type_label(),
		option.enemy_count,
		option.enemy_health_multiplier,
		option.enemy_damage_multiplier,
		option.hazard_level,
		option.reward_tier,
		option.description
	]

func _select(room_id: StringName) -> void:
	if get_tree() != null:
		get_tree().paused = false
	route_selected.emit(room_id)
	queue_free()

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
