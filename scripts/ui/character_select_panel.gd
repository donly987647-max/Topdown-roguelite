class_name CharacterSelectPanel
extends Control

signal character_selected(character_id: StringName)

var catalog := CharacterCatalog.new()
var unlocks: Dictionary = {}

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var cards: HBoxContainer = $Panel/Margin/VBox/Cards
@onready var detail_label: Label = $Panel/Margin/VBox/Details
@onready var start_button: Button = $Panel/Margin/VBox/Start

var _selected_id: StringName = &""

func _ready() -> void:
	start_button.disabled = true
	start_button.pressed.connect(_confirm_selection)
	visibility_changed.connect(_on_visibility_changed)
	rebuild()

func set_unlocks(value: Dictionary) -> void:
	unlocks = value.duplicate(true)
	if is_node_ready(): rebuild()

func rebuild() -> void:
	for child in cards.get_children(): child.queue_free()
	_selected_id = &""
	start_button.disabled = true
	detail_label.text = "캐릭터를 선택하세요."
	for character in catalog.selectable(unlocks):
		var button := Button.new()
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(250, 160)
		button.text = "%s\nHP %.0f  SPD %d%%\n%s" % [character.display_name, character.max_health, int(round(character.move_speed_multiplier * 100.0)), _frame_title(character.starting_frame_id)]
		button.tooltip_text = character.role
		button.pressed.connect(func(): _select(character.id))
		cards.add_child(button)
	if visible:
		call_deferred("focus_first_card")

func focus_first_card() -> void:
	for child in cards.get_children():
		if child is Button:
			(child as Button).grab_focus()
			return

func _select(id: StringName) -> void:
	var character := catalog.get_by_id(id)
	if character == null: return
	_selected_id = id
	start_button.disabled = false
	detail_label.text = "%s\n%s\n\n패시브 — %s\n%s\n\n액티브 — %s\n%s\n\n플레이: %s" % [
		character.display_name, character.role, String(character.passive_id).replace("_", " ").capitalize(), character.passive_description,
		String(character.active_id).replace("_", " ").capitalize(), character.active_description, ", ".join(Array(character.playstyle))]
	start_button.grab_focus()

func _confirm_selection() -> void:
	if _selected_id == &"": return
	visible = false
	character_selected.emit(_selected_id)

func _frame_title(id: StringName) -> String:
	return "시작 무기: %s" % String(id).replace("_", " ").capitalize()

func _on_visibility_changed() -> void:
	if visible:
		call_deferred("focus_first_card")
