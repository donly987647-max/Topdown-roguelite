class_name RewardChoicePanel
extends Control

signal reward_selected(index: int)

var view_model := RewardChoiceViewModel.new()
var choices: Array[RewardOffer] = []

func present(new_choices: Array[RewardOffer]) -> void:
	choices = new_choices.duplicate()
	_rebuild()
	visible = not choices.is_empty()
	if visible:
		call_deferred("focus_first_choice")

func clear() -> void:
	choices.clear()
	for child in get_children():
		child.queue_free()
	visible = false

func focus_first_choice() -> void:
	for child in get_children():
		if child is HBoxContainer:
			for card in child.get_children():
				if card is Button and not (card as Button).disabled:
					(card as Button).grab_focus()
					return

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	add_child(row)
	for data in view_model.build(choices):
		var card := Button.new()
		card.focus_mode = Control.FOCUS_ALL
		card.custom_minimum_size = Vector2(270.0, 190.0)
		card.text = _card_text(data)
		var index := int(data.get("index", -1))
		card.pressed.connect(func(): reward_selected.emit(index))
		row.add_child(card)

func _card_text(data: Dictionary) -> String:
	var title := String(data.get("title", "Reward"))
	var rarity := String(data.get("rarity", "common")).capitalize()
	var description := String(data.get("description", ""))
	var category := String(data.get("category", "item")).capitalize()
	var text := "%s\n[%s · %s]" % [title, rarity, category]
	if not description.is_empty():
		text += "\n\n%s" % description
	return text
