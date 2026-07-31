class_name BackpackPanel
extends CanvasLayer

signal equip_requested(item_id: StringName)
signal loadout_restore_requested(parts: Array[WeaponPartData])
signal closed

var grid_model: BackpackGrid
var player: Node
var _baseline_snapshot: Dictionary = {}
var _baseline_parts: Array[WeaponPartData] = []
var _selected_id: StringName = &""
var _pending_rotations: Dictionary = {}
var _grid_container: GridContainer
var _tray_container: VBoxContainer
var _details_label: Label
var _equipped_label: Label
var _status_label: Label
var _close_button: Button
var _auto_arrange_dialog: ConfirmationDialog

func configure(backpack: BackpackGrid, owner_player: Node) -> void:
	grid_model = backpack
	player = owner_player

func _ready() -> void:
	layer = 65
	process_mode = Node.PROCESS_MODE_ALWAYS
	if grid_model == null:
		grid_model = BackpackGrid.new()
	_baseline_snapshot = grid_model.create_snapshot()
	_capture_baseline_parts()
	_build_ui()
	_refresh()
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("inventory") or event.is_action("pause"):
		_try_close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var key := event as InputEventKey
		if key.physical_keycode == KEY_R:
			_rotate_selected()
			get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.005, 0.012, 0.018, 0.94)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-468.0, -258.0)
	panel.size = Vector2(936.0, 516.0)
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 7)
	margin.add_child(outer)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	outer.add_child(title_row)
	var title := Label.new()
	title.text = "LOADOUT GRID | BACKPACK 6x5"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color("ffbd55"))
	title_row.add_child(title)
	_close_button = Button.new()
	_close_button.text = "CLOSE [I]"
	_close_button.custom_minimum_size = Vector2(104.0, 30.0)
	_close_button.pressed.connect(_try_close)
	title_row.add_child(_close_button)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	outer.add_child(content)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(340.0, 0.0)
	left.add_theme_constant_override("separation", 6)
	content.add_child(left)

	var terminal_hint := Label.new()
	terminal_hint.text = "P POWER | A AMMO | C COOLING | S SIGNAL"
	terminal_hint.add_theme_font_size_override("font_size", 12)
	terminal_hint.add_theme_color_override("font_color", Color("8bd8ff"))
	left.add_child(terminal_hint)

	_grid_container = GridContainer.new()
	_grid_container.columns = BackpackGrid.WIDTH
	_grid_container.add_theme_constant_override("h_separation", 4)
	_grid_container.add_theme_constant_override("v_separation", 4)
	left.add_child(_grid_container)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", Color("a8bac3"))
	left.add_child(_status_label)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 5)
	content.add_child(right)

	_equipped_label = Label.new()
	_equipped_label.custom_minimum_size = Vector2(0.0, 68.0)
	_equipped_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equipped_label.add_theme_font_size_override("font_size", 13)
	_equipped_label.add_theme_color_override("font_color", Color("e8eef1"))
	right.add_child(_equipped_label)

	var tray_title := Label.new()
	tray_title.text = "UNPLACED ITEMS"
	tray_title.add_theme_font_size_override("font_size", 13)
	tray_title.add_theme_color_override("font_color", Color("ff8b72"))
	right.add_child(tray_title)

	var tray_scroll := ScrollContainer.new()
	tray_scroll.custom_minimum_size = Vector2(0.0, 62.0)
	tray_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(tray_scroll)
	_tray_container = VBoxContainer.new()
	_tray_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tray_scroll.add_child(_tray_container)

	_details_label = Label.new()
	_details_label.custom_minimum_size = Vector2(0.0, 126.0)
	_details_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_label.add_theme_font_size_override("font_size", 12)
	_details_label.add_theme_color_override("font_color", Color("c9d7dd"))
	right.add_child(_details_label)

	var controls := GridContainer.new()
	controls.columns = 2
	controls.add_theme_constant_override("h_separation", 6)
	controls.add_theme_constant_override("v_separation", 5)
	right.add_child(controls)
	controls.add_child(_make_button("ROTATE [R]", _rotate_selected))
	controls.add_child(_make_button("UNPLACE", _unplace_selected))
	controls.add_child(_make_button("AUTO PLACE", _auto_place_selected))
	controls.add_child(_make_button("EQUIP", _equip_selected))
	controls.add_child(_make_button("AUTO ARRANGE", _request_auto_arrange))
	controls.add_child(_make_button("RESTORE", _restore_previous_state))

	var help := Label.new()
	help.text = "DRAG MOVE | RIGHT-CLICK ROTATE | DOUBLE-CLICK AUTO PLACE | CLICK EMPTY CELL TO PLACE"
	help.add_theme_font_size_override("font_size", 11)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.58))
	outer.add_child(help)

	_auto_arrange_dialog = ConfirmationDialog.new()
	_auto_arrange_dialog.title = "AUTO ARRANGE"
	_auto_arrange_dialog.dialog_text = "Replace the current layout and repack every item?"
	_auto_arrange_dialog.confirmed.connect(_auto_arrange)
	root.add_child(_auto_arrange_dialog)

func _make_button(label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0.0, 28.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	return button

func _refresh() -> void:
	_refresh_grid()
	_refresh_tray()
	_refresh_equipped()
	_refresh_details()
	var metrics: Dictionary = grid_model.get_metrics()
	_status_label.text = "USED %d/%d | ITEMS %d | UNPLACED %d" % [
		int(metrics.get("occupied_cells", 0)),
		int(metrics.get("capacity", 30)),
		int(metrics.get("item_count", 0)),
		int(metrics.get("unplaced_count", 0))
	]
	_status_label.add_theme_color_override("font_color", Color("a8bac3"))
	_close_button.disabled = grid_model.has_unplaced_items()

func _refresh_grid() -> void:
	_clear_container(_grid_container)
	var occupied: Dictionary = grid_model.get_occupied_map()
	var connections: Dictionary = grid_model.evaluate_connections()
	for y in range(BackpackGrid.HEIGHT):
		for x in range(BackpackGrid.WIDTH):
			var cell_position := Vector2i(x, y)
			var cell := BackpackCell.new()
			cell.grid_cell = cell_position
			cell.custom_minimum_size = Vector2(52.0, 52.0)
			cell.item_id = StringName(occupied.get(cell_position, &""))
			cell.text = _cell_text(cell_position, cell.item_id, connections)
			cell.tooltip_text = _cell_tooltip(cell_position, cell.item_id, connections)
			cell.add_theme_font_size_override("font_size", 12)
			if cell.item_id == _selected_id and _selected_id != &"":
				cell.add_theme_color_override("font_color", Color("ffbd55"))
			cell.cell_pressed.connect(_on_cell_pressed)
			cell.drop_requested.connect(_on_drop_requested)
			cell.rotate_requested.connect(_on_rotate_requested)
			_grid_container.add_child(cell)

func _refresh_tray() -> void:
	_clear_container(_tray_container)
	var unplaced: Array[StringName] = grid_model.get_unplaced_ids()
	if unplaced.is_empty():
		var empty := Label.new()
		empty.text = "ALL ITEMS PLACED"
		empty.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
		_tray_container.add_child(empty)
		return
	for item_id in unplaced:
		var item: BackpackItemData = grid_model.get_item(item_id)
		if item == null or item.part == null:
			continue
		var button := Button.new()
		button.text = "%s | %d CELLS" % [item.part.display_name, item.cell_count()]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_item.bind(item_id))
		button.gui_input.connect(_on_tray_input.bind(item_id))
		if item_id == _selected_id:
			button.add_theme_color_override("font_color", Color("ffbd55"))
		_tray_container.add_child(button)

func _refresh_equipped() -> void:
	var weapon := _weapon()
	if weapon == null:
		_equipped_label.text = "NO ACTIVE WEAPON"
		return
	var snapshot: Dictionary = weapon.get_build_snapshot()
	var part_names: PackedStringArray = snapshot.get("part_names", PackedStringArray())
	_equipped_label.text = "%s\n%s\nPOWER %d/%d | WEIGHT %.1f/%.1f" % [
		weapon.get_display_name(),
		" / ".join(part_names),
		int(snapshot.get("power_cost", 0)),
		int(snapshot.get("max_power", 0)),
		float(snapshot.get("weight", 0.0)),
		float(snapshot.get("max_weight", 0.0))
	]

func _refresh_details() -> void:
	var item: BackpackItemData = grid_model.get_item(_selected_id)
	if item == null or item.part == null:
		_details_label.text = "SELECT AN ITEM\n\nMove a placed part by dragging it or by selecting an empty grid cell."
		return
	var placement: Dictionary = grid_model.get_placement(_selected_id)
	var rotation := int(placement.get("rotation", _pending_rotations.get(_selected_id, 0)))
	var active: Dictionary = grid_model.evaluate_connections()
	var active_connectors: PackedStringArray = active.get(_selected_id, PackedStringArray())
	_details_label.text = "%s\n%s | %s\nPOWER %d | WEIGHT %.1f\nSHAPE %d CELLS | ROTATION %d DEG\nCONNECTORS: %s\nACTIVE: %s\nTAGS: %s" % [
		item.part.display_name,
		_slot_name(item.part.slot),
		"PLACED" if not placement.is_empty() else "UNPLACED",
		item.part.power_cost,
		item.part.weight,
		item.cell_count(),
		rotation * 90,
		", ".join(item.connector_types),
		", ".join(active_connectors) if not active_connectors.is_empty() else "NONE",
		", ".join(item.part.tags)
	]

func _cell_text(cell_position: Vector2i, item_id: StringName, connections: Dictionary) -> String:
	var terminal := _terminal_symbol(cell_position)
	if item_id == &"":
		return terminal
	var item: BackpackItemData = grid_model.get_item(item_id)
	if item == null or item.part == null:
		return "?"
	var placement: Dictionary = grid_model.get_placement(item_id)
	var origin: Vector2i = placement.get("origin", cell_position)
	var connected := connections.has(item_id)
	if cell_position == origin:
		return "%s%s" % ["*" if connected else "", item.part.display_name.left(7)]
	return "*" if connected else "."

func _cell_tooltip(cell_position: Vector2i, item_id: StringName, connections: Dictionary) -> String:
	if item_id == &"":
		return "EMPTY %s" % _terminal_name(cell_position)
	var item: BackpackItemData = grid_model.get_item(item_id)
	if item == null or item.part == null:
		return "UNKNOWN ITEM"
	var active_connectors: PackedStringArray = connections.get(item_id, PackedStringArray())
	return "%s\n%s\nACTIVE %s" % [
		item.part.display_name,
		", ".join(item.connector_types),
		", ".join(active_connectors) if not active_connectors.is_empty() else "NONE"
	]

func _terminal_symbol(cell: Vector2i) -> String:
	for connector in BackpackGrid.TERMINAL_CELLS:
		if BackpackGrid.TERMINAL_CELLS[connector] == cell:
			match String(connector):
				"power": return "P"
				"ammo": return "A"
				"cooling": return "C"
				"signal": return "S"
	return ""

func _terminal_name(cell: Vector2i) -> String:
	for connector in BackpackGrid.TERMINAL_CELLS:
		if BackpackGrid.TERMINAL_CELLS[connector] == cell:
			return "| %s TERMINAL" % String(connector).to_upper()
	return ""

func _on_cell_pressed(cell: Vector2i) -> void:
	var occupying_id := grid_model.get_item_at(cell)
	if occupying_id != &"":
		_select_item(occupying_id)
		return
	if _selected_id == &"":
		return
	if grid_model.place_item(_selected_id, cell, _selected_rotation()):
		_pending_rotations.erase(_selected_id)
		_refresh()
	else:
		_show_message("ITEM DOES NOT FIT AT THAT POSITION")

func _on_drop_requested(item_id: StringName, cell: Vector2i) -> void:
	_select_item(item_id)
	if grid_model.place_item(item_id, cell, _selected_rotation()):
		_pending_rotations.erase(item_id)
		_refresh()
	else:
		_show_message("PLACEMENT OVERLAPS OR EXCEEDS THE GRID")

func _on_rotate_requested(item_id: StringName) -> void:
	_select_item(item_id)
	_rotate_selected()

func _on_tray_input(event: InputEvent, item_id: StringName) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and mouse_event.double_click:
			_select_item(item_id)
			_auto_place_selected()

func _select_item(item_id: StringName) -> void:
	if grid_model.get_item(item_id) == null:
		return
	_selected_id = item_id
	_refresh()

func _selected_rotation() -> int:
	var placement: Dictionary = grid_model.get_placement(_selected_id)
	if not placement.is_empty():
		return int(placement.get("rotation", 0))
	return int(_pending_rotations.get(_selected_id, 0))

func _rotate_selected() -> void:
	if _selected_id == &"":
		return
	if grid_model.get_placement(_selected_id).is_empty():
		_pending_rotations[_selected_id] = posmod(_selected_rotation() + 1, 4)
		_refresh()
		return
	if not grid_model.rotate_item(_selected_id):
		_show_message("ITEM CANNOT ROTATE AT ITS CURRENT POSITION")
	else:
		_refresh()

func _unplace_selected() -> void:
	if _selected_id == &"":
		return
	var placement: Dictionary = grid_model.get_placement(_selected_id)
	if placement.is_empty():
		return
	_pending_rotations[_selected_id] = int(placement.get("rotation", 0))
	grid_model.unplace_item(_selected_id)
	_refresh()

func _auto_place_selected() -> void:
	if _selected_id == &"":
		return
	if grid_model.auto_place(_selected_id, _selected_rotation()):
		_pending_rotations.erase(_selected_id)
		_refresh()
	else:
		_show_message("NO SPACE AVAILABLE FOR AUTO PLACEMENT")

func _equip_selected() -> void:
	if _selected_id == &"" or grid_model.get_item(_selected_id) == null:
		return
	equip_requested.emit(_selected_id)
	_selected_id = &""
	call_deferred("_refresh")

func _request_auto_arrange() -> void:
	_auto_arrange_dialog.popup_centered(Vector2i(420, 150))

func _auto_arrange() -> void:
	if grid_model.auto_arrange():
		_refresh()
	else:
		_show_message("AUTO ARRANGE FAILED; PREVIOUS LAYOUT RESTORED")

func _restore_previous_state() -> void:
	grid_model.restore_snapshot(_baseline_snapshot)
	var restored_parts: Array[WeaponPartData] = []
	for part in _baseline_parts:
		restored_parts.append(part.duplicate_part())
	loadout_restore_requested.emit(restored_parts)
	_selected_id = &""
	_pending_rotations.clear()
	_refresh()
	_show_message("RESTORED THE STATE FROM WHEN THE BACKPACK OPENED")

func _try_close() -> void:
	if grid_model.has_unplaced_items():
		_show_message("PLACE OR EQUIP EVERY UNPLACED ITEM BEFORE CLOSING")
		return
	queue_free()

func _capture_baseline_parts() -> void:
	_baseline_parts.clear()
	var weapon := _weapon()
	if weapon == null:
		return
	for part in weapon.equipped_parts:
		if part != null:
			_baseline_parts.append(part.duplicate_part())

func _weapon() -> PrototypeWeapon:
	if player == null:
		return null
	return player.get("weapon") as PrototypeWeapon

func _slot_name(slot: WeaponPartData.Slot) -> String:
	match slot:
		WeaponPartData.Slot.BARREL:
			return "BARREL"
		WeaponPartData.Slot.MAGAZINE:
			return "MAGAZINE"
		WeaponPartData.Slot.CORE:
			return "CORE"
	return "UNKNOWN"

func _show_message(message: String) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Color("ff8b72"))

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
	closed.emit()
