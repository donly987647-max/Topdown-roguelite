class_name P2GameFlow
extends Node

@export var bootstrap_path: NodePath
@export var main_menu_path: NodePath
@export var character_select_path: NodePath
@export var result_panel_path: NodePath

var bootstrap: Zone1RunBootstrap
var main_menu: MainMenuPanel
var character_select: CharacterSelectPanel
var result_panel: RunResultPanel

func _ready() -> void:
	bootstrap = get_node_or_null(bootstrap_path) as Zone1RunBootstrap
	main_menu = get_node_or_null(main_menu_path) as MainMenuPanel
	character_select = get_node_or_null(character_select_path) as CharacterSelectPanel
	result_panel = get_node_or_null(result_panel_path) as RunResultPanel
	if bootstrap == null or main_menu == null or character_select == null or result_panel == null:
		push_error("P2GameFlow is missing required nodes")
		return
	main_menu.new_run_requested.connect(_on_new_run_requested)
	main_menu.continue_requested.connect(_on_continue_requested)
	main_menu.quit_requested.connect(func(): get_tree().quit())
	character_select.character_selected.connect(_on_character_selected)
	result_panel.retry_requested.connect(_reload_flow)
	result_panel.character_select_requested.connect(_on_change_character)
	bootstrap.run_state.run_finished.connect(_on_run_finished)
	var player := bootstrap.get_player()
	if player != null and not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	main_menu.set_continue_available(bootstrap.save_service.has_save())
	main_menu.visible = true
	character_select.visible = false
	result_panel.visible = false
	_set_combat_enabled(false)

func _on_new_run_requested() -> void:
	main_menu.visible = false
	character_select.visible = true
	result_panel.visible = false
	_set_combat_enabled(false)

func _on_continue_requested() -> void:
	main_menu.visible = false
	character_select.visible = false
	result_panel.visible = false
	if bootstrap.continue_run():
		_set_combat_enabled(true)
	else:
		main_menu.visible = true
		main_menu.set_continue_available(false)
		_set_combat_enabled(false)

func _on_character_selected(character_id: StringName) -> void:
	if bootstrap.start_new_run(bootstrap.seed_value, character_id):
		_set_combat_enabled(true)
	else:
		character_select.visible = true
		_set_combat_enabled(false)

func _on_player_died() -> void:
	_set_combat_enabled(false)
	bootstrap.run_state.fail_run()

func _on_run_finished(success: bool) -> void:
	_set_combat_enabled(false)
	character_select.visible = false
	main_menu.visible = false
	var character := bootstrap.character_catalog.get_by_id(bootstrap.run_state.selected_character_id)
	result_panel.show_result(success, character, bootstrap.run_state, bootstrap.wallet, bootstrap.owned_rewards)

func _on_change_character() -> void:
	bootstrap.clear_checkpoint()
	_reload_flow()

func _set_combat_enabled(enabled: bool) -> void:
	var player := bootstrap.get_player()
	if player != null:
		player.set_physics_process(enabled)
	var weapon := bootstrap.get_weapon_controller()
	if weapon != null:
		weapon.set_process(enabled)

func _reload_flow() -> void:
	get_tree().reload_current_scene()
