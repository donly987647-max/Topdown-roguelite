class_name CraftingController
extends RefCounted

signal crafted(recipe_id: StringName, result: Variant)
signal craft_failed(reason: String)

var wallet: RunWallet
var recipes: Dictionary = {}

func configure(run_wallet: RunWallet) -> void:
	wallet = run_wallet

func register_recipe(recipe_id: StringName, scrap_cost: int, payload: Variant) -> void:
	if recipe_id == &"":
		return
	recipes[recipe_id] = {"scrap_cost": maxi(0, scrap_cost), "payload": payload}

func craft(recipe_id: StringName, grant_callable: Callable) -> bool:
	if wallet == null:
		craft_failed.emit("wallet_missing")
		return false
	if not recipes.has(recipe_id):
		craft_failed.emit("recipe_missing")
		return false
	var recipe: Dictionary = recipes[recipe_id]
	var cost := int(recipe.get("scrap_cost", 0))
	if not wallet.spend(cost):
		craft_failed.emit("insufficient_scrap")
		return false
	var payload = recipe.get("payload")
	if not grant_callable.is_valid() or not bool(grant_callable.call(payload)):
		wallet.add(cost)
		craft_failed.emit("grant_failed")
		return false
	crafted.emit(recipe_id, payload)
	return true
