class_name BackpackCell
extends Button

signal cell_pressed(cell: Vector2i)
signal drop_requested(item_id: StringName, cell: Vector2i)
signal rotate_requested(item_id: StringName)

var grid_cell := Vector2i.ZERO
var item_id: StringName = &""

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	cell_pressed.emit(grid_cell)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id == &"":
		return null
	var preview := Label.new()
	preview.text = text
	preview.custom_minimum_size = Vector2(96.0, 42.0)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_theme_font_size_override("font_size", 13)
	set_drag_preview(preview)
	return {"backpack_item_id": String(item_id)}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("backpack_item_id")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(Vector2.ZERO, data):
		return
	var dictionary := data as Dictionary
	drop_requested.emit(StringName(dictionary.get("backpack_item_id", "")), grid_cell)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed and item_id != &"":
			rotate_requested.emit(item_id)
			accept_event()
