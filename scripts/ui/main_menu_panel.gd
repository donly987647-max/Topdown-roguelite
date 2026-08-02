class_name MainMenuPanel
extends Control

signal new_run_requested
signal continue_requested
signal quit_requested

@onready var new_run_button: Button = $Panel/VBox/NewRun
@onready var continue_button: Button = $Panel/VBox/Continue
@onready var quit_button: Button = $Panel/VBox/Quit

func _ready() -> void:
	new_run_button.pressed.connect(func(): new_run_requested.emit())
	continue_button.pressed.connect(func(): continue_requested.emit())
	quit_button.pressed.connect(func(): quit_requested.emit())
	visibility_changed.connect(_on_visibility_changed)
	call_deferred("focus_default")

func set_continue_available(value: bool) -> void:
	continue_button.disabled = not value

func focus_default() -> void:
	if not visible:
		return
	if not continue_button.disabled:
		continue_button.grab_focus()
	else:
		new_run_button.grab_focus()

func _on_visibility_changed() -> void:
	if visible:
		call_deferred("focus_default")
