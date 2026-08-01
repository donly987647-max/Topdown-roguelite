extends Node2D

@onready var player: Player = $Player
@onready var weapon: WeaponController = $Player/AimPivot/CombatController
@onready var combat_room: CombatRoom = $CombatRoom
@onready var hp_label: Label = $HUD/HP
@onready var ammo_label: Label = $HUD/Ammo
@onready var reload_bar: ProgressBar = $HUD/ReloadBar
@onready var status_label: Label = $HUD/Status
@onready var room_label: Label = $HUD/RoomState

func _ready() -> void:
	print("LAST MAGAZINE: M1 combat lab booted")
	weapon.ammo_changed.connect(_on_ammo_changed)
	weapon.reload_started.connect(_on_reload_started)
	weapon.reload_finished.connect(_on_reload_finished)
	combat_room.room_started.connect(_on_room_started)
	combat_room.room_cleared.connect(_on_room_cleared)
	_on_ammo_changed(weapon.ammo, weapon.magazine_capacity)
	reload_bar.visible = false

func _process(_delta: float) -> void:
	hp_label.text = "HP  %d / %d" % [roundi(player.health), roundi(player.max_health)]
	if weapon.is_reloading():
		reload_bar.visible = true
		reload_bar.value = weapon.reload_progress() * 100.0
	else:
		reload_bar.visible = false

func _on_ammo_changed(current: int, capacity: int) -> void:
	ammo_label.text = "AMMO  %02d / %02d" % [current, capacity]

func _on_reload_started(_duration: float) -> void:
	status_label.text = "RELOADING"

func _on_reload_finished() -> void:
	status_label.text = "WASD Move | Mouse Aim/Fire | R Reload | Space Dash"

func _on_room_started(enemy_count: int) -> void:
	room_label.text = "HOSTILES %d" % enemy_count

func _on_room_cleared() -> void:
	room_label.text = "ROOM CLEAR"
	status_label.text = "ROOM CLEAR — M1 combat loop checkpoint reached"
