class_name ShopController
extends RefCounted

signal stock_changed(stock: Array)
signal purchased(entry: Dictionary)
signal purchase_failed(reason: String)

var wallet: RunWallet
var stock: Array[Dictionary] = []

func configure(run_wallet: RunWallet) -> void:
	wallet = run_wallet

func set_stock(entries: Array[Dictionary]) -> void:
	stock = entries.duplicate(true)
	stock_changed.emit(stock)

func buy(index: int, grant_callable: Callable) -> bool:
	if wallet == null:
		purchase_failed.emit("wallet_missing")
		return false
	if index < 0 or index >= stock.size():
		purchase_failed.emit("invalid_index")
		return false
	var entry := stock[index]
	if bool(entry.get("sold", false)):
		purchase_failed.emit("sold")
		return false
	var price := maxi(0, int(entry.get("price", 0)))
	if not wallet.spend(price):
		purchase_failed.emit("insufficient_scrap")
		return false
	var granted := grant_callable.is_valid() and bool(grant_callable.call(entry.get("offer", entry)))
	if not granted:
		wallet.add(price)
		purchase_failed.emit("grant_failed")
		return false
	entry["sold"] = true
	stock[index] = entry
	purchased.emit(entry)
	stock_changed.emit(stock)
	return true
