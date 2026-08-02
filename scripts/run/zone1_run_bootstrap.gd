class_name Zone1RunBootstrap
extends Node

@export var room_parent_path: NodePath
@export var player_path: NodePath
@export var camera_path: NodePath
@export var weapon_controller_path: NodePath
@export var ui_parent_path: NodePath
@export var auto_start := true
@export var continue_if_available := true
@export var seed_value := 0

var run_state := RunStateController.new()
var template_registry := RoomTemplateRegistry.new()
var spawn_registry := EnemySpawnRegistry.new()
var threat_planner := ThreatBudgetPlanner.new()
var wallet := RunWallet.new()
var backpack := BackpackState.new()
var save_service := RunSaveService.new()
var owned_rewards: Array = []
var character_catalog := CharacterCatalog.new()
var character_runtime := CharacterRunRuntime.new()
var starter_weapon_runtime := StarterWeaponRuntime.new()

var room_runtime: RoomSceneRuntime
var coordinator: RunSceneCoordinator
var facilities: RunFacilityCoordinator
var devour_runtime: DevourRoomRuntime
var abilities: CharacterAbilityRuntime
var ui_root: Node

func _ready() -> void:
	_build_runtime()
	if auto_start:
		if continue_if_available and save_service.has_save() and continue_run():
			return
		start_new_run(seed_value, &"mara")

func _build_runtime() -> void:
	var room_parent := get_node_or_null(room_parent_path)
	if room_parent == null:
		room_parent = self
	var player := get_player()
	var camera := get_node_or_null(camera_path) as Camera2D
	var weapon := get_weapon_controller()
	var content := Zone1ContentCatalog.new()
	content.register_into(template_registry, threat_planner, spawn_registry)
	var rewards := Zone1RewardCatalog.new().offers()
	run_state.reward_selector.set_pool(rewards)
	run_state.set_build_tags(_derive_build_tags(weapon))

	room_runtime = RoomSceneRuntime.new()
	room_runtime.name = "RoomSceneRuntime"
	add_child(room_runtime)
	room_runtime.configure(room_parent, spawn_registry, threat_planner)

	coordinator = RunSceneCoordinator.new()
	coordinator.name = "RunSceneCoordinator"
	add_child(coordinator)
	coordinator.configure(run_state, room_runtime, template_registry, player, camera)

	facilities = RunFacilityCoordinator.new()
	facilities.name = "RunFacilityCoordinator"
	add_child(facilities)
	facilities.configure(run_state, wallet)
	facilities.set_shop_offers(rewards.slice(0, mini(5, rewards.size())))

	if player != null:
		MagazineRuntime.attach_to_player(player)
	if weapon != null:
		devour_runtime = DevourRoomRuntime.new()
		devour_runtime.name = "DevourRoomRuntime"
		add_child(devour_runtime)
		devour_runtime.configure(weapon, room_runtime)

	_bind_checkpoint_signals()
	_setup_ui()

func start_new_run(seed: int = 0, character_id: StringName = &"mara") -> bool:
	var character := character_catalog.get_by_id(character_id)
	if character == null or character.secret:
		return false
	wallet.reset()
	backpack = BackpackState.new()
	owned_rewards.clear()
	run_state.reward_selector.restore_history({})
	run_state.set_character(character.id)
	var context := _build_run_context()
	if not character_runtime.apply(character, get_player(), wallet, context, true):
		return false
	if not starter_weapon_runtime.apply(get_weapon_controller(), character.starting_frame_id):
		return false
	if not _configure_character_abilities(character):
		return false
	context["character_ability_runtime"] = abilities
	run_state.set_build_tags(_derive_build_tags(get_weapon_controller()))
	var generator := RunGraphGenerator.new()
	var graph := generator.generate(seed)
	var validation := generator.validate(graph)
	if not bool(validation.get("valid", false)):
		push_error("Zone 1 graph validation failed: %s" % str(validation.get("errors", [])))
		return false
	var started := run_state.start_run(graph, seed, context)
	_refresh_combat_hud()
	return started

func continue_run() -> bool:
	var context := _build_run_context()
	if not save_service.restore_run(run_state, wallet, backpack, template_registry, context):
		return false
	run_state.restore_registered_templates(template_registry)
	var character := character_catalog.get_by_id(run_state.selected_character_id)
	if character == null:
		return false
	if not character_runtime.apply(character, get_player(), wallet, run_state.run_context, false):
		return false
	var weapon := get_weapon_controller()
	if weapon == null:
		return false
	if weapon.weapon_build == null:
		var saved_weapon: Dictionary = run_state.run_context.get("_restored_weapon_state", {})
		var saved_frame := StringName(saved_weapon.get("frame_id", String(character.starting_frame_id)))
		if not starter_weapon_runtime.apply(weapon, saved_frame):
			return false
	save_service.apply_runtime_state(run_state.run_context)
	if not _configure_character_abilities(character):
		return false
	run_state.run_context["character_ability_runtime"] = abilities
	run_state.set_build_tags(_derive_build_tags(weapon))
	var node := run_state.current_node()
	if node == null:
		return false
	run_state.room_entered.emit(run_state.current_room_id, node.room_type)
	_refresh_combat_hud()
	return true

func save_checkpoint() -> bool:
	return save_service.save_run(run_state, wallet, backpack, template_registry)

func clear_checkpoint() -> bool:
	return save_service.delete_save()

func get_player() -> Player:
	var player := get_node_or_null(player_path) as Player
	if player == null:
		player = get_tree().get_first_node_in_group(&"player") as Player
	return player

func get_weapon_controller() -> WeaponController:
	var weapon := get_node_or_null(weapon_controller_path) as WeaponController
	var player := get_player()
	if weapon == null and player != null:
		weapon = _find_weapon_controller(player)
	return weapon

func _build_run_context() -> Dictionary:
	return {
		"wallet": wallet,
		"player": get_player(),
		"weapon_controller": get_weapon_controller(),
		"backpack_state": backpack,
		"owned_rewards": owned_rewards,
		"character_ability_runtime": abilities,
	}

func _configure_character_abilities(character: CharacterDefinition) -> bool:
	if abilities != null and is_instance_valid(abilities):
		abilities.queue_free()
	abilities = CharacterAbilityRuntime.new()
	abilities.name = "CharacterAbilityRuntime"
	add_child(abilities)
	var configured := abilities.configure(character, get_player(), get_weapon_controller(), run_state, room_runtime, facilities, wallet)
	if configured:
		facilities.refresh_character_modifiers()
	return configured

func _bind_checkpoint_signals() -> void:
	if not run_state.room_entered.is_connected(_on_checkpoint_room_entered):
		run_state.room_entered.connect(_on_checkpoint_room_entered)
	if not run_state.run_finished.is_connected(_on_run_finished):
		run_state.run_finished.connect(_on_run_finished)

func _on_checkpoint_room_entered(_room_id: StringName, _room_type: StringName) -> void:
	call_deferred("save_checkpoint")

func _on_run_finished(_success: bool) -> void:
	clear_checkpoint()

func _setup_ui() -> void:
	var parent := get_node_or_null(ui_parent_path)
	if parent == null:
		return
	var resource := load("res://scenes/ui/run_ui_root.tscn")
	if not (resource is PackedScene):
		return
	ui_root = resource.instantiate()
	parent.add_child(ui_root)
	var binder := ui_root.get_node_or_null("Binder") as RunUiBinder
	if binder != null:
		binder.configure(coordinator, self)

func _refresh_combat_hud() -> void:
	if ui_root == null:
		return
	var hud := ui_root.get_node_or_null("CombatHUD") as CombatHud
	if hud != null:
		hud.configure(self)

func _find_weapon_controller(root: Node) -> WeaponController:
	if root is WeaponController:
		return root as WeaponController
	for child in root.get_children():
		var result := _find_weapon_controller(child)
		if result != null:
			return result
	return null

func _derive_build_tags(weapon: WeaponController) -> PackedStringArray:
	var result := PackedStringArray()
	if weapon == null or weapon.weapon_build == null:
		return result
	var build := weapon.weapon_build
	if build.frame != null:
		for tag in build.frame.compatibility_tags:
			if tag not in result:
				result.append(tag)
	for part in [build.barrel, build.magazine, build.core]:
		if part == null:
			continue
		for tag in part.tags:
			if tag not in result:
				result.append(tag)
	return result
