extends Node
## Minimal global state for the foundation stage.

enum BuildStage {
	FOUNDATION,
	PRE_PRODUCTION,
	CORE_PROTOTYPE,
	VERTICAL_SLICE,
	ALPHA,
	BETA,
	RELEASE_CANDIDATE,
	RELEASE
}

var build_stage: BuildStage = BuildStage.FOUNDATION
var active_run_seed: int = 0
var is_run_active: bool = false

func begin_run(seed_value: int) -> void:
	active_run_seed = seed_value
	is_run_active = true
	EventBus.run_started.emit(active_run_seed)

func end_run(result: Dictionary = {}) -> void:
	is_run_active = false
	EventBus.run_ended.emit(result)

func set_build_stage(next_stage: BuildStage) -> void:
	if build_stage == next_stage:
		return
	build_stage = next_stage
	EventBus.build_stage_changed.emit(build_stage)
