extends Node

enum BuildStage { FOUNDATION, PRE_PRODUCTION, CORE_PROTOTYPE, VERTICAL_SLICE, ALPHA, BETA, RELEASE_CANDIDATE }

var build_stage: BuildStage = BuildStage.PRE_PRODUCTION
var high_difficulty_hazard_correction_disabled := false
var run_seed: int = 0
var kills: int = 0
var damage_dealt: float = 0.0
var damage_taken: float = 0.0

func reset_run() -> void:
	run_seed = Time.get_ticks_msec()
	seed(run_seed)
	kills = 0
	damage_dealt = 0.0
	damage_taken = 0.0
