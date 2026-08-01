class_name RunUiBinder
extends Node

@export var map_panel_path: NodePath
@export var reward_panel_path: NodePath

var coordinator: RunSceneCoordinator
var map_panel: RunMapPanel
var reward_panel: RewardChoicePanel

func configure(run_coordinator: RunSceneCoordinator) -> bool:
	coordinator = run_coordinator
	map_panel = get_node_or_null(map_panel_path) as RunMapPanel
	reward_panel = get_node_or_null(reward_panel_path) as RewardChoicePanel
	if coordinator == null or map_panel == null or reward_panel == null:
		return false
	coordinator.reward_panel_requested.connect(reward_panel.present)
	coordinator.map_state_changed.connect(_on_map_state_changed)
	map_panel.route_selected.connect(coordinator.choose_route)
	reward_panel.reward_selected.connect(_on_reward_selected)
	return true

func _on_reward_selected(index: int) -> void:
	if coordinator.choose_reward(index):
		reward_panel.clear()

func _on_map_state_changed(_state: Dictionary) -> void:
	if coordinator == null or coordinator.run_state == null or coordinator.run_state.graph == null:
		return
	var state := coordinator.run_state
	map_panel.bind_run(state.graph, state.current_room_id, state.visited_rooms, state.cleared_rooms)
