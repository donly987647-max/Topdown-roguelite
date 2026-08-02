class_name RunWallet
extends RefCounted

signal scrap_changed(current: int)
signal debt_changed(current: int, limit: int)

var scrap := 0
var debt := 0
var debt_limit := 0
var debt_enabled := false

func reset(value: int = 0) -> void:
	scrap = maxi(0, value)
	debt = 0
	debt_limit = 0
	debt_enabled = false
	scrap_changed.emit(scrap)
	debt_changed.emit(debt, debt_limit)

func configure_credit(enabled: bool, limit: int = 0) -> void:
	debt_enabled = enabled
	debt_limit = maxi(0, limit) if enabled else 0
	if not enabled:
		debt = 0
	debt_changed.emit(debt, debt_limit)

func available_credit() -> int:
	return maxi(0, debt_limit - debt) if debt_enabled else 0

func add(amount: int) -> int:
	if amount <= 0:
		return scrap
	var remaining := amount
	if debt > 0:
		var repayment := mini(debt, remaining)
		debt -= repayment
		remaining -= repayment
		debt_changed.emit(debt, debt_limit)
	if remaining > 0:
		scrap += remaining
		scrap_changed.emit(scrap)
	return scrap

func add_currency(currency_id: StringName, amount: int) -> int:
	if currency_id != &"scrap":
		return 0
	return add(amount)

func get_currency(currency_id: StringName) -> int:
	return scrap if currency_id == &"scrap" else 0

func can_afford(cost: int) -> bool:
	if cost < 0:
		return false
	return scrap + available_credit() >= cost

func spend(cost: int) -> bool:
	if cost < 0 or not can_afford(cost):
		return false
	if scrap >= cost:
		scrap -= cost
		scrap_changed.emit(scrap)
		return true
	var shortfall := cost - scrap
	scrap = 0
	debt += shortfall
	scrap_changed.emit(scrap)
	debt_changed.emit(debt, debt_limit)
	return true

func spend_currency(currency_id: StringName, cost: int) -> bool:
	return currency_id == &"scrap" and spend(cost)

func serialize() -> Dictionary:
	return {
		"scrap": scrap,
		"debt": debt,
		"debt_limit": debt_limit,
		"debt_enabled": debt_enabled,
	}

func restore(data: Dictionary) -> bool:
	var value := int(data.get("scrap", 0))
	var restored_debt := int(data.get("debt", 0))
	var restored_limit := int(data.get("debt_limit", 0))
	if value < 0 or restored_debt < 0 or restored_limit < 0 or restored_debt > restored_limit:
		return false
	scrap = value
	debt = restored_debt
	debt_limit = restored_limit
	debt_enabled = bool(data.get("debt_enabled", restored_limit > 0))
	scrap_changed.emit(scrap)
	debt_changed.emit(debt, debt_limit)
	return true
