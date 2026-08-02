class_name CharacterAbilityRuntime
extends Node

signal active_state_changed(ready: bool, current: float, maximum: float, label: String)
signal focus_changed(stacks: int)
signal mutation_reaction(reaction_id: StringName, target: Node)
signal reward_rerolled(index: int, offer: RewardOffer)

const MARA_KILLS_PER_CHARGE := 8
const KANE_MAX_FOCUS := 5
const KANE_CHAIN_WINDOW := 3.0
const KANE_ACTIVE_COOLDOWN := 18.0
const NOVA_ACTIVE_COOLDOWN := 16.0
const REX_ACTIVE_COOLDOWN := 12.0
const NOVA_ACTIVE_RADIUS := 380.0
const NOVA_STATUS_IDS: Array[StringName] = [&"burn", &"cold", &"shock", &"corrosion", &"bleed", &"confusion", &"vulnerable"]

var character: CharacterDefinition
var player: Player
var weapon: WeaponController
var run_state: RunStateController
var room_runtime: RoomSceneRuntime
var facilities: RunFacilityCoordinator
var wallet: RunWallet

var _active_cooldown := 0.0
var _mara_kill_charge := 0
var _kane_focus := 0
var _kane_chain_left := 0.0
var _kane_decay_left := 0.0
var _kane_base_speed := 260.0
var _kane_free_shots := 0
var _nova_bonus_guard: Dictionary = {}
var _nova_reaction_cooldowns: Dictionary = {}
var _connected_enemy_ids: Dictionary = {}

func configure(definition: CharacterDefinition, player_node: Player, weapon_controller: WeaponController, state: RunStateController, runtime: RoomSceneRuntime, facility_runtime: RunFacilityCoordinator, run_wallet: RunWallet) -> bool:
	if definition == null or player_node == null or state == null:
		return false
	character = definition
	player = player_node
	weapon = weapon_controller
	run_state = state
	room_runtime = runtime
	facilities = facility_runtime
	wallet = run_wallet
	_kane_base_speed = player.max_speed
	_reset_character_state()
	if not player.damaged.is_connected(_on_player_damaged):
		player.damaged.connect(_on_player_damaged)
	if room_runtime != null and not room_runtime.enemy_spawned.is_connected(_on_enemy_spawned):
		room_runtime.enemy_spawned.connect(_on_enemy_spawned)
	if not run_state.room_entered.is_connected(_on_room_entered):
		run_state.room_entered.connect(_on_room_entered)
	if weapon != null and not weapon.shot_fired.is_connected(_on_weapon_shot):
		weapon.shot_fired.connect(_on_weapon_shot)
	_apply_static_character_effects()
	_emit_active_state()
	return true

func _process(delta: float) -> void:
	if character == null or player == null:
		return
	if _active_cooldown > 0.0:
		_active_cooldown = maxf(0.0, _active_cooldown - delta)
	if character.id == &"kane":
		_process_kane_focus(delta)
	_process_reaction_cooldowns(delta)
	if player.input_enabled and Input.is_action_just_pressed("character_active"):
		try_activate()
	_emit_active_state()

func try_activate() -> bool:
	if character == null or player == null or not is_active_ready():
		return false
	match character.id:
		&"mara": return _activate_mara()
		&"kane": return _activate_kane()
		&"nova": return _activate_nova()
		&"rex": return _activate_rex()
	return false

func is_active_ready() -> bool:
	if character == null:
		return false
	if character.id == &"mara":
		return _mara_kill_charge >= MARA_KILLS_PER_CHARGE
	return _active_cooldown <= 0.0

func active_progress() -> Dictionary:
	if character == null:
		return {"current":0.0, "maximum":1.0, "ready":false, "label":""}
	if character.id == &"mara":
		return {"current":float(_mara_kill_charge), "maximum":float(MARA_KILLS_PER_CHARGE), "ready":is_active_ready(), "label":"긴급 수리"}
	var maximum := _cooldown_for_character()
	return {"current":maxf(0.0, maximum - _active_cooldown), "maximum":maximum, "ready":is_active_ready(), "label":_active_label()}

func focus_stacks() -> int:
	return _kane_focus

func _reset_character_state() -> void:
	_active_cooldown = 0.0
	_mara_kill_charge = 0
	_kane_focus = 0
	_kane_chain_left = 0.0
	_kane_decay_left = 0.0
	_kane_free_shots = 0
	_nova_bonus_guard.clear()
	_nova_reaction_cooldowns.clear()
	_connected_enemy_ids.clear()

func _apply_static_character_effects() -> void:
	if player != null:
		player.set_guard(character.starting_guard)
	if weapon != null and character.crit_bonus > 0.0:
		weapon._build_stats["critical_chance"] = float(weapon._build_stats.get("critical_chance", 0.0)) + character.crit_bonus
	if facilities != null:
		facilities.shop_price_multiplier = character.shop_price_multiplier
		facilities.crafting_cost_multiplier = 0.80 if character.id == &"mara" else 1.0
		facilities.free_dismantles_remaining = 1 if character.id == &"mara" else 0
		facilities.sale_multiplier = 1.25 if character.id == &"rex" else 1.0
	if wallet != null:
		wallet.configure_credit(character.id == &"rex", 75 if character.id == &"rex" else 0)

func _process_kane_focus(delta: float) -> void:
	if _kane_focus <= 0:
		return
	_kane_chain_left = maxf(0.0, _kane_chain_left - delta)
	if _kane_chain_left <= 0.0:
		_kane_decay_left -= delta
		if _kane_decay_left <= 0.0:
			_set_kane_focus(_kane_focus - 1)
			_kane_decay_left = 0.85
	var fire_multiplier := 1.0 + _kane_focus * 0.06
	var reload_multiplier := 1.0 + _kane_focus * 0.07
	if weapon != null:
		weapon._fire_cooldown = maxf(0.0, weapon._fire_cooldown - delta * (fire_multiplier - 1.0))
		weapon._burst_timer = maxf(0.0, weapon._burst_timer - delta * (fire_multiplier - 1.0))
		if weapon._is_reloading:
			weapon._reload_left = maxf(0.0, weapon._reload_left - delta * (reload_multiplier - 1.0))
	if player != null:
		player.max_speed = _kane_base_speed * (1.0 + _kane_focus * 0.04)

func _process_reaction_cooldowns(delta: float) -> void:
	for key in _nova_reaction_cooldowns.keys():
		var left := float(_nova_reaction_cooldowns[key]) - delta
		if left <= 0.0:
			_nova_reaction_cooldowns.erase(key)
		else:
			_nova_reaction_cooldowns[key] = left

func _on_enemy_spawned(enemy: Node, _enemy_id: StringName, _wave_index: int) -> void:
	if enemy == null:
		return
	var instance_id := enemy.get_instance_id()
	if _connected_enemy_ids.has(instance_id):
		return
	_connected_enemy_ids[instance_id] = true
	if enemy.has_signal("died"):
		enemy.connect("died", Callable(self, "_on_enemy_died"), CONNECT_ONE_SHOT)
	elif enemy.has_signal("defeated"):
		enemy.connect("defeated", Callable(self, "_on_boss_defeated"), CONNECT_ONE_SHOT)
	if character != null and character.id == &"nova":
		var receiver := _find_status_receiver(enemy)
		if receiver != null and not receiver.status_applied.is_connected(_on_nova_status_applied.bind(receiver)):
			receiver.status_applied.connect(_on_nova_status_applied.bind(receiver))

func _on_enemy_died(enemy: Node) -> void:
	_register_kill(enemy)

func _on_boss_defeated() -> void:
	_register_kill(null)

func _register_kill(_enemy: Node) -> void:
	if character == null:
		return
	match character.id:
		&"mara":
			_mara_kill_charge = mini(MARA_KILLS_PER_CHARGE, _mara_kill_charge + 1)
		&"kane":
			if _kane_chain_left > 0.0:
				_set_kane_focus(_kane_focus + 1)
			else:
				_set_kane_focus(1)
			_kane_chain_left = KANE_CHAIN_WINDOW
			_kane_decay_left = 0.85
	_emit_active_state()

func _on_player_damaged(_amount: float) -> void:
	if character != null and character.id == &"kane" and _kane_focus > 0:
		_set_kane_focus(maxi(0, _kane_focus - 2))
		_kane_chain_left = 0.0
		_kane_decay_left = 0.6

func _set_kane_focus(value: int) -> void:
	_kane_focus = clampi(value, 0, KANE_MAX_FOCUS)
	if _kane_focus == 0 and player != null:
		player.max_speed = _kane_base_speed
	focus_changed.emit(_kane_focus)

func _on_weapon_shot() -> void:
	if _kane_free_shots <= 0 or weapon == null:
		return
	_kane_free_shots -= 1
	weapon.ammo = mini(weapon.magazine_capacity, weapon.ammo + 1)
	weapon.ammo_changed.emit(weapon.ammo, weapon.magazine_capacity, weapon.reserve_ammo)

func _activate_mara() -> bool:
	_mara_kill_charge = 0
	if player.guard < player.max_guard:
		player.add_guard(1)
	else:
		player.heal(15.0)
	_emit_active_state()
	return true

func _activate_kane() -> bool:
	if weapon == null:
		return false
	weapon._is_reloading = false
	weapon._reload_left = 0.0
	weapon.ammo = weapon.magazine_capacity
	weapon.ammo_changed.emit(weapon.ammo, weapon.magazine_capacity, weapon.reserve_ammo)
	weapon.reload_finished.emit()
	_kane_free_shots = weapon.magazine_capacity
	_active_cooldown = KANE_ACTIVE_COOLDOWN
	return true

func _activate_nova() -> bool:
	var candidates: Array[Node] = []
	for enemy in get_tree().get_nodes_in_group(&"enemy"):
		if enemy is Node2D and is_instance_valid(enemy) and player.global_position.distance_squared_to((enemy as Node2D).global_position) <= NOVA_ACTIVE_RADIUS * NOVA_ACTIVE_RADIUS:
			candidates.append(enemy)
	if candidates.is_empty():
		return false
	for enemy in candidates:
		if not enemy.has_method("apply_status_by_id"):
			continue
		var first := NOVA_STATUS_IDS[randi() % NOVA_STATUS_IDS.size()]
		var second := first
		while second == first:
			second = NOVA_STATUS_IDS[randi() % NOVA_STATUS_IDS.size()]
		enemy.call("apply_status_by_id", first, 1)
		enemy.call("apply_status_by_id", second, 1)
	_active_cooldown = NOVA_ACTIVE_COOLDOWN
	return true

func _activate_rex() -> bool:
	if run_state == null or run_state.active_reward_choices.is_empty():
		return false
	var index := 0
	var excluded: Array[StringName] = []
	for offer in run_state.active_reward_choices:
		excluded.append(offer.id)
	var replacement_choices := run_state.reward_selector.generate_choices(1, excluded)
	if replacement_choices.is_empty():
		return false
	var replacement := replacement_choices[0]
	if not (replacement.payload is Dictionary):
		replacement.payload = {"value":replacement.payload}
	replacement.payload["defective"] = true
	replacement.payload["defect_risk"] = 0.35
	run_state.active_reward_choices[index] = replacement
	run_state.reward_choices_ready.emit(run_state.active_reward_choices)
	_active_cooldown = REX_ACTIVE_COOLDOWN
	reward_rerolled.emit(index, replacement)
	return true

func _on_room_entered(_room_id: StringName, room_type: StringName) -> void:
	_nova_reaction_cooldowns.clear()
	_connected_enemy_ids.clear()
	if character == null:
		return
	if character.id == &"mara" and facilities != null:
		facilities.free_dismantles_remaining = 1
	if character.id == &"rex" and room_type == &"shop" and facilities != null:
		facilities.add_defective_shop_offer()

func _on_nova_status_applied(status_id: StringName, added_stacks: int, _total_stacks: int, receiver: StatusReceiver) -> void:
	if character == null or character.id != &"nova" or receiver == null or added_stacks <= 0:
		return
	var receiver_id := receiver.get_instance_id()
	if not _nova_bonus_guard.has(receiver_id) and randf() < maxf(0.0, character.status_buildup_multiplier - 1.0):
		_nova_bonus_guard[receiver_id] = true
		receiver.apply_status(status_id, 1)
		_nova_bonus_guard.erase(receiver_id)
	var host := receiver.get_parent()
	if host == null:
		return
	if (status_id == &"burn" and receiver.has_status(&"cold")) or (status_id == &"cold" and receiver.has_status(&"burn")):
		_trigger_nova_reaction(&"steam_burst", host, receiver_id, 28.0)
	elif (status_id == &"shock" and receiver.has_status(&"corrosion")) or (status_id == &"corrosion" and receiver.has_status(&"shock")):
		_trigger_nova_reaction(&"conductive_corrosion", host, receiver_id, 30.0)
	elif (status_id == &"bleed" and receiver.has_status(&"cold")) or (status_id == &"cold" and receiver.has_status(&"bleed")):
		_trigger_nova_reaction(&"frozen_shred", host, receiver_id, 34.0)

func _trigger_nova_reaction(reaction: StringName, host: Node, receiver_id: int, damage_amount: float) -> void:
	var key := "%d:%s" % [receiver_id, String(reaction)]
	if _nova_reaction_cooldowns.has(key):
		return
	_nova_reaction_cooldowns[key] = 1.0
	if host.has_method("take_damage"):
		host.call("take_damage", damage_amount, Vector2.ZERO)
	if reaction == &"steam_burst" and host is Node2D:
		for enemy in get_tree().get_nodes_in_group(&"enemy"):
			if enemy == host or not (enemy is Node2D) or not enemy.has_method("take_damage"):
				continue
			if (host as Node2D).global_position.distance_squared_to((enemy as Node2D).global_position) <= 150.0 * 150.0:
				enemy.call("take_damage", 16.0, Vector2.ZERO)
	elif reaction == &"conductive_corrosion" and host is Node2D:
		var chained := 0
		for enemy in get_tree().get_nodes_in_group(&"enemy"):
			if enemy == host or not (enemy is Node2D) or not enemy.has_method("take_damage"):
				continue
			if (host as Node2D).global_position.distance_squared_to((enemy as Node2D).global_position) <= 220.0 * 220.0:
				enemy.call("take_damage", 14.0, Vector2.ZERO)
				chained += 1
				if chained >= 2:
					break
	elif reaction == &"frozen_shred" and host.has_method("apply_status_by_id"):
		host.call("apply_status_by_id", &"vulnerable", 1)
	mutation_reaction.emit(reaction, host)

func _find_status_receiver(enemy: Node) -> StatusReceiver:
	if enemy.has_method("status_receiver"):
		return enemy.call("status_receiver") as StatusReceiver
	for child in enemy.get_children():
		if child is StatusReceiver:
			return child as StatusReceiver
	return null

func _active_label() -> String:
	match character.id:
		&"mara": return "긴급 수리"
		&"kane": return "전술 재장전"
		&"nova": return "강제 변이"
		&"rex": return "가격 조작"
	return String(character.active_id)

func _cooldown_for_character() -> float:
	match character.id:
		&"kane": return KANE_ACTIVE_COOLDOWN
		&"nova": return NOVA_ACTIVE_COOLDOWN
		&"rex": return REX_ACTIVE_COOLDOWN
	return 1.0

func _emit_active_state() -> void:
	var data := active_progress()
	active_state_changed.emit(bool(data.get("ready", false)), float(data.get("current", 0.0)), float(data.get("maximum", 1.0)), String(data.get("label", "")))
