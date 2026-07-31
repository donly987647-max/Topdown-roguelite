class_name CombatHUD
extends CanvasLayer

var stats_label: Label
var ammo_label: Label
var enemy_label: Label
var status_label: Label
var precision_label: Label
var damage_flash: ColorRect
var _precision_time := 0.0

func _ready() -> void:
	layer = 20
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var panel := ColorRect.new()
	panel.color = Color(0.03, 0.05, 0.07, 0.86)
	panel.position = Vector2(14, 14)
	panel.size = Vector2(390, 104)
	root.add_child(panel)
	stats_label = _make_label(root, Vector2(28, 24), 18)
	ammo_label = _make_label(root, Vector2(28, 68), 18)
	enemy_label = _make_label(root, Vector2(760, 20), 18)
	status_label = _make_label(root, Vector2(18, 490), 14)
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		status_label.text = "MOBILE P2  ·  LEFT MOVE  ·  RIGHT AIM/FIRE  ·  WEAPON / DASH / RELOAD / BAG"
		status_label.position = Vector2(18, 458)
	else:
		status_label.text = "WASD MOVE  ·  MOUSE FIRE  ·  1/2/3 OR Q WEAPON  ·  SPACE DASH  ·  R RELOAD  ·  I BAG"
	precision_label = _make_label(root, Vector2(370, 80), 24)
	precision_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	precision_label.size = Vector2(220, 40)
	damage_flash = ColorRect.new()
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(1.0, 0.1, 0.2, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(damage_flash)
	EventBus.player_stats_changed.connect(_on_stats)
	EventBus.ammo_changed.connect(_on_ammo)
	EventBus.enemy_count_changed.connect(_on_enemy_count)
	EventBus.precision_dodge.connect(_on_precision_dodge)
	EventBus.player_damaged.connect(_on_player_damaged)
	call_deferred("_sync_initial_state")

func _process(delta: float) -> void:
	_precision_time = maxf(0.0, _precision_time - delta)
	precision_label.modulate.a = clampf(_precision_time * 2.0, 0.0, 1.0)
	damage_flash.color.a = move_toward(damage_flash.color.a, 0.0, delta * 2.8)

func _sync_initial_state() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var health_node: Node = player.get_node_or_null("HealthComponent")
	if health_node != null and health_node.has_method("get_snapshot"):
		_on_stats(health_node.get_snapshot())
	if player.has_method("get_weapon_snapshot"):
		var snapshot: Dictionary = player.get_weapon_snapshot()
		_on_ammo(
			int(snapshot.get("current", 0)),
			int(snapshot.get("capacity", 0)),
			bool(snapshot.get("reloading", false)),
			String(snapshot.get("display_name", "NO WEAPON"))
		)

func _make_label(parent: Control, position_value: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = position_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e8eef1"))
	parent.add_child(label)
	return label

func _on_stats(snapshot: Dictionary) -> void:
	stats_label.text = "HP %d/%d   ARMOR %d   SHIELD %d" % [int(snapshot.get("health", 0)), int(snapshot.get("max_health", 100)), int(snapshot.get("armor", 0)), int(snapshot.get("temporary_shield", 0))]

func _on_ammo(current: int, capacity: int, reloading: bool, weapon_name: String) -> void:
	ammo_label.text = "%s  %02d / %02d%s" % [weapon_name, current, capacity, "  RELOADING" if reloading else ""]

func _on_enemy_count(count: int) -> void:
	enemy_label.text = "TRAINING HOSTILES: %d" % count

func _on_precision_dodge(_position: Vector2) -> void:
	precision_label.text = "PRECISION DODGE"
	precision_label.add_theme_color_override("font_color", Color("6de7ef"))
	_precision_time = 1.1

func _on_player_damaged(_amount: float, _source_position: Vector2) -> void:
	damage_flash.color.a = 0.18
