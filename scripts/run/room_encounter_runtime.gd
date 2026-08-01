class_name RoomEncounterRuntime
extends RefCounted

signal encounter_started(template_id: StringName, wave_count: int)
signal wave_ready(index: int, entries: Array, spawn_cells: Array[Vector2i])
signal wave_cleared(index: int)
signal encounter_cleared(template_id: StringName)

var template: RoomTemplateDefinition
var waves: Array[Array] = []
var current_wave := -1
var active_enemy_count := 0
var cleared := false
var wave_delay_seconds := 0.65

func configure(room_template: RoomTemplateDefinition, planner: ThreatBudgetPlanner, difficulty_multiplier: float = 1.0) -> bool:
	if room_template == null or planner == null:
		return false
	template = room_template
	waves = planner.build_waves(template, difficulty_multiplier)
	current_wave = -1
	active_enemy_count = 0
	cleared = false
	return true

func start() -> bool:
	if template == null:
		return false
	if not template.is_combat_room():
		cleared = true
		encounter_started.emit(template.id, 0)
		encounter_cleared.emit(template.id)
		return true
	encounter_started.emit(template.id, waves.size())
	return advance_wave()

func advance_wave() -> bool:
	if cleared or template == null:
		return false
	if active_enemy_count > 0:
		return false
	current_wave += 1
	if current_wave >= waves.size():
		cleared = true
		encounter_cleared.emit(template.id)
		return false
	var entries: Array = waves[current_wave]
	active_enemy_count = entries.size()
	wave_ready.emit(current_wave, entries, template.enemy_spawn_cells)
	if active_enemy_count == 0:
		mark_wave_empty()
	return true

func notify_enemy_removed(count: int = 1) -> void:
	if cleared or current_wave < 0 or count <= 0:
		return
	active_enemy_count = maxi(0, active_enemy_count - count)
	if active_enemy_count == 0:
		wave_cleared.emit(current_wave)
		advance_wave()

func mark_wave_empty() -> void:
	if cleared or current_wave < 0:
		return
	active_enemy_count = 0
	wave_cleared.emit(current_wave)
	advance_wave()

func progress() -> Dictionary:
	return {
		"template_id": String(template.id) if template != null else "",
		"wave_index": current_wave,
		"wave_count": waves.size(),
		"active_enemy_count": active_enemy_count,
		"cleared": cleared,
	}
