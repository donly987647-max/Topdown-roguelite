class_name RunResultPanel
extends Control

signal retry_requested
signal character_select_requested

@onready var result_label: Label = $Panel/Margin/VBox/Result
@onready var summary_label: Label = $Panel/Margin/VBox/Summary
@onready var retry_button: Button = $Panel/Margin/VBox/Buttons/Retry
@onready var select_button: Button = $Panel/Margin/VBox/Buttons/CharacterSelect

func _ready() -> void:
	visible = false
	retry_button.pressed.connect(func(): retry_requested.emit())
	select_button.pressed.connect(func(): character_select_requested.emit())

func show_result(success: bool, character: CharacterDefinition, state: RunStateController, wallet: RunWallet, owned_rewards: Array) -> void:
	visible = true
	result_label.text = "ZONE CLEARED" if success else "RUN TERMINATED"
	var character_name := character.display_name if character != null else "UNKNOWN"
	var cleared := state.cleared_rooms.size() if state != null else 0
	var visited := state.visited_rooms.size() if state != null else 0
	var scrap := wallet.scrap if wallet != null else 0
	var reward_names: Array[String] = []
	for raw in owned_rewards:
		if raw is Dictionary:
			reward_names.append(String(raw.get("id", "unknown")).replace("_", " ").capitalize())
	var rewards_text := ", ".join(reward_names) if not reward_names.is_empty() else "없음"
	summary_label.text = "캐릭터  %s\n방문 %d  |  클리어 %d\n보유 고철 %d\n획득 보상 %s" % [character_name, visited, cleared, scrap, rewards_text]
