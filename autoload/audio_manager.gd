extends Node

const MIX_RATE := 22050.0
const CUES := {
	&"fire": {"frequency": 180.0, "duration": 0.10, "harmonic": 2.0, "noise": 0.16},
	&"hit": {"frequency": 95.0, "duration": 0.08, "harmonic": 2.0, "noise": 0.22},
	&"dash": {"frequency": 420.0, "duration": 0.14, "harmonic": 1.8, "noise": 0.12},
	&"telegraph": {"frequency": 640.0, "duration": 0.30, "harmonic": 1.5, "noise": 0.0},
	&"reload": {"frequency": 260.0, "duration": 0.18, "harmonic": 2.0, "noise": 0.05},
	&"hurt": {"frequency": 72.0, "duration": 0.16, "harmonic": 2.0, "noise": 0.18}
}

var _last_played: Dictionary = {}

func play_cue(cue: StringName, volume_db := 0.0, minimum_interval := 0.0) -> void:
	if not CUES.has(cue):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if minimum_interval > 0.0 and now - float(_last_played.get(cue, -999.0)) < minimum_interval:
		return
	_last_played[cue] = now
	var parameters: Dictionary = CUES[cue]
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = maxf(0.25, float(parameters.duration) + 0.05)
	var player := AudioStreamPlayer.new()
	player.stream = generator
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.97, 1.03)
	add_child(player)
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback != null:
		playback.push_buffer(_build_buffer(parameters))
	get_tree().create_timer(float(parameters.duration) + 0.1).timeout.connect(player.queue_free)

func _build_buffer(parameters: Dictionary) -> PackedVector2Array:
	var duration := float(parameters.duration)
	var frequency := float(parameters.frequency)
	var harmonic := float(parameters.harmonic)
	var noise_amount := float(parameters.noise)
	var frame_count := int(duration * MIX_RATE)
	var frames := PackedVector2Array()
	frames.resize(frame_count)
	for index in range(frame_count):
		var time := index / MIX_RATE
		var normalized := time / duration
		var envelope := pow(maxf(0.0, 1.0 - normalized), 1.7)
		var sample := sin(TAU * frequency * time) * 0.55
		sample += sin(TAU * frequency * harmonic * time) * 0.22
		sample += sin(TAU * (frequency * 7.1 + index % 37) * time) * noise_amount
		sample *= envelope * 0.35
		frames[index] = Vector2(sample, sample)
	return frames
