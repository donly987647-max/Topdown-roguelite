class_name RunFacilityCoordinator
extends Node

signal facility_opened(facility_type: StringName)
signal facility_closed
signal shop_stock_ready(stock: Array)

var run_state: RunStateController
var wallet := RunWallet.new()
var shop := ShopController.new()
var crafting := CraftingController.new()
var medical := MedicalController.new()
var active_facility: StringName = &""

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
			"price": maxi(1, base_price + index * 8 + _rarity_surcharge(offer.rarity)),
			"sold": false,
		})
	shop.set_stock(entries)
	shop_stock_ready.emit(entries)

func close_facility() -> void:
	if active_facility == &"":
		return
	active_facility = &""
	facility_closed.emit()

func _on_room_entered(_room_id: StringName, room_type: StringName) -> void:
	active_facility = &""
	if room_type in [&"shop", &"crafting", &"medical"]:
		active_facility = room_type
		facility_opened.emit(room_type)

func _seed_default_recipes() -> void:
	crafting.register_recipe(&"ammo_bundle", 18, {"category":"ammo", "amount":18})
	crafting.register_recipe(&"shield_patch", 24, {"category":"shield", "amount":16})
	crafting.register_recipe(&"scrap_rework", 30, {"category":"reroll_token", "amount":1})

func _rarity_surcharge(rarity: StringName) -> int:
	match rarity:
		&"uncommon": return 8
		&"rare": return 18
		&"epic": return 34
		&"legendary": return 58
	return 0
