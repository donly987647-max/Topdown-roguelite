extends Node

# Temporary production guard: the current vertical slice only contains starter weapons.
# Keep reserve ammunition available so a run can never become unwinnable.
const STARTER_RESERVE_FLOOR := 999999

func _process(_delta: float) -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return
    var player_data = scene.get("player")
    if typeof(player_data) != TYPE_DICTIONARY or player_data.is_empty():
        return
    if not player_data.has("reserve"):
        return
    player_data["reserve"] = maxi(int(player_data["reserve"]), STARTER_RESERVE_FLOOR)
