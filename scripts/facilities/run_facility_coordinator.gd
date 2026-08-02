class_name RunFacilityCoordinator
extends Node

signal facility_opened(facility_type: StringName)
signal facility_closed
signal shop_stock_ready(stock: Array)
signal transaction_completed(kind: StringName, detail: Variant)
signal transaction_failed(kind: StringName, reason: String)

var run_state: RunStateController
var wallet := RunWallet.new()
var shop := ShopController.new()
var crafting := CraftingController.new()
var medical := MedicalController.new()
var active_facility: StringName = &""
var shop_price_multiplier := 1.0
var crafting_cost_multiplier := 1.0
var sale_multiplier := 1.0
var free_dismantles_remaining := 0

func configure(state: RunStateController, run_wallet: RunWallet = null) -> bool:
	if state == null:
		return false
	run_state = state
	if run_wallet != null:
		wallet = run_wallet
	shop.configure(wallet)
	crafting.configure(wallet)
	medical.configure(wallet)
	if not run_state.room_entered.is_connected(_on_room_entered):
		run_state.room_entered.connect(_on_room_entered)
	_seed_default_recipes()
	return true

func set_shop_offers(offers: Array[RewardOffer], base_price: int = 25) -> void:
	var entries: Array[Dictionary] = []
	for index in range(offers.size()):
		var offer := offers[index]
		if offer == null:
			continue
		entries.append({
			"offer": offer,
			"price": maxi(1, int(round((base_price + index * 8 + _rarity_surcharge(offer.rarity)) * shop_price_multiplier))),
			"sold": false,
			"defective": bool(offer.payload.get("defective", false)) if offer.payload is Dictionary else false,
		})
	shop.set_stock(entries)
	shop_stock_ready.emit(shop.stock)

func refresh_character_modifiers() -> void:
	crafting.set_cost_multiplier(crafting_cost_multiplier)
	if not shop.stock.is_empty():
		var offers: Array[RewardOffer] = []
		for entry in shop.stock:
			var offer = entry.get("offer")
			if offer is RewardOffer:
				offers.append(offer)
		set_shop_offers(offers)

func purchase_shop(index: int) -> bool:
	var ok := shop.buy(index, Callable(self, "_grant_offer"))
	if ok:
		transaction_completed.emit(&"shop", index)
	else:
		transaction_failed.emit(&"shop", "purchase_failed")
	return ok

func craft_recipe(recipe_id: StringName) -> bool:
	crafting.set_cost_multiplier(crafting_cost_multiplier)
	var ok := crafting.craft(recipe_id, Callable(self, "_grant_payload"))
	if ok:
		transaction_completed.emit(&"crafting", recipe_id)
	else:
		transaction_failed.emit(&"crafting", "craft_failed")
	return ok

func buy_medical_heal(cost: int = 22, fraction: float = 0.35) -> bool:
	var player = run_state.run_context.get("player") if run_state != null else null
	var ok := medical.heal_player(player, cost, fraction)
	if ok:
		transaction_completed.emit(&"medical", &"heal")
	else:
		transaction_failed.emit(&"medical", "heal_failed")
	return ok

func buy_medical_shield(cost: int = 18, amount: float = 18.0) -> bool:
	var player = run_state.run_context.get("player") if run_state != null else null
	var ok := medical.grant_shield(player, cost, amount)
	if ok:
		transaction_completed.emit(&"medical", &"shield")
	else:
		transaction_failed.emit(&"medical", "shield_failed")
	return ok

func dismantle_owned_reward(index: int) -> bool:
	if run_state == null:
		return false
	var owned = run_state.run_context.get("owned_rewards")
	if not (owned is Array) or index < 0 or index >= owned.size():
		return false
	var inventory = run_state.run_context.get("inventory")
	if inventory != null and inventory.has_method("can_remove_owned_record") and not bool(inventory.call("can_remove_owned_record", index)):
		transaction_failed.emit(&"dismantle", "equipped_or_protected")
		return false
	var processing_cost := 0 if free_dismantles_remaining > 0 else 6
	if processing_cost > 0 and not wallet.spend(processing_cost):
		transaction_failed.emit(&"dismantle", "insufficient_scrap")
		return false
	var raw = owned[index]
	var rarity := StringName(raw.get("rarity", "common")) if raw is Dictionary else &"common"
	var yield_amount := int(round(_dismantle_value(rarity) * sale_multiplier))
	if inventory != null and inventory.has_method("remove_owned_record"):
		if not bool(inventory.call("remove_owned_record", index)):
			if processing_cost > 0:
				wallet.add(processing_cost)
			transaction_failed.emit(&"dismantle", "remove_failed")
			return false
	else:
		owned.remove_at(index)
	wallet.add(yield_amount)
	if free_dismantles_remaining > 0:
		free_dismantles_remaining -= 1
	transaction_completed.emit(&"dismantle", {"yield":yield_amount, "free_left":free_dismantles_remaining})
	return true

func sell_owned_reward(index: int) -> bool:
	if run_state == null:
		return false
	var owned = run_state.run_context.get("owned_rewards")
	if not (owned is Array) or index < 0 or index >= owned.size():
		return false
	var inventory = run_state.run_context.get("inventory")
	if inventory != null and inventory.has_method("can_remove_owned_record") and not bool(inventory.call("can_remove_owned_record", index)):
		transaction_failed.emit(&"sell", "equipped_or_protected")
		return false
	var raw = owned[index]
	var rarity := StringName(raw.get("rarity", "common")) if raw is Dictionary else &"common"
	var value := int(round(_dismantle_value(rarity) * 1.35 * sale_multiplier))
	if inventory != null and inventory.has_method("remove_owned_record"):
		if not bool(inventory.call("remove_owned_record", index)):
			transaction_failed.emit(&"sell", "remove_failed")
			return false
	else:
		owned.remove_at(index)
	wallet.add(value)
	transaction_completed.emit(&"sell", value)
	return true

func add_defective_shop_offer() -> bool:
	if shop.stock.is_empty():
		return false
	for entry in shop.stock:
		if bool(entry.get("defective", false)):
			return true
	var source_entry: Dictionary = shop.stock[randi() % shop.stock.size()]
	var source = source_entry.get("offer")
	if not (source is RewardOffer):
		return false
	var payload: Dictionary = source.payload.duplicate(true) if source.payload is Dictionary else {"value":source.payload}
	payload["defective"] = true
	payload["defect_risk"] = 0.35
	var defective := RewardOffer.new(StringName("%s_defective" % String(source.id)), source.category, source.rarity, payload, source.weight)
	var entry := {
		"offer": defective,
		"price": maxi(1, int(round(int(source_entry.get("price", 20)) * 0.70))),
		"sold": false,
		"defective": true,
	}
	shop.stock.append(entry)
	shop.stock_changed.emit(shop.stock)
	shop_stock_ready.emit(shop.stock)
	return true

func close_facility() -> void:
	if active_facility == &"":
		return
	active_facility = &""
	facility_closed.emit()

func _on_room_entered(_room_id: StringName, room_type: StringName) -> void:
	active_facility = &""
	if room_type in [&"shop", &"crafting", &"medical"]:
		active_facility = room_type
		crafting.set_cost_multiplier(crafting_cost_multiplier)
		facility_opened.emit(room_type)

func _grant_offer(offer: Variant) -> bool:
	if not (offer is RewardOffer) or run_state == null:
		return false
	var context := run_state.run_context.duplicate(false)
	context["offer"] = offer
	var ok := run_state.reward_grant_resolver.grant(offer, context)
	if ok:
		run_state.reward_selector.claim(offer, run_state.build_tags)
	return ok

func _grant_payload(payload: Variant) -> bool:
	if run_state == null or not (payload is Dictionary):
		return false
	var category := StringName(payload.get("category", "item"))
	var synthetic := RewardOffer.new(StringName("facility_%s" % String(category)), category, &"common", payload, 1.0)
	return _grant_offer(synthetic)

func _seed_default_recipes() -> void:
	crafting.register_recipe(&"ammo_bundle", 18, {"category":"ammo", "amount":18})
	crafting.register_recipe(&"shield_patch", 24, {"category":"shield", "amount":16})
	crafting.register_recipe(&"guard_plate", 28, {"category":"guard", "amount":1})

func _rarity_surcharge(rarity: StringName) -> int:
	match rarity:
		&"uncommon": return 8
		&"rare": return 18
		&"epic": return 34
		&"legendary": return 58
	return 0

func _dismantle_value(rarity: StringName) -> int:
	match rarity:
		&"uncommon": return 14
		&"rare": return 22
		&"epic": return 34
		&"legendary": return 52
	return 9
