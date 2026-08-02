class_name RunUiBinder
extends Node

@export var map_panel_path: NodePath
@export var reward_panel_path: NodePath
@export var combat_hud_path: NodePath
@export var facility_panel_path: NodePath
@export var inventory_panel_path: NodePath

var coordinator: RunSceneCoordinator
var bootstrap: Zone1RunBootstrap
var map_panel: RunMapPanel
var reward_panel: RewardChoicePanel
var combat_hud: CombatHud
var facility_panel: FacilityPanel
var inventory_panel: InventoryPanel
var _route_selection_required := false
var _restore_map_after_inventory := false

func configure(run_coordinator: RunSceneCoordinator, run_bootstrap: Zone1RunBootstrap = null) -> bool:
	coordinator = run_coordinator
	bootstrap = run_bootstrap
	map_panel = get_node_or_null(map_panel_path) as RunMapPanel
	reward_panel = get_node_or_null(reward_panel_path) as RewardChoicePanel
	combat_hud = get_node_or_null(combat_hud_path) as CombatHud
	facility_panel = get_node_or_null(facility_panel_path) as FacilityPanel
	inventory_panel = get_node_or_null(inventory_panel_path) as InventoryPanel
	if coordinator == null or map_panel == null or reward_panel == null:
		return false
	map_panel.visible = false
	reward_panel.visible = false
	coordinator.reward_panel_requested.connect(_on_reward_choices)
	coordinator.route_panel_requested.connect(_on_route_choices)
	coordinator.map_state_changed.connect(_on_map_state_changed)
	map_panel.route_selected.connect(_on_route_selected)
	reward_panel.reward_selected.connect(_on_reward_selected)
	if bootstrap != null:
		if combat_hud != null: combat_hud.configure(bootstrap)
		if facility_panel != null:
			facility_panel.configure(bootstrap)
			facility_panel.modal_state_changed.connect(func(_open: bool): _refresh_gameplay_input())
		if inventory_panel != null:
			inventory_panel.configure(bootstrap)
			inventory_panel.modal_state_changed.connect(_on_inventory_modal_state_changed)
	_refresh_gameplay_input()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if map_panel == null or coordinator == null:
		return
	var joypad_inventory_conflict := event is InputEventJoypadButton and map_panel.visible and (inventory_panel == null or not inventory_panel.visible)
	if event.is_action_pressed("toggle_inventory") and not joypad_inventory_conflict:
		if inventory_panel != null and inventory_panel.visible:
			if not (event is InputEventJoypadButton):
				inventory_panel.close()
			else:
				return
		elif _can_open_inventory():
			_restore_map_after_inventory = map_panel.visible
			map_panel.visible = false
			inventory_panel.open()
		_refresh_gameplay_input()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_map") and not reward_panel.visible and (facility_panel == null or not facility_panel.visible) and (inventory_panel == null or not inventory_panel.visible):
		map_panel.visible = not map_panel.visible
		if map_panel.visible:
			_on_map_state_changed({})
			map_panel.focus_first_available()
		_refresh_gameplay_input()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and map_panel.visible and not _route_selection_required:
		map_panel.visible = false
		_refresh_gameplay_input()
		get_viewport().set_input_as_handled()

func _on_reward_choices(choices: Array[RewardOffer]) -> void:
	reward_panel.present(choices)
	_refresh_gameplay_input()

func _on_route_choices(room_ids: Array[StringName]) -> void:
	_route_selection_required = not room_ids.is_empty()
	if _route_selection_required:
		map_panel.visible = true
		_on_map_state_changed({})
		map_panel.focus_first_available()
	_refresh_gameplay_input()

func _on_reward_selected(index: int) -> void:
	if coordinator.choose_reward(index):
		reward_panel.clear()
	_refresh_gameplay_input()

func _on_route_selected(room_id: StringName) -> void:
	if coordinator.choose_route(room_id):
		_route_selection_required = false
		map_panel.visible = false
	_refresh_gameplay_input()

func _on_map_state_changed(_state: Dictionary) -> void:
	if coordinator == null or coordinator.run_state == null or coordinator.run_state.graph == null:
		return
	var state := coordinator.run_state
	map_panel.bind_run(state.graph, state.current_room_id, state.visited_rooms, state.cleared_rooms)

func _can_open_inventory() -> bool:
	if inventory_panel == null or bootstrap == null or coordinator == null or coordinator.run_state == null:
		return false
	if reward_panel != null and reward_panel.visible:
		return false
	if facility_panel != null and facility_panel.visible:
		return false
	var state := coordinator.run_state
	return state.current_room_id != &"" and state.cleared_rooms.has(state.current_room_id)

func _on_inventory_modal_state_changed(open: bool) -> void:
	if not open:
		if _restore_map_after_inventory or _route_selection_required:
			map_panel.visible = true
			_on_map_state_changed({})
			map_panel.focus_first_available()
		_restore_map_after_inventory = false
		if bootstrap != null:
			bootstrap.save_checkpoint()
	_refresh_gameplay_input()

func _refresh_gameplay_input() -> void:
	if bootstrap == null:
		return
	var player := bootstrap.get_player()
	var weapon := bootstrap.get_weapon_controller()
	var blocked := (map_panel != null and map_panel.visible) or (reward_panel != null and reward_panel.visible) or (facility_panel != null and facility_panel.visible) or (inventory_panel != null and inventory_panel.visible)
	if player != null:
		player.set_input_enabled(not blocked)
	if weapon != null:
		weapon.set_process(not blocked)
