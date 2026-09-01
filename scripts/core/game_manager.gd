extends Node

var run_seed: int = 0
var run_elapsed := 0.0
var enemies_killed := 0
var total_damage_dealt := 0.0
var run_active := false

func _process(delta: float) -> void:
    if run_active:
        run_elapsed += delta

func reset_run(seed_value: int = 0) -> void:
    run_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
    seed(run_seed)
    run_elapsed = 0.0
    enemies_killed = 0
    total_damage_dealt = 0.0
    run_active = true

func register_enemy_kill() -> void:
    enemies_killed += 1

func register_damage(amount: float) -> void:
    total_damage_dealt += amount

func end_run() -> void:
    run_active = false
