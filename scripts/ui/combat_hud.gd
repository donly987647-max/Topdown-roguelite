class_name CombatHud
extends Control

var bootstrap: Zone1RunBootstrap
var player: Player
var weapon: WeaponController
var wallet: RunWallet
var abilities: CharacterAbilityRuntime
var equipment: RunEquipmentRuntime
var _reload_duration := 0.0
var _reload_left := 0.0

@onready var character_label: Label = $TopLeft/Character
@onready var hp_bar: ProgressBar = $TopLeft/HP
@onready var hp_text: Label = $TopLeft/HPText
@onready var guard_label: Label = $TopLeft/Guard
@onready var shield_bar: ProgressBar = $TopLeft/Shield
@onready var status_label: Label = $TopLeft/Status
@onready var room_label: Label = $TopRight/Room
@onready var scrap_label: Label = $TopRight/Scrap
@onready var key_label: Label = $TopRight/Keys
@onready var curse_label: Label = $TopRight/Curse
@onready var active_label: Label = $BottomLeft/Active
@onready var active_bar: ProgressBar = $BottomLeft/ActiveBar
@onready var equipment_label: Label = $BottomLeft/Equipment
@onready var equipment_bar: ProgressBar = $BottomLeft/EquipmentBar
@onready var unique_label: Label = $BottomLeft/Unique
@onready var weapon_label: Label = $BottomRight/Weapon
@onready var ammo_label: Label = $BottomRight/Ammo
@onready var heat_bar: ProgressBar = $BottomRight/Heat
@onready var reload_bar: ProgressBar = $BottomRight/Reload
@onready var perfect_label: Label = $BottomRight/Perfect

func configure(run_bootstrap: Zone1RunBootstrap) -> bool:
	bootstrap = run_bootstrap
	if bootstrap == null:
		return false
	player = bootstrap.get_player()
	weapon = bootstrap.get_weapon_controller()
	wallet = bootstrap.wallet
	abilities = bootstrap.abilities
	equipment = bootstrap.equipment
	_bind_signals()
	_refresh_all()
	return true

func _process(delta: float) -> void:
	if _reload_left > 0.0:
		_reload_left = maxf(0.0, _reload_left - delta)
		var progress := 1.0 - _reload_left / maxf(_reload_duration, 0.01)
		reload_bar.value = progress * 100.0
		var in_perfect := progress >= weapon.perfect_reload_window_start and progress <= weapon.perfect_reload_window_end if weapon != null else false
		perfect_label.text = "PERFECT" if in_perfect else "완벽 재장전 %.0f–%.0f%%" % [weapon.perfect_reload_window_start * 100.0, weapon.perfect_reload_window_end * 100.0] if weapon != null else ""
	elif reload_bar.value != 0.0:
		reload_bar.value = 0.0

func _bind_signals() -> void:
	if player != null:
		if not player.health_changed.is_connected(_on_health_changed): player.health_changed.connect(_on_health_changed)
		if not player.guard_changed.is_connected(_on_guard_changed): player.guard_changed.connect(_on_guard_changed)
		if not player.temporary_shield_changed.is_connected(_on_shield_changed): player.temporary_shield_changed.connect(_on_shield_changed)
	if weapon != null:
		if not weapon.ammo_changed.is_connected(_on_ammo_changed): weapon.ammo_changed.connect(_on_ammo_changed)
		if not weapon.heat_changed.is_connected(_on_heat_changed): weapon.heat_changed.connect(_on_heat_changed)
		if not weapon.reload_started.is_connected(_on_reload_started): weapon.reload_started.connect(_on_reload_started)
		if not weapon.reload_finished.is_connected(_on_reload_finished): weapon.reload_finished.connect(_on_reload_finished)
		if not weapon.reload_cancelled.is_connected(_on_reload_finished): weapon.reload_cancelled.connect(_on_reload_finished)
		if not weapon.build_applied.is_connected(_on_build_applied): weapon.build_applied.connect(_on_build_applied)
	if wallet != null:
		if not wallet.scrap_changed.is_connected(_on_scrap_changed): wallet.scrap_changed.connect(_on_scrap_changed)
		if not wallet.debt_changed.is_connected(_on_debt_changed): wallet.debt_changed.connect(_on_debt_changed)
	if abilities != null and not abilities.active_state_changed.is_connected(_on_active_state):
		abilities.active_state_changed.connect(_on_active_state)
	if equipment != null and not equipment.active_state_changed.is_connected(_on_equipment_state):
		equipment.active_state_changed.connect(_on_equipment_state)
	if bootstrap.run_state != null and not bootstrap.run_state.room_entered.is_connected(_on_room_entered):
		bootstrap.run_state.room_entered.connect(_on_room_entered)

func _refresh_all() -> void:
	if bootstrap == null:
		return
	var character := bootstrap.character_catalog.get_by_id(bootstrap.run_state.selected_character_id)
	character_label.text = character.display_name if character != null else "LAST MAGAZINE"
	unique_label.text = character.passive_description if character != null else ""
	if player != null:
		_on_health_changed(player.health, player.max_health)
		_on_guard_changed(player.guard, player.max_guard)
		_on_shield_changed(player.temporary_shield, player.max_temporary_shield)
	if weapon != null:
		_on_ammo_changed(weapon.ammo, weapon.magazine_capacity, weapon.reserve_ammo)
		_on_heat_changed(weapon.heat, weapon.max_heat)
		_update_weapon_label()
	if wallet != null:
		_on_scrap_changed(wallet.scrap)
		_on_debt_changed(wallet.debt, wallet.debt_limit)
	if abilities != null:
		var data := abilities.active_progress()
		_on_active_state(bool(data.get("ready", false)), float(data.get("current", 0.0)), float(data.get("maximum", 1.0)), String(data.get("label", "")))
	if equipment != null:
		var equipment_data := equipment.active_progress()
		_on_equipment_state(StringName(equipment_data.get("id", "")), String(equipment_data.get("title", "장비 없음")), bool(equipment_data.get("ready", false)), float(equipment_data.get("current", 0.0)), float(equipment_data.get("maximum", 1.0)), bool(equipment_data.get("powered", false)))
	status_label.text = "상태 —"
	key_label.text = "KEY 0"
	curse_label.text = "CURSE 0"

func _on_health_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_text.text = "HP %.0f / %.0f" % [current, maximum]

func _on_guard_changed(current: int, maximum: int) -> void:
	guard_label.text = "방어판 %d / %d" % [current, maximum]

func _on_shield_changed(current: float, maximum: float) -> void:
	shield_bar.max_value = maximum
	shield_bar.value = current
	shield_bar.visible = current > 0.0

func _on_ammo_changed(current: int, capacity: int, reserve: int) -> void:
	ammo_label.text = "탄창 %d / %d   예비 %s" % [current, capacity, "∞" if weapon != null and weapon.infinite_reserve_ammo else str(reserve)]

func _on_heat_changed(current: float, maximum: float) -> void:
	heat_bar.max_value = maximum
	heat_bar.value = current
	heat_bar.visible = weapon != null and weapon.uses_heat

func _on_reload_started(duration: float) -> void:
	_reload_duration = maxf(0.01, duration)
	_reload_left = _reload_duration
	reload_bar.value = 0.0

func _on_reload_finished() -> void:
	_reload_left = 0.0
	reload_bar.value = 0.0

func _on_build_applied(_build: WeaponBuild) -> void:
	_update_weapon_label()

func _update_weapon_label() -> void:
	if weapon == null or weapon.weapon_build == null or weapon.weapon_build.frame == null:
		weapon_label.text = "무기 —"
		return
	weapon_label.text = weapon.weapon_build.frame.display_name if not weapon.weapon_build.frame.display_name.is_empty() else String(weapon.weapon_build.frame.id).replace("_", " ").capitalize()

func _on_scrap_changed(current: int) -> void:
	scrap_label.text = "고철 %d" % current

func _on_debt_changed(current: int, limit: int) -> void:
	if current > 0:
		scrap_label.text += "  빚 %d/%d" % [current, limit]

func _on_active_state(ready: bool, current: float, maximum: float, label: String) -> void:
	active_label.text = "%s  [F / Y] %s" % [label, "READY" if ready else ""]
	active_bar.max_value = maxf(1.0, maximum)
	active_bar.value = current

func _on_equipment_state(_equipment_id: StringName, title: String, ready: bool, current: float, maximum: float, powered: bool) -> void:
	var state := "READY" if ready else ("충전 중" if powered else "전력 없음")
	equipment_label.text = "%s  [Q / RB] %s" % [title, state]
	equipment_bar.max_value = maxf(1.0, maximum)
	equipment_bar.value = current

func _on_room_entered(room_id: StringName, room_type: StringName) -> void:
	room_label.text = "%s · %s" % [String(room_id), String(room_type).capitalize()]
	_refresh_all()
