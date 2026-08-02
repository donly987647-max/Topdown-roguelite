extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_test_fullscreen_contract()
	_test_player_projectile_enemy_collision_contract()
	_test_enemy_attack_collision_contract()
	_test_infinite_starter_ammo_contract()
	_test_route_map_visibility_contract()
	if failures.is_empty():
		print("FIRST_PLAYTEST_REGRESSION_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_fullscreen_contract() -> void:
	_assert(int(ProjectSettings.get_setting("display/window/size/mode", 0)) == 3, "desktop build must start fullscreen")
	_assert(String(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "expand", "desktop stretch aspect must expand to the available display")

func _test_player_projectile_enemy_collision_contract() -> void:
	var projectile_scene := load("res://scenes/combat/Projectile.tscn") as PackedScene
	var melee_scene := load("res://scenes/enemies/zone1_melee.tscn") as PackedScene
	var ranged_scene := load("res://scenes/enemies/zone1_ranged.tscn") as PackedScene
	_assert(projectile_scene != null and melee_scene != null and ranged_scene != null, "combat scenes must load")
	if projectile_scene == null or melee_scene == null or ranged_scene == null:
		return
	var projectile := projectile_scene.instantiate() as Area2D
	var melee := melee_scene.instantiate() as CharacterBody2D
	var ranged := ranged_scene.instantiate() as CharacterBody2D
	_assert((projectile.collision_mask & 16) != 0, "player projectile must scan EnemyBody layer")
	_assert((melee.collision_layer & 16) != 0, "melee enemy must live on EnemyBody layer")
	_assert((ranged.collision_layer & 16) != 0, "ranged enemy must live on EnemyBody layer")
	projectile.free()
	melee.free()
	ranged.free()

func _test_enemy_attack_collision_contract() -> void:
	var melee_scene := load("res://scenes/enemies/zone1_melee.tscn") as PackedScene
	var enemy_projectile_scene := load("res://scenes/enemies/enemy_projectile.tscn") as PackedScene
	if melee_scene == null or enemy_projectile_scene == null:
		_assert(false, "enemy attack scenes must load")
		return
	var melee := melee_scene.instantiate() as CharacterBody2D
	var attack_area := melee.get_node("AttackArea") as Area2D
	var enemy_projectile := enemy_projectile_scene.instantiate() as Area2D
	_assert((attack_area.collision_layer & 64) != 0, "melee attack area must use EnemyAttack layer")
	_assert((attack_area.collision_mask & 4) != 0, "melee attack area must scan PlayerHurtbox")
	_assert((enemy_projectile.collision_layer & 32) != 0, "enemy projectile must use EnemyProjectile layer")
	_assert((enemy_projectile.collision_mask & 4) != 0, "enemy projectile must scan PlayerHurtbox")
	melee.free()
	enemy_projectile.free()

func _test_infinite_starter_ammo_contract() -> void:
	var player_scene := load("res://scenes/player/Player.tscn") as PackedScene
	if player_scene == null:
		_assert(false, "player scene must load")
		return
	var player := player_scene.instantiate() as Player
	root.add_child(player)
	var weapon := player.get_node("AimPivot/CombatController") as WeaponController
	_assert(weapon != null and weapon.infinite_reserve_ammo, "player starter weapon must have infinite reserve ammo")
	if weapon != null:
		weapon.ammo = 0
		weapon.reserve_ammo = 0
		_assert(weapon.start_reload(), "empty starter weapon must still be able to reload with zero reserve")
	player.queue_free()

func _test_route_map_visibility_contract() -> void:
	var ui_scene := load("res://scenes/ui/run_ui_root.tscn") as PackedScene
	if ui_scene == null:
		_assert(false, "run UI scene must load")
		return
	var ui := ui_scene.instantiate()
	root.add_child(ui)
	var binder := ui.get_node("Binder") as RunUiBinder
	var map_panel := ui.get_node("RunMapPanel") as RunMapPanel
	binder.map_panel = map_panel
	binder.reward_panel = ui.get_node("RewardChoicePanel") as RewardChoicePanel
	binder.facility_panel = ui.get_node("FacilityPanel") as FacilityPanel
	binder.coordinator = RunSceneCoordinator.new()
	map_panel.visible = false
	var toggle := InputEventAction.new()
	toggle.action = &"toggle_map"
	toggle.pressed = true
	binder._unhandled_input(toggle)
	_assert(not map_panel.visible, "full route map must not open during active combat")
	binder._on_route_choices([&"next_room"])
	_assert(map_panel.visible, "route map must open when post-combat route selection is requested")
	ui.queue_free()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
