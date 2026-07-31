class_name BackpackPanel
extends CanvasLayer

signal equip_requested(item_id: StringName)
signal loadout_restore_requested(parts: Array[WeaponPartData])
signal closed

var grid_model: BackpackGrid
var player: PlayerController
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

func configure(backpack: BackpackGrid, owner_player: PlayerController) -> void:
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
	backdrop.color = Color(0.005, 0.012, 0.018, 0.93)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-455.0, -245.0)
	panel.size = Vector2(910.0, 490.0)
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)

	var title_row := HBoxContainer.new()
	outer.add_child(title_row)
	var title := Label.new()
	title.text = "LOADOUT GRID  ·  BACKPACK 6×5"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("ffbd55"))
	title_row.add_child(title)
	_close_button = Button.new()
	_close_button.text = "CLOSE [I]"
	_close_button.pressed.connect(_try_close)
	title_row.add_child(_close_button)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	outer.add_child(content)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(390.0, 365.0)
	left.add_theme_constant_override("separation", 8)
	content.add_child(left)

	var terminal_hint := Label.new()
	terminal_hint.text = "P 전력  ·  A 탄약  ·  C 냉각  ·  S 신호"
	terminal_hint.add_theme_font_size_override("font_size", 13)
	terminal_hint.add_theme_color_override("font_color", Color("8bd8ff"))
	left.add_child(terminal_hint)

	_grid_container = GridContainer.new()
	_grid_container.columns = BackpackGrid.WIDTH
	_grid_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_container.add_theme_constant_override("h_separation", 4)
	_grid_container.add_theme_constant_override("v_separation", 4)
	left.add_child(_grid_container)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color("a8bac3"))
	left.add_child(_status_label)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	content.add_child(right)

	_equipped_label = Label.new()
	_equipped_label.custom_minimum_size = Vector2(0.0, 78.0)
	_equipped_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equipped_label.add_theme_font_size_override("font_size", 14)
	_equipped_label.add_theme_color_override("font_color", Color("e8eef1"))
	right.add_child(_equipped_label)

	var tray_title := Label.new()
	tray_title.text = "UNPLACED ITEMS"
	tray_title.add_theme_font_size_override("font_size", 14)
	tray_title.add_theme_color_override("font_color", Color("ff8b72"))
	right.add_child(tray_title)

	var tray_scroll := ScrollContainer.new()
	tray_scroll.custom_minimum_size = Vector2(0.0, 76.0)
	tray_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(tray_scroll)
	_tray_container = VBoxContainer.new()
	_tray_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tray_scroll.add_child(_tray_container)

	_details_label = Label.new()
	_details_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_label.add_theme_font_size_override("font_size", 14)
	_details_label.add_theme_color_override("font_color", Color("c9d7dd"))
	right.add_child(_details_label)

	var controls_a := HBoxContainer.new()
	controls_a.add_theme_constant_override("separation", 6)
	right.add_child(controls_a)
	controls_a.add_child(_make_button("ROTATE [R]", _rotate_selected))
	controls_a.add_child(_make_button("UNPLACE", _unplace_selected))
	controls_a.add_child(_make_button("AUTO PLACE", _auto_place_selected))
	controls_a.add_child(_make_button("EQUIP", _equip_selected))

	var controls_b := HBoxContainer.new()
	controls_b.add_theme_constant_override("separation", 6)
	right.add_child(controls_b)
	controls_b.add_child(_make_button("AUTO ARRANGE", _request_auto_arrange))
	controls_b.add_child(_make_button("RESTORE", _restore_previous_state))

	var help := Label.new()
	help.text = "드래그 이동  ·  우클릭 회전  ·  더블클릭 자동 배치  ·  빈 칸 클릭 배치"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.58))
	outer.add_child(help)

	_auto_arrange_dialog = ConfirmationDialog.new()
	_auto_arrange_dialog.title = "자동 정렬"
	_auto_arrange_dialog.dialog_text = "현재 배치를 덮어쓰고 모든 아이템을 다시 배치합니다."
	_auto_arrange_dialog.confirmed.connect(_auto_arrange)
	root.add_child(_auto_arrange_dialog)

func _make_button(label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	return button

func _refresh() -> void:
	_refresh_grid()
	_refresh_tray()
	_refresh_equipped()
	_refresh_details()
	var metrics := grid_model.get_metrics()
	_status_label.text = "USED %d/%d  ·  ITEMS %d  ·  UNPLACED %d" % [
		int(metrics.get("occupied_cells", 0)),
		int(metrics.get("capacity", 30)),
		int(metrics.get("item_count", 0)),
		int(metrics.get("unplaced_count", 0))
	]
	_close_button.disabled = grid_model.has_unplaced_items()

func _refresh_grid() -> void:
	_clear_container(_grid_container)
	var occupied := grid_model.get_occupied_map()
	var connections := grid_model.evaluate_connections()
	for y in range(BackpackGrid.HEIGHT):
		for x in range(BackpackGrid.WIDTH):
			var cell_position := Vector2i(x, y)
			var cell := BackpackCell.new()
			cell.grid_cell = cell_position
			cell.custom_minimum_size = Vector2(58.0, 58.0)
			cell.item_id = StringName(occupied.get(cell_position, &""))
			cell.text = _cell_text(cell_position, cell.item_id, connections)
			cell.tooltip_text = _cell_tooltip(cell_position, cell.item_id, connections)
			if cell.item_id == _selected_id and _selected_id != &"":
				cell.add_theme_color_override("font_color", Color("ffbd55"))
			cell.cell_pressed.connect(_on_cell_pressed)
			cell.drop_requested.connect(_on_drop_requested)
			cell.rotate_requested.connect(_on_rotate_requested)
			_grid_container.add_child(cell)

func _refresh_tray() -> void:
	_clear_container(_tray_container)
	var unplaced := grid_model.get_unplaced_ids()
	if unplaced.is_empty():
		var empty := Label.new()
		empty.text = "모든 아이템이 배치됨"
		empty.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
		_tray_container.add_child(empty)
		return
	for item_id in unplaced:
		var item := grid_model.get_item(item_id)
		if item == null or item.part == null:
			continue
		var button := Button.new()
		button.text = "%s  ·  %d칸" % [item.part.display_name, item.cell_count()]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_item.bind(item_id))
		button.gui_input.connect(_on_tray_input.bind(item_id))
		if item_id == _selected_id:
			button.add_theme_color_override("font_color", Color("ffbd55"))
		_tray_container.add_child(button)

func _refresh_equipped() -> void:
	if player == null or player.weapon == null:
		_equipped_label.text = "NO ACTIVE WEAPON"
		return
	var snapshot := player.weapon.get_build_snapshot()
	var part_names: PackedStringArray = snapshot.get("part_names", PackedStringArray())
	_equipped_label.text = "%s\n%s\nPOWER %d/%d  ·  WEIGHT %.1f/%.1f" % [
		player.weapon.get_display_name(),
		" / ".join(part_names),
		int(snapshot.get("power_cost", 0)),
		int(snapshot.get("max_power", 0)),
		float(snapshot.get("weight", 0.0)),
		float(snapshot.get("max_weight", 0.0))
	]

func _refresh_details() -> void:
	var item := grid_model.get_item(_selected_id)
	if item == null or item.part == null:
		_details_label.text = "아이템을 선택하십시오.\n\n배치된 부품은 드래그하거나 빈 칸을 눌러 이동할 수 있습니다."
		return
	var placement := grid_model.get_placement(_selected_id)
	var rotation := int(placement.get("rotation", _pending_rotations.get(_selected_id, 0)))
	var active: Dictionary = grid_model.evaluate_connections()
	var active_connectors: PackedStringArray = active.get(_selected_id, PackedStringArray())
	_details_label.text = "%s\n%s  ·  %s\n\nPOWER %d  ·  WEIGHT %.1f\nSHAPE %d CELLS  ·  ROTATION %d°\nCONNECTORS: %s\nACTIVE: %s\n\nTAGS: %s" % [
		item.part.display_name,
		_slot_name(item.part.slot),
		"PLACED" if placement.size() > 0 else "UNPLACED",
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
	var item := grid_model.get_item(item_id)
	if item == null or item.part == null:
		return "?"
	var placement := grid_model.get_placement(item_id)
	var origin: Vector2i = placement.get("origin", cell_position)
	var connected := connections.has(item_id)
	if cell_position == origin:
		return "%s%s" % ["● " if connected else "", item.part.display_name.left(9)]
	return "●" if connected else "·"

func _cell_tooltip(cell_position: Vector2i, item_id: StringName, connections: Dictionary) -> String:
	if item_id == &"":
		return "EMPTY %s" % _terminal_name(cell_position)
	var item := grid_model.get_item(item_id)
	if item == null or item.part == null:
		return "UNKNOWN ITEM"
	var active: PackedStringArray = connections.get(item_id, PackedStringArray())
	return "%s\n%s\nACTIVE %s" % [item.part.display_name, ", ".join(item.connector_types), ", ".join(active) if not active.is_empty() else "NONE"]

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
			return "· %s TERMINAL" % String(connector).to_upper()
	return ""

func _on_cell_pressed(cell: Vector2i) -> void:
	var occupying_id := grid_model.get_item_at(cell)
	if occupying_id != &"":
		_select_item(occupying_id)
		return
	if _selected_id == &"":
		return
	var rotation := _selected_rotation()
	if grid_model.place_item(_selected_id, cell, rotation):
		_pending_rotations.erase(_selected_id)
		_refresh()
	else:
		_show_message("해당 위치에는 배치할 수 없습니다.")

func _on_drop_requested(item_id: StringName, cell: Vector2i) -> void:
	_select_item(item_id)
	if grid_model.place_item(item_id, cell, _selected_rotation()):
		_pending_rotations.erase(item_id)
		_refresh()
	else:
		_show_message("겹치거나 가방 범위를 벗어났습니다.")

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
	var placement := grid_model.get_placement(_selected_id)
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
		_show_message("현재 위치에서는 회전할 수 없습니다.")
	_refresh()

func _unplace_selected() -> void:
	if _selected_id == &"":
		return
	var placement := grid_model.get_placement(_selected_id)
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
	else:
		_show_message("자동 배치할 공간이 없습니다.")
	_refresh()

func _equip_selected() -> void:
	if _selected_id == &"" or grid_model.get_item(_selected_id) == null:
		return
	equip_requested.emit(_selected_id)
	_selected_id = &""
	call_deferred("_refresh")

func _request_auto_arrange() -> void:
	_auto_arrange_dialog.popup_centered(Vector2i(460, 160))

func _auto_arrange() -> void:
	if not grid_model.auto_arrange():
		_show_message("모든 아이템을 배치할 수 없어 이전 배치를 유지했습니다.")
	_refresh()

func _restore_previous_state() -> void:
	grid_model.restore_snapshot(_baseline_snapshot)
	var restored_parts: Array[WeaponPartData] = []
	for part in _baseline_parts:
		restored_parts.append(part.duplicate_part())
	loadout_restore_requested.emit(restored_parts)
	_selected_id = &""
	_pending_rotations.clear()
	_refresh()
	_show_message("인벤토리를 열었을 때의 상태로 복원했습니다.")

func _try_close() -> void:
	if grid_model.has_unplaced_items():
		_show_message("미배치 아이템을 모두 배치하거나 장착해야 합니다.")
		return
	queue_free()

func _capture_baseline_parts() -> void:
	_baseline_parts.clear()
	if player == null or player.weapon == null:
		return
	for part in player.weapon.equipped_parts:
		if part != null:
			_baseline_parts.append(part.duplicate_part())

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
