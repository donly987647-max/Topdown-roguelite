class_name WeaponRewardPanel
extends CanvasLayer

signal part_selected(part: WeaponPartData)

var options: Array[WeaponPartData] = []
var _selection_locked := false

func configure(reward_options: Array[WeaponPartData]) -> void:
	options.clear()
	for part in reward_options:
		if part != null:
			options.append(part.duplicate_part())

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if _selection_locked or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		match key.physical_keycode:
			KEY_1:
				_select_option(0)
			KEY_2:
				_select_option(1)
			KEY_3:
				_select_option(2)

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.02, 0.03, 0.86)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-370.0, -190.0)
	panel.size = Vector2(740.0, 380.0)
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title := Label.new()
	title.text = "ROOM CLEAR  ·  SELECT WEAPON PART"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("ffbd55"))
	column.add_child(title)

	var hint := Label.new()
	hint.text = "1 / 2 / 3 또는 버튼 터치  ·  같은 슬롯의 기존 부품을 교체합니다"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("a8bac3"))
	column.add_child(hint)

	var cards := HBoxContainer.new()
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 12)
	column.add_child(cards)

	for index in options.size():
		cards.add_child(_make_card(index, options[index]))

func _make_card(index: int, part: WeaponPartData) -> Button:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(210.0, 230.0)
	button.text = "%d\n%s\n\n%s\n\nPOWER %d   WEIGHT %.1f" % [
		index + 1,
		part.display_name,
		_describe_part(part.part_id),
		part.power_cost,
		part.weight
	]
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(_select_option.bind(index))
	return button

func _select_option(index: int) -> void:
	if _selection_locked or index < 0 or index >= options.size():
		return
	_selection_locked = true
	part_selected.emit(options[index].duplicate_part())
	queue_free()

func _describe_part(part_id: StringName) -> String:
	match part_id:
		&"precision_barrel":
			return "탄 퍼짐 -35%\n탄속 +15%\n발사 속도 -8%"
		&"spread_barrel":
			return "발사체 +2\n개별 피해 -25%\n탄 퍼짐 증가"
		&"piercing_barrel":
			return "관통 +2\n관통 후 피해 -15%"
		&"ricochet_barrel":
			return "벽 도탄 +2\n도탄 후 피해 +20%"
		&"extended_magazine":
			return "탄창 +60%\n재장전 시간 +25%"
		&"lightweight_magazine":
			return "탄창 -25%\n재장전 시간 -35%"
		&"compressed_magazine":
			return "탄약 소비 2배\n피해 +70%\n탄환 크기 증가"
		&"reverse_magazine":
			return "첫 탄환 최대 피해\n후속 탄환마다 -3%"
		&"impact_core":
			return "넉백과 경직 증가\n벽 충돌 빌드용"
		&"photon_core":
			return "탄속과 치명타 증가\n피해 소폭 감소"
		&"clone_core":
			return "일정 확률로 탄환 복제\n복제 탄환 피해 감소"
		&"flame_core":
			return "화상 축적\n지속 피해 빌드용"
		_:
			return "프로토타입 무기 부품"

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
