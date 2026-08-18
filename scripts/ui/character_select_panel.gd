class_name CharacterSelectPanel
extends Control

signal character_selected(character_id: StringName)

var catalog := CharacterCatalog.new()
var unlocks: Dictionary = {}

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var cards: GridContainer = $Panel/Margin/VBox/Cards
@onready var detail_label: Label = $Panel/Margin/VBox/Details
@onready var start_button: Button = $Panel/Margin/VBox/Start

var _selected_id: StringName = &""

func _ready() -> void:
	start_button.disabled = true
	start_button.pressed.connect(_confirm_selection)
	visibility_changed.connect(_on_visibility_changed)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	rebuild()

func set_unlocks(value: Dictionary) -> void:
	unlocks = value.duplicate(true)
	if is_node_ready():
		rebuild()

func rebuild() -> void:
	for child in cards.get_children():
		child.queue_free()
	_selected_id = &""
	start_button.disabled = true
	detail_label.text = "캐릭터를 선택하세요."
	var size := get_viewport_rect().size
	var portrait := size.y > size.x
	var card_width := clampf((size.x - 120.0) / (2.0 if portrait else 4.0) - 16.0, 150.0, 280.0)
	var card_height := clampf(minf(size.x, size.y) * 0.20, 130.0, 190.0)
	for character in catalog.selectable(unlocks):
		var button := Button.new()
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(card_width, card_height)
		button.add_theme_font_size_override("font_size", int(clampf(minf(size.x, size.y) * 0.021, 14.0, 20.0)))
		button.text = "%s\nHP %.0f · SPD %d%%\n%s" % [character.display_name, character.max_health, int(round(character.move_speed_multiplier * 100.0)), _frame_title(character.starting_frame_id)]
		button.tooltip_text = character.role
		button.pressed.connect(func(): _select(character.id))
		cards.add_child(button)
	if visible:
		call_deferred("focus_first_card")

func _apply_responsive_layout() -> void:
	if panel == null:
		return
	var size := get_viewport_rect().size
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var portrait := size.y > size.x
	var margin := clampf(minf(size.x, size.y) * 0.025, 18.0, 34.0)
	panel.position = Vector2(margin, margin)
	panel.size = size - Vector2.ONE * margin * 2.0
	cards.columns = 2 if portrait else 4
	title_label.add_theme_font_size_override("font_size", int(clampf(minf(size.x, size.y) * 0.04, 24.0, 38.0)))
	detail_label.custom_minimum_size.y = clampf(size.y * (0.24 if portrait else 0.20), 160.0, 260.0)
	detail_label.add_theme_font_size_override("font_size", int(clampf(minf(size.x, size.y) * 0.021, 14.0, 19.0)))
	start_button.custom_minimum_size.y = clampf(minf(size.x, size.y) * 0.085, 62.0, 86.0)
	if cards.get_child_count() > 0:
		rebuild()

func focus_first_card() -> void:
	for child in cards.get_children():
		if child is Button:
			(child as Button).grab_focus()
			return

func _select(id: StringName) -> void:
	var character := catalog.get_by_id(id)
	if character == null:
		return
	_selected_id = id
	start_button.disabled = false
	detail_label.text = "%s · %s\n패시브 — %s: %s\n액티브 — %s: %s\n플레이 — %s" % [
		character.display_name, character.role,
		String(character.passive_id).replace("_", " ").capitalize(), character.passive_description,
		String(character.active_id).replace("_", " ").capitalize(), character.active_description,
		", ".join(Array(character.playstyle))]

func _confirm_selection() -> void:
	if _selected_id == &"":
		return
	visible = false
	character_selected.emit(_selected_id)

func _frame_title(id: StringName) -> String:
	return String(id).replace("_", " ").capitalize()

func _on_visibility_changed() -> void:
	if visible:
		_apply_responsive_layout()
		call_deferred("focus_first_card")
