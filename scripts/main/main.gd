extends Control

@onready var status_label: Label = %Status

func _ready() -> void:
	status_label.text = "FOUNDATION BOOT OK"
	print("[LAST MAGAZINE] Godot foundation booted successfully.")
	print("[LAST MAGAZINE] Build stage id: %d" % GameState.build_stage)
