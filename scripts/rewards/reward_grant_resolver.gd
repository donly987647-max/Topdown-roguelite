class_name RewardGrantResolver
extends RefCounted

signal reward_granted(offer: RewardOffer)

func grant(offer: RewardOffer, context: Dictionary) -> bool:
	if offer == null or offer.id == &"":
		return false
	var payload = offer.payload
	match offer.category:
		&"scrap":
			return _grant_currency(context, "scrap", _payload_amount(payload, 1))
		&"ammo":
			return _grant_ammo(context, _payload_amount(payload, 1))
		&"heal":
			return _grant_heal(context, float(_payload_amount(payload, 10)))
		&"shield":
			return _grant_shield(context, float(_payload_amount(payload, 10)))
		&"backpack_expansion":
			return _grant_backpack_expansion(context, payload)
		&"passive", &"active", &"frame", &"barrel", &"magazine", &"core", &"item":
			return _grant_inventory_item(context, offer)
		&"temporary_buff":
			return _grant_temporary_buff(context, offer)
		_:
			return _grant_inventory_item(context, offer)

func _payload_amount(payload: Variant, fallback: int) -> int:
	if payload is Dictionary:
		return int(payload.get("amount", fallback))
	if payload is int or payload is float:
		return int(payload)
	return fallback

func _grant_currency(context: Dictionary, key: String, amount: int) -> bool:
	var wallet = context.get("wallet")
	if wallet != null and wallet.has_method("add_currency"):
		wallet.add_currency(StringName(key), amount)
		reward_granted.emit(context.get("offer"))
		return true
	if context.has("currencies") and context["currencies"] is Dictionary:
		context["currencies"][key] = int(context["currencies"].get(key, 0)) + amount
		return true
	return false

func _grant_ammo(context: Dictionary, amount: int) -> bool:
	var weapon = context.get("weapon_controller")
	if weapon != null and weapon.has_method("add_reserve_ammo"):
		weapon.add_reserve_ammo(amount)
		return true
	return false

func _grant_heal(context: Dictionary, amount: float) -> bool:
	var player = context.get("player")
	if player == null:
		return false
	var health = player.get("health")
	var maximum = player.get("max_health")
	if (health is float or health is int) and (maximum is float or maximum is int):
		player.set("health", minf(float(maximum), float(health) + amount))
		return true
	return false

func _grant_shield(context: Dictionary, amount: float) -> bool:
	var player = context.get("player")
	if player != null and player.has_method("add_temporary_shield"):
		player.add_temporary_shield(amount)
		return true
	return false

func _grant_backpack_expansion(context: Dictionary, payload: Variant) -> bool:
	var backpack = context.get("backpack_state")
	if backpack == null or not (payload is Dictionary):
		return false
	var raw_cell = payload.get("cell", [])
	if not (raw_cell is Array) or raw_cell.size() < 2:
		return false
	return backpack.grid.add_expansion_cell(Vector2i(int(raw_cell[0]), int(raw_cell[1])))

func _grant_inventory_item(context: Dictionary, offer: RewardOffer) -> bool:
	var inventory = context.get("inventory")
	if inventory != null and inventory.has_method("add_reward_offer"):
		return bool(inventory.add_reward_offer(offer))
	var owned = context.get("owned_rewards")
	if owned is Array:
		owned.append(offer.to_dictionary())
		return true
	return false

func _grant_temporary_buff(context: Dictionary, offer: RewardOffer) -> bool:
	var runtime = context.get("passive_runtime")
	if runtime != null and runtime.has_method("apply_temporary_effect"):
		runtime.apply_temporary_effect(offer.payload)
		return true
	return _grant_inventory_item(context, offer)
