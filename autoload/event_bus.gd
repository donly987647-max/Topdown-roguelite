extends Node
## Central signal hub. Keep systems decoupled by routing cross-system events here.

signal build_stage_changed(stage: int)
signal run_started(seed: int)
signal run_ended(result: Dictionary)
signal room_entered(room_id: StringName)
signal room_cleared(room_id: StringName)
signal player_damaged(amount: float, source_id: StringName)
signal player_died
signal pause_requested(paused: bool)
