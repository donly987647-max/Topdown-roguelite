extends Node

signal shot_fired(payload: Dictionary)
signal projectile_hit(payload: Dictionary)
signal enemy_killed(payload: Dictionary)
signal reload_started(payload: Dictionary)
signal reload_completed(payload: Dictionary)
signal perfect_reload(payload: Dictionary)
signal weapon_build_changed(payload: Dictionary)
signal player_damaged(payload: Dictionary)
signal player_died(payload: Dictionary)
signal wave_changed(payload: Dictionary)
signal encounter_cleared(payload: Dictionary)
