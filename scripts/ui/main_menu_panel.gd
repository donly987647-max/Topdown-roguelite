class_name MainMenuPanel
extends Control

signal new_run_requested
signal continue_requested
signal quit_requested

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $Panel/Margin/VBox/Subtitle
@onready var new_run_button: Button = $Panel/Margin/VBox/NewRun
@onready var continue_button: Button = $Panel/Margin/VBox/Continue
@onready var quit_button: Button = $Panel/Margin/VBox/Quit

func _ready() -> void:
	new_run_button.pressed.connect(func(): new_run_requested.emit())
	continue_button.pressed.connect(func(): continue_requested.emit())
	quit_button.pressed.connect(func(): quit_requested.emit())
	visibility_changed.connect(_on_visibility_changed)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
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
		_apply_responsive_layout()
		call_deferred("focus_default")

func _apply_responsive_layout() -> void:
	if panel == null:
		return
	var size := get_viewport_rect().size
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var portrait := size.y > size.x
	var shortest := minf(size.x, size.y)
	var panel_width := minf(size.x - 48.0, 720.0 if not portrait else size.x - 36.0)
	var panel_height := minf(size.y - 48.0, 640.0 if not portrait else 720.0)
	panel.position = (size - Vector2(panel_width, panel_height)) * 0.5
	panel.size = Vector2(panel_width, panel_height)
	var title_size := int(clampf(shortest * (0.064 if portrait else 0.052), 34.0, 62.0))
	var subtitle_size := int(clampf(shortest * 0.025, 16.0, 24.0))
	title_label.add_theme_font_size_override("font_size", title_size)
	subtitle_label.add_theme_font_size_override("font_size", subtitle_size)
	var button_height := clampf(shortest * 0.088, 64.0, 88.0)
	for button in [new_run_button, continue_button, quit_button]:
		button.custom_minimum_size = Vector2(minf(panel_width - 80.0, 520.0), button_height)
		button.add_theme_font_size_override("font_size", int(clampf(shortest * 0.027, 18.0, 28.0)))
