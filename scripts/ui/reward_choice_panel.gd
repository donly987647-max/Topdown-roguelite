class_name RewardChoicePanel
extends Control

signal reward_selected(index: int)
signal reward_focus_changed(index: int)

var view_model := RewardChoiceViewModel.new()
var choices: Array[RewardOffer] = []
var _focused_index := 0

func present(new_choices: Array[RewardOffer]) -> void:
	choices = new_choices.duplicate()
	_focused_index = 0
	_rebuild()
	visible = not choices.is_empty()
	if visible:
		call_deferred("focus_first_choice")

func clear() -> void:
	choices.clear()
	_focused_index = 0
	for child in get_children():
		child.queue_free()
	visible = false

func focus_first_choice() -> void:
	focus_choice(0)

func focus_choice(index: int) -> void:
	if index < 0 or index >= choices.size():
		return
	for child in get_children():
		if child is not HBoxContainer:
			continue
		var cards := child.get_children()
		if index >= cards.size():
			return
		var card := cards[index] as Button
		if card != null and not card.disabled:
			card.grab_focus()
			_set_focused_index(index)
		return

func focused_index() -> int:
	return _focused_index

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
		card.focus_entered.connect(func(): _set_focused_index(index))
		card.mouse_entered.connect(func(): _set_focused_index(index))
		card.pressed.connect(func(): reward_selected.emit(index))
		row.add_child(card)

func _set_focused_index(index: int) -> void:
	if index < 0 or index >= choices.size():
		return
	if _focused_index == index:
		return
	_focused_index = index
	reward_focus_changed.emit(index)

func _card_text(data: Dictionary) -> String:
	var title := String(data.get("title", "Reward"))
	var rarity := String(data.get("rarity", "common")).capitalize()
	var description := String(data.get("description", ""))
	var category := String(data.get("category", "item")).capitalize()
	var text := "%s\n[%s · %s]" % [title, rarity, category]
	if not description.is_empty():
		text += "\n\n%s" % description
	return text
