extends Node2D

@onready var player: Player = $Player
@onready var weapon: WeaponController = $Player/AimPivot/CombatController
@onready var combat_room: CombatRoom = $CombatRoom
@onready var hp_label: Label = $HUD/HP
@onready var ammo_label: Label = $HUD/Ammo
@onready var reload_bar: ProgressBar = $HUD/ReloadBar
@onready var status_label: Label = $HUD/Status
@onready var room_label: Label = $HUD/RoomState
@onready var debug_label: Label = $HUD/Debug

var _base_status := "WASD Move | Mouse Aim/Fire | R Reload | Space Dash"

func _ready() -> void:
	print("LAST MAGAZINE: M1 combat lab booted")
	weapon.ammo_changed.connect(_on_ammo_changed)
	weapon.reload_started.connect(_on_reload_started)
	weapon.reload_finished.connect(_on_reload_finished)
	weapon.reload_cancelled.connect(_on_reload_cancelled)
	weapon.perfect_reload.connect(_on_perfect_reload)
	weapon.overheated.connect(_on_overheated)
	weapon.overheat_recovered.connect(_on_overheat_recovered)
	combat_room.room_started.connect(_on_room_started)
	combat_room.wave_changed.connect(_on_wave_changed)
	combat_room.room_cleared.connect(_on_room_cleared)
	combat_room.reward_spawned.connect(_on_reward_spawned)
	_on_ammo_changed(weapon.ammo, weapon.magazine_capacity, -1 if weapon.infinite_reserve_ammo else weapon.reserve_ammo)
	reload_bar.visible = false

func _process(_delta: float) -> void:
	hp_label.text = "HP  %d / %d" % [roundi(player.health), roundi(player.max_health)]
	if weapon.is_reloading():
		reload_bar.visible = true
		reload_bar.value = weapon.reload_progress() * 100.0
	else:
		reload_bar.visible = false
	_update_debug_overlay()

func _update_debug_overlay() -> void:
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	debug_label.text = "FPS %d\nENEMIES %d\nSPEED %.0f\nDASH CD %.2f\nI-FRAME %.2f\nINPUT %s\nHEAT %.0f/%.0f%s" % [
		Engine.get_frames_per_second(),
		enemy_count,
		player.velocity.length(),
		player.dash_cooldown_remaining(),
		player.invulnerability_remaining(),
		"MOBILE" if player.mobile_input_active() else "DESKTOP",
		weapon.heat,
		weapon.max_heat,
		" OVERHEAT" if weapon.is_overheated() else ""
	]

func _on_ammo_changed(current: int, capacity: int, reserve: int) -> void:
	var reserve_text := "∞" if reserve < 0 else str(reserve)
	ammo_label.text = "AMMO  %02d / %02d  |  %s" % [current, capacity, reserve_text]

func _on_reload_started(_duration: float) -> void:
	status_label.text = "RELOADING — press R in the timing window for PERFECT RELOAD"

func _on_reload_finished() -> void:
	status_label.text = _base_status

func _on_reload_cancelled() -> void:
	status_label.text = "RELOAD CANCELLED BY DASH"

func _on_perfect_reload() -> void:
	status_label.text = "PERFECT RELOAD"

func _on_overheated(_duration: float) -> void:
	status_label.text = "WEAPON OVERHEATED"

func _on_overheat_recovered() -> void:
	status_label.text = _base_status

func _on_room_started(enemy_count: int) -> void:
	room_label.text = "WAVE 1/2  |  HOSTILES %d" % enemy_count

func _on_wave_changed(current_wave: int, total_waves: int, enemy_count: int) -> void:
	room_label.text = "WAVE %d/%d  |  HOSTILES %d" % [current_wave, total_waves, enemy_count]
	if current_wave > 1:
		status_label.text = "INCOMING — RANGED HOSTILES"

func _on_room_cleared() -> void:
	room_label.text = "ROOM CLEAR"
	status_label.text = "ROOM CLEAR — collect the salvage reward"

func _on_reward_spawned(reward: Node) -> void:
	if reward.has_signal("collected"):
		reward.collected.connect(_on_reward_collected)

func _on_reward_collected() -> void:
	status_label.text = "SALVAGE COLLECTED — combat room loop complete"
