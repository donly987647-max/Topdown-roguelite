class_name SettingsPanel
extends Control

signal close_requested

var service: GameSettingsService
var _binding := false

@onready var master_slider: HSlider = $Dim/Panel/Margin/VBox/Master/Slider
@onready var music_slider: HSlider = $Dim/Panel/Margin/VBox/Music/Slider
@onready var sfx_slider: HSlider = $Dim/Panel/Margin/VBox/Sfx/Slider
@onready var dialogue_slider: HSlider = $Dim/Panel/Margin/VBox/Dialogue/Slider
@onready var shake_slider: HSlider = $Dim/Panel/Margin/VBox/Shake/Slider
@onready var aim_slider: HSlider = $Dim/Panel/Margin/VBox/AimAssist/Slider
@onready var speed_slider: HSlider = $Dim/Panel/Margin/VBox/GameSpeed/Slider
@onready var fullscreen_check: CheckButton = $Dim/Panel/Margin/VBox/Fullscreen
@onready var auto_reload_check: CheckButton = $Dim/Panel/Margin/VBox/AutoReload
@onready var auto_fire_check: CheckButton = $Dim/Panel/Margin/VBox/AutoFire
@onready var subtitles_check: CheckButton = $Dim/Panel/Margin/VBox/Subtitles
@onready var reduced_flashing_check: CheckButton = $Dim/Panel/Margin/VBox/ReducedFlashing
@onready var damage_numbers: OptionButton = $Dim/Panel/Margin/VBox/DamageNumbers
@onready var reset_button: Button = $Dim/Panel/Margin/VBox/Buttons/Reset
@onready var close_button: Button = $Dim/Panel/Margin/VBox/Buttons/Close

func _ready() -> void:
	damage_numbers.clear()
	for title in ["피해 숫자: 모두", "피해 숫자: 치명타만", "피해 숫자: 보스만", "피해 숫자: 끄기"]:
		damage_numbers.add_item(title)
	master_slider.value_changed.connect(func(value: float): _set_normalized(&"master_volume", value))
	music_slider.value_changed.connect(func(value: float): _set_normalized(&"music_volume", value))
	sfx_slider.value_changed.connect(func(value: float): _set_normalized(&"sfx_volume", value))
	dialogue_slider.value_changed.connect(func(value: float): _set_normalized(&"dialogue_volume", value))
	shake_slider.value_changed.connect(func(value: float): _set_normalized(&"screen_shake", value))
	aim_slider.value_changed.connect(func(value: float): _set_normalized(&"aim_assist", value))
	speed_slider.value_changed.connect(func(value: float): _set_speed(value))
	fullscreen_check.toggled.connect(func(value: bool): _set_setting(&"fullscreen", value))
	auto_reload_check.toggled.connect(func(value: bool): _set_setting(&"auto_reload", value))
	auto_fire_check.toggled.connect(func(value: bool): _set_setting(&"auto_fire", value))
	subtitles_check.toggled.connect(func(value: bool): _set_setting(&"subtitles", value))
	reduced_flashing_check.toggled.connect(func(value: bool): _set_setting(&"reduced_flashing", value))
	damage_numbers.item_selected.connect(_on_damage_number_mode_selected)
	reset_button.pressed.connect(_reset_defaults)
	close_button.pressed.connect(_close)
	visibility_changed.connect(_on_visibility_changed)

func configure(settings_service: GameSettingsService) -> bool:
	service = settings_service
	if service == null:
		return false
	_bind_values()
	return true

func open() -> void:
	_bind_values()
	visible = true
	call_deferred("focus_default")

func focus_default() -> void:
	if visible:
		master_slider.grab_focus()

func _bind_values() -> void:
	if service == null or not is_node_ready():
		return
	_binding = true
	master_slider.value = float(service.get_value(&"master_volume", 1.0)) * 100.0
	music_slider.value = float(service.get_value(&"music_volume", 0.8)) * 100.0
	sfx_slider.value = float(service.get_value(&"sfx_volume", 0.9)) * 100.0
	dialogue_slider.value = float(service.get_value(&"dialogue_volume", 0.9)) * 100.0
	shake_slider.value = float(service.get_value(&"screen_shake", 1.0)) * 100.0
	aim_slider.value = float(service.get_value(&"aim_assist", 0.0)) * 100.0
	speed_slider.value = float(service.get_value(&"game_speed", 1.0)) * 100.0
	fullscreen_check.button_pressed = bool(service.get_value(&"fullscreen", false))
	auto_reload_check.button_pressed = bool(service.get_value(&"auto_reload", true))
	auto_fire_check.button_pressed = bool(service.get_value(&"auto_fire", false))
	subtitles_check.button_pressed = bool(service.get_value(&"subtitles", true))
	reduced_flashing_check.button_pressed = bool(service.get_value(&"reduced_flashing", false))
	var mode := String(service.get_value(&"damage_numbers_mode", "all"))
	damage_numbers.select(maxi(0, GameSettingsService.DAMAGE_NUMBER_MODES.find(mode)))
	_binding = false

func _set_normalized(key: StringName, value: float) -> void:
	_set_setting(key, clampf(value / 100.0, 0.0, 1.0))

func _set_speed(value: float) -> void:
	_set_setting(&"game_speed", clampf(value / 100.0, 0.80, 1.0))

func _set_setting(key: StringName, value: Variant) -> void:
	if _binding or service == null:
		return
	service.set_value(key, value)

func _on_damage_number_mode_selected(index: int) -> void:
	if _binding or service == null:
		return
	var safe_index := clampi(index, 0, GameSettingsService.DAMAGE_NUMBER_MODES.size() - 1)
	service.set_value(&"damage_numbers_mode", GameSettingsService.DAMAGE_NUMBER_MODES[safe_index])

func _reset_defaults() -> void:
	if service == null:
		return
	service.reset_to_defaults()
	_bind_values()

func _close() -> void:
	if service != null:
		service.save_settings()
	visible = false
	close_requested.emit()

func _on_visibility_changed() -> void:
	if visible:
		call_deferred("focus_default")
