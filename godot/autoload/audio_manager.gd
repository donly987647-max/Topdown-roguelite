extends Node

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var next_sfx_index := 0

func _ready() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.name = "MusicPlayer"
    music_player.bus = &"Music"
    add_child(music_player)

    for i in 12:
        var player := AudioStreamPlayer.new()
        player.name = "SFX_%02d" % i
        player.bus = &"SFX"
        add_child(player)
        sfx_players.append(player)

func play_music(stream: AudioStream, fade_seconds: float = 0.35) -> void:
    if stream == null:
        return
    if music_player.playing and music_player.stream == stream:
        return
    if music_player.playing and fade_seconds > 0.0:
        var tween := create_tween()
        tween.tween_property(music_player, "volume_db", -40.0, fade_seconds)
        await tween.finished
    music_player.stream = stream
    music_player.volume_db = 0.0
    music_player.play()

func stop_music(fade_seconds: float = 0.25) -> void:
    if not music_player.playing:
        return
    if fade_seconds <= 0.0:
        music_player.stop()
        return
    var tween := create_tween()
    tween.tween_property(music_player, "volume_db", -40.0, fade_seconds)
    await tween.finished
    music_player.stop()
    music_player.volume_db = 0.0

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
    if stream == null or sfx_players.is_empty():
        return
    var player := sfx_players[next_sfx_index]
    next_sfx_index = (next_sfx_index + 1) % sfx_players.size()
    player.stop()
    player.stream = stream
    player.volume_db = volume_db
    player.pitch_scale = pitch_scale
    player.play()

func set_bus_linear(bus_name: StringName, value: float) -> void:
    var index := AudioServer.get_bus_index(bus_name)
    if index < 0:
        return
    var normalized := clampf(value, 0.0, 1.0)
    AudioServer.set_bus_volume_db(index, linear_to_db(maxf(normalized, 0.0001)))
    AudioServer.set_bus_mute(index, normalized <= 0.0001)

func apply_profile_settings(settings: Dictionary) -> void:
    set_bus_linear(&"Master", float(settings.get("master", 1.0)))
    set_bus_linear(&"Music", float(settings.get("music", 0.8)))
    set_bus_linear(&"SFX", float(settings.get("sfx", 0.9)))
