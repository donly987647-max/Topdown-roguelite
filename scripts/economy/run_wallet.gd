class_name RunWallet
extends RefCounted

signal scrap_changed(current: int)

var scrap := 0

func add(amount: int) -> int:
	if amount <= 0:
		return scrap
	scrap += amount
	scrap_changed.emit(scrap)
	return scrap

func add_currency(currency_id: StringName, amount: int) -> int:
	if currency_id != &"scrap":
		return 0
	return add(amount)

func get_currency(currency_id: StringName) -> int:
	return scrap if currency_id == &"scrap" else 0

func can_afford(cost: int) -> bool:
	return cost >= 0 and scrap >= cost

func spend(cost: int) -> bool:
	if cost < 0 or scrap < cost:
		return false
	scrap -= cost
	scrap_changed.emit(scrap)
	return true

func spend_currency(currency_id: StringName, cost: int) -> bool:
	return currency_id == &"scrap" and spend(cost)

func serialize() -> Dictionary:
	return {"scrap": scrap}

func restore(data: Dictionary) -> bool:
	var value := int(data.get("scrap", 0))
	if value < 0:
		return false
	scrap = value
	scrap_changed.emit(scrap)
	return true
