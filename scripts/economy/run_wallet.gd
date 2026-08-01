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

func can_afford(cost: int) -> bool:
	return cost >= 0 and scrap >= cost

func spend(cost: int) -> bool:
	if cost < 0 or scrap < cost:
		return false
	scrap -= cost
	scrap_changed.emit(scrap)
	return true

func serialize() -> Dictionary:
	return {"scrap": scrap}

func restore(data: Dictionary) -> bool:
	var value := int(data.get("scrap", 0))
	if value < 0:
		return false
	scrap = value
	scrap_changed.emit(scrap)
	return true
