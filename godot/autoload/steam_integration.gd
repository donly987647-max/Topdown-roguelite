extends Node

var steam = null
var available := false
var initialized := false
var last_error := ""

func _ready() -> void: initialize()
func _process(_delta: float) -> void:
    if available and steam != null and steam.has_method("run_callbacks"): steam.call("run_callbacks")

func initialize() -> bool:
    if initialized: return available
    initialized = true
    if not Engine.has_singleton("Steam"): last_error = "Steam singleton not installed; offline adapter active."; return false
    steam = Engine.get_singleton("Steam")
    if steam == null: last_error = "Steam singleton unavailable."; return false
    if steam.has_method("steamInitEx"): available = int(steam.call("steamInitEx")) == 0
    elif steam.has_method("steamInit"): available = bool(steam.call("steamInit"))
    else: last_error = "Steam extension API mismatch."; return false
    if not available: last_error = "Steam initialization failed."
    return available

func unlock_achievement(api_name: String) -> void:
    if not available or steam == null: return
    if steam.has_method("setAchievement"): steam.call("setAchievement", api_name)
    if steam.has_method("storeStats"): steam.call("storeStats")

func write_cloud_file(file_name: String, data: PackedByteArray) -> bool:
    if not available or steam == null or not steam.has_method("fileWrite"): return false
    return bool(steam.call("fileWrite", file_name, data))

func read_cloud_file(file_name: String) -> PackedByteArray:
    if not available or steam == null or not steam.has_method("fileRead"): return PackedByteArray()
    var result = steam.call("fileRead", file_name)
    return result if typeof(result) == TYPE_PACKED_BYTE_ARRAY else PackedByteArray()

func upload_score(leaderboard_name: String, score: int, details: PackedInt32Array = PackedInt32Array()) -> void:
    if not available or steam == null: return
    if steam.has_method("findOrCreateLeaderboard"): steam.call("findOrCreateLeaderboard", leaderboard_name, 2, 1)
    if steam.has_method("uploadLeaderboardScore"): steam.call("uploadLeaderboardScore", score, true, details)

func status_text() -> String: return "Steam connected" if available else "Offline mode: %s" % last_error
