class_name MainMenuPanel
extends Control

signal new_run_requested
signal continue_requested
signal quit_requested

@onready var continue_button: Button = $Panel/VBox/Continue

func _ready() -> void:
	$Panel/VBox/NewRun.pressed.connect(func(): new_run_requested.emit())
	continue_button.pressed.connect(func(): continue_requested.emit())
	$Panel/VBox/Quit.pressed.connect(func(): quit_requested.emit())

func set_continue_available(value: bool) -> void:
	continue_button.disabled = not value
