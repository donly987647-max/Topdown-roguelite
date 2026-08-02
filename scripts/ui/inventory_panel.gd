class_name InventoryPanel
extends Control

signal modal_state_changed(open: bool)

const GRID_COLUMNS := 6
const GRID_ROWS := 5

var bootstrap: Zone1RunBootstrap
var runtime: RunInventoryRuntime
var _cell_buttons: Dictionary = {}
var _selected_record_index := -1
var _auto_sort_confirmation := false

@onready var grid: GridContainer = $Dim/Panel/Margin/Root/Content/Left/Grid
@onready var stash: ItemList = $Dim/Panel/Margin/Root/Content/Left/Stash
@onready var frame_button: Button = $Dim/Panel/Margin/Root/Content/Right/Slots/Frame
@onready var barrel_button: Button = $Dim/Panel/Margin/Root/Content/Right/Slots/Barrel
@onready var magazine_button: Button = $Dim/Panel/Margin/Root/Content/Right/Slots/Magazine
@onready var core_button: Button = $Dim/Panel/Margin/Root/Content/Right/Slots/Core
@onready var details: RichTextLabel = $Dim/Panel/Margin/Root/Content/Right/Details
@onready var synergy: Label = $Dim/Panel/Margin/Root/Content/Right/Synergy
@onready var message: Label = $Dim/Panel/Margin/Root/Content/Right/Message
@onready var rotate_button: Button = $Dim/Panel/Margin/Root/Content/Right/Actions/Rotate
@onready var quick_move_button: Button = $Dim/Panel/Margin/Root/Content/Right/Actions/QuickMove
@onready var auto_sort_button: Button = $Dim/Panel/Margin/Root/Content/Right/Actions/AutoSort
@onready var undo_button: Button = $Dim/Panel/Margin/Root/Content/Right/Actions/Undo
@onready var close_button: Button = $Dim/Panel/Margin/Root/Header/Close

func _ready() -> void:
	visible = false
	_build_grid()
	stash.item_selected.connect(_on_stash_selected)
	stash.item_activated.connect(_on_stash_activated)
	stash.item_clicked.connect(_on_stash_clicked)
	frame_button.pressed.connect(_cycle_slot.bind(&"frame"))
	barrel_button.pressed.connect(_cycle_slot.bind(&"barrel"))
	magazine_button.pressed.connect(_cycle_slot.bind(&"magazine"))
	core_button.pressed.connect(_cycle_slot.bind(&"core"))
	rotate_button.pressed.connect(_rotate_selected)
	quick_move_button.pressed.connect(_quick_move_selected)
	auto_sort_button.pressed.connect(_request_auto_sort)
	undo_button.pressed.connect(_undo)
	close_button.pressed.connect(close)

func configure(run_bootstrap: Zone1RunBootstrap) -> bool:
	bootstrap = run_bootstrap
	runtime = bootstrap.inventory if bootstrap != null else null
	if runtime == null:
		return false
	if not runtime.inventory_changed.is_connected(_refresh):
		runtime.inventory_changed.connect(_refresh)
	if not runtime.build_changed.is_connected(_on_build_changed):
		runtime.build_changed.connect(_on_build_changed)
	if not runtime.action_failed.is_connected(_on_action_failed):
		runtime.action_failed.connect(_on_action_failed)
	_refresh()
	return true

func open() -> void:
	if runtime == null:
		return
	visible = true
	_selected_record_index = -1
	message.text = "방 정리 완료 · 가방 편집 가능"
	_auto_sort_confirmation = false
	_refresh()
	modal_state_changed.emit(true)
	call_deferred("_focus_first_control")

func close() -> void:
	if not visible:
		return
	visible = false
	_auto_sort_confirmation = false
	modal_state_changed.emit(false)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var keyboard_toggle := event.is_action_pressed("toggle_inventory") and not (event is InputEventJoypadButton)
	if keyboard_toggle or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		_rotate_selected()
		get_viewport().set_input_as_handled()

func _build_grid() -> void:
	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			var cell := Vector2i(x, y)
			var button := Button.new()
			button.custom_minimum_size = Vector2(66.0, 66.0)
			button.focus_mode = Control.FOCUS_ALL
			button.text = "·"
			button.pressed.connect(_on_cell_pressed.bind(cell))
			button.gui_input.connect(_on_cell_gui_input.bind(cell))
			grid.add_child(button)
			_cell_buttons[cell] = button

func _refresh() -> void:
	if runtime == null or runtime.backpack == null:
		return
	for raw_cell in _cell_buttons.keys():
		var cell: Vector2i = raw_cell
		var button: Button = _cell_buttons[cell]
		var instance_id := runtime.backpack.grid.item_at(cell)
		if instance_id == &"":
			button.text = "·"
			button.tooltip_text = "빈 칸 (%d, %d)" % [cell.x + 1, cell.y + 1]
			button.modulate = Color.WHITE
			continue
		var entry := runtime.entry_for_instance(instance_id)
		var definition_id := StringName(entry.get("definition_id", ""))
		var data := runtime.display_data(definition_id)
		var payload: Dictionary = data.get("payload", {})
		var title := String(payload.get("display_name", String(definition_id)))
		button.text = title.left(2)
		button.tooltip_text = "%s\n%s" % [title, String(payload.get("description", ""))]
		button.modulate = Color(1.0, 0.86, 0.45) if int(entry.get("record_index", -1)) == _selected_record_index else Color.WHITE
	_rebuild_stash()
	_refresh_slots()
	_refresh_details()
	_refresh_synergy()
	undo_button.disabled = not runtime.can_undo()
	rotate_button.disabled = not _selection_is_placed()
	quick_move_button.disabled = not _has_selection()
	auto_sort_button.text = "정렬 확정" if _auto_sort_confirmation else "자동 정렬"

func _rebuild_stash() -> void:
	stash.clear()
	for entry in runtime.entries():
		if StringName(entry.get("instance_id", "")) != &"":
			continue
		var data := runtime.display_data(StringName(entry.get("definition_id", "")))
		var payload: Dictionary = data.get("payload", {})
		var item_index := stash.add_item("%s  [%s]" % [String(payload.get("display_name", entry.get("definition_id", "Item"))), String(entry.get("rarity", "common")).capitalize()])
		stash.set_item_metadata(item_index, int(entry.get("record_index", -1)))
		stash.set_item_tooltip(item_index, String(payload.get("description", "더블클릭: 자동 배치")))
	if stash.item_count == 0:
		var empty_index := stash.add_item("보관 중인 모듈 없음")
		stash.set_item_disabled(empty_index, true)

func _refresh_slots() -> void:
	var equipped := runtime.equipped_ids()
	_update_slot_button(frame_button, &"frame", StringName(equipped.get("frame", "")))
	_update_slot_button(barrel_button, &"barrel", StringName(equipped.get("barrel", "")))
	_update_slot_button(magazine_button, &"magazine", StringName(equipped.get("magazine", "")))
	_update_slot_button(core_button, &"core", StringName(equipped.get("core", "")))

func _update_slot_button(button: Button, category: StringName, id: StringName) -> void:
	var category_label := String(category).capitalize()
	var title := "비어 있음"
	if id != &"":
		var data := runtime.display_data(id)
		var payload: Dictionary = data.get("payload", {})
		title = String(payload.get("display_name", String(id)))
	var count := runtime.available_ids(category).size()
	button.text = "%s  ·  %s  (%d)" % [category_label, title, count]
	button.disabled = count <= 1

func _refresh_details() -> void:
	if not _has_selection():
		details.text = "[b]아이템 상세[/b]\n\n격자나 보관함의 아이템을 선택하세요.\n\n[i]기본 설명 → 수치/단자 → 빌드 태그 순으로 표시됩니다.[/i]"
		return
	var record: Dictionary = runtime.owned_rewards[_selected_record_index]
	var data := runtime.display_data(StringName(record.get("id", "")))
	var payload: Dictionary = data.get("payload", {})
	var tags_value: Variant = payload.get("tags", [])
	var tags: Array = tags_value if tags_value is Array else Array(tags_value)
	var definition := runtime.definition_for(StringName(record.get("id", "")))
	var detail_text := "[b]%s[/b]\n[%s · %s]\n\n%s" % [String(payload.get("display_name", record.get("id", "Item"))), String(record.get("rarity", "common")).capitalize(), String(record.get("category", "item")).capitalize(), String(payload.get("description", ""))]
	if definition != null:
		detail_text += "\n\n전력 %.0f / 공급 %.0f · 냉각 %.0f · 탄약 %.0f · 신호 %.0f" % [definition.power_draw, definition.power_supply, definition.cooling_supply, definition.ammo_supply, definition.signal_strength]
		detail_text += "\n상태: %s" % ["전력 연결 필요" if definition.requires_power else "수동/상시"]
	if not tags.is_empty():
		detail_text += "\n\n태그: %s" % ", ".join(tags)
	details.text = detail_text

func _refresh_synergy() -> void:
	var summary := runtime.synergy_summary()
	if summary.is_empty():
		synergy.text = ""
		return
	var links: Array = summary.get("connector_links", [])
	var overloaded := 0
	for network in summary.get("power_networks", []):
		if bool(network.get("overloaded", false)):
			overloaded += 1
	var warning := "  ⚠ 과부하 %d" % overloaded if overloaded > 0 else ""
	synergy.text = "전력 %.0f 공급 / %.0f 소모 · 냉각 %.0f · 탄약 %.0f · 신호 %.0f · 연결 %d%s" % [float(summary.get("power_supply", 0.0)), float(summary.get("power_draw", 0.0)), float(summary.get("cooling_supply", 0.0)), float(summary.get("ammo_supply", 0.0)), float(summary.get("signal_strength", 0.0)), links.size(), warning]

func _on_cell_pressed(cell: Vector2i) -> void:
	var instance_id := runtime.backpack.grid.item_at(cell)
	if instance_id != &"":
		_select_instance(instance_id)
	elif _has_selection():
		if runtime.place_record(_selected_record_index, cell):
			message.text = "선택한 모듈을 배치했습니다."
	_refresh()

func _on_cell_gui_input(event: InputEvent, cell: Vector2i) -> void:
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	var mouse := event as InputEventMouseButton
	var instance_id := runtime.backpack.grid.item_at(cell)
	if instance_id == &"":
		return
	_select_instance(instance_id)
	if mouse.button_index == MOUSE_BUTTON_RIGHT:
		_rotate_selected()
		accept_event()
	elif mouse.button_index == MOUSE_BUTTON_LEFT and mouse.shift_pressed:
		_quick_move_selected()
		accept_event()

func _on_stash_selected(index: int) -> void:
	var metadata: Variant = stash.get_item_metadata(index)
	if metadata is int:
		_selected_record_index = int(metadata)
		_refresh()

func _on_stash_activated(index: int) -> void:
	_on_stash_selected(index)
	_quick_move_selected()

func _on_stash_clicked(index: int, _position: Vector2, mouse_button_index: int) -> void:
	_on_stash_selected(index)
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_quick_move_selected()

func _select_instance(instance_id: StringName) -> void:
	var entry := runtime.entry_for_instance(instance_id)
	_selected_record_index = int(entry.get("record_index", -1))
	_auto_sort_confirmation = false
	_refresh()

func _cycle_slot(category: StringName) -> void:
	if runtime.cycle_equipped(category):
		message.text = "%s 슬롯을 교체했습니다." % String(category).capitalize()
	_refresh()

func _rotate_selected() -> void:
	if not _selection_is_placed():
		return
	if runtime.rotate_record(_selected_record_index):
		message.text = "모듈을 시계 방향으로 회전했습니다."
	_refresh()

func _quick_move_selected() -> void:
	if not _has_selection():
		return
	var record: Dictionary = runtime.owned_rewards[_selected_record_index]
	var instance_id := StringName(record.get("backpack_instance_id", ""))
	var changed := runtime.remove_record_to_stash(_selected_record_index) if instance_id != &"" else runtime.auto_place_record(_selected_record_index)
	if changed:
		message.text = "보관함으로 이동했습니다." if instance_id != &"" else "빈 칸에 자동 배치했습니다."
	_refresh()

func _request_auto_sort() -> void:
	if not _auto_sort_confirmation:
		_auto_sort_confirmation = true
		message.text = "배치가 바뀝니다. 버튼을 한 번 더 눌러 확정하세요."
		_refresh()
		return
	_auto_sort_confirmation = false
	if runtime.auto_sort():
		message.text = "큰 모듈 우선으로 자동 정렬했습니다."
	_refresh()

func _undo() -> void:
	if runtime.undo():
		message.text = "직전 배치를 복원했습니다."
	_refresh()

func _on_build_changed(_build: WeaponBuild) -> void:
	_refresh()

func _on_action_failed(reason: String) -> void:
	message.text = reason

func _has_selection() -> bool:
	return runtime != null and _selected_record_index >= 0 and _selected_record_index < runtime.owned_rewards.size() and runtime.owned_rewards[_selected_record_index] is Dictionary

func _selection_is_placed() -> bool:
	if not _has_selection():
		return false
	var record: Dictionary = runtime.owned_rewards[_selected_record_index]
	return StringName(record.get("backpack_instance_id", "")) != &""

func _focus_first_control() -> void:
	for cell in _cell_buttons.keys():
		var button: Button = _cell_buttons[cell]
		if not button.disabled:
			button.grab_focus()
			return
	close_button.grab_focus()
