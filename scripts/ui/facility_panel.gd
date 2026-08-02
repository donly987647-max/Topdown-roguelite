class_name FacilityPanel
extends Control

signal modal_state_changed(open: bool)

var facilities: RunFacilityCoordinator
var wallet: RunWallet
var bootstrap: Zone1RunBootstrap

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var wallet_label: Label = $Panel/Margin/VBox/Wallet
@onready var items: VBoxContainer = $Panel/Margin/VBox/Items
@onready var message_label: Label = $Panel/Margin/VBox/Message
@onready var close_button: Button = $Panel/Margin/VBox/Close

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)

func configure(run_bootstrap: Zone1RunBootstrap) -> bool:
	bootstrap = run_bootstrap
	if bootstrap == null or bootstrap.facilities == null:
		return false
	facilities = bootstrap.facilities
	wallet = bootstrap.wallet
	if not facilities.facility_opened.is_connected(_on_facility_opened): facilities.facility_opened.connect(_on_facility_opened)
	if not facilities.facility_closed.is_connected(close): facilities.facility_closed.connect(close)
	if not facilities.transaction_completed.is_connected(_on_transaction_completed): facilities.transaction_completed.connect(_on_transaction_completed)
	if not facilities.transaction_failed.is_connected(_on_transaction_failed): facilities.transaction_failed.connect(_on_transaction_failed)
	if not facilities.shop_stock_ready.is_connected(_on_shop_stock_ready): facilities.shop_stock_ready.connect(_on_shop_stock_ready)
	if wallet != null:
		if not wallet.scrap_changed.is_connected(_on_wallet_changed): wallet.scrap_changed.connect(_on_wallet_changed)
		if not wallet.debt_changed.is_connected(_on_debt_changed): wallet.debt_changed.connect(_on_debt_changed)
	_refresh_wallet()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func close() -> void:
	if not visible:
		return
	visible = false
	message_label.text = ""
	modal_state_changed.emit(false)

func _on_facility_opened(facility_type: StringName) -> void:
	visible = true
	message_label.text = ""
	title_label.text = _facility_title(facility_type)
	_rebuild(facility_type)
	_refresh_wallet()
	modal_state_changed.emit(true)
	_grab_first_focus()

func _rebuild(facility_type: StringName) -> void:
	for child in items.get_children(): child.queue_free()
	match facility_type:
		&"shop": _build_shop()
		&"crafting": _build_crafting()
		&"medical": _build_medical()

func _build_shop() -> void:
	for index in range(facilities.shop.stock.size()):
		var entry: Dictionary = facilities.shop.stock[index]
		var offer = entry.get("offer")
		if not (offer is RewardOffer): continue
		var button := Button.new()
		button.focus_mode = Control.FOCUS_ALL
		button.disabled = bool(entry.get("sold", false))
		var defect := "  ⚠ 결함" if bool(entry.get("defective", false)) else ""
		button.text = "%s  · %d 고철%s" % [_offer_title(offer), int(entry.get("price", 0)), defect]
		button.tooltip_text = _offer_description(offer)
		button.pressed.connect(func():
			facilities.purchase_shop(index)
			_rebuild(&"shop")
			_refresh_wallet())
		items.add_child(button)
	if facilities.run_state != null:
		var owned = facilities.run_state.run_context.get("owned_rewards")
		if owned is Array and not owned.is_empty():
			var sell_index := _first_removable_owned_index()
			var sell := Button.new()
			sell.focus_mode = Control.FOCUS_ALL
			sell.disabled = sell_index < 0
			sell.text = "판매 가능한 첫 보유품 판매" if sell_index >= 0 else "장착/보호 품목은 판매 불가"
			sell.pressed.connect(func():
				facilities.sell_owned_reward(sell_index)
				_refresh_wallet())
			items.add_child(sell)

func _build_crafting() -> void:
	for raw_id in facilities.crafting.recipes.keys():
		var recipe_id := StringName(raw_id)
		var recipe: Dictionary = facilities.crafting.recipes[recipe_id]
		var button := Button.new()
		button.focus_mode = Control.FOCUS_ALL
		button.text = "%s  · %d 고철" % [String(recipe_id).replace("_", " ").capitalize(), facilities.crafting.effective_cost(recipe_id)]
		button.tooltip_text = str(recipe.get("payload", {}))
		button.pressed.connect(func():
			facilities.craft_recipe(recipe_id)
			_refresh_wallet())
		items.add_child(button)
	if facilities.run_state != null:
		var owned = facilities.run_state.run_context.get("owned_rewards")
		if owned is Array and not owned.is_empty():
			var dismantle_index := _first_removable_owned_index()
			var dismantle := Button.new()
			dismantle.focus_mode = Control.FOCUS_ALL
			dismantle.disabled = dismantle_index < 0
			dismantle.text = "판매 가능한 첫 보유품 분해%s" % [" · 무료" if facilities.free_dismantles_remaining > 0 else " · 수수료 6"] if dismantle_index >= 0 else "장착/보호 품목은 분해 불가"
			dismantle.pressed.connect(func():
				facilities.dismantle_owned_reward(dismantle_index)
				_rebuild(&"crafting")
				_refresh_wallet())
			items.add_child(dismantle)

func _build_medical() -> void:
	var heal := Button.new()
	heal.focus_mode = Control.FOCUS_ALL
	heal.text = "응급 치료 · 22 고철 · 최대 HP 35%"
	heal.pressed.connect(func(): facilities.buy_medical_heal(22, 0.35); _refresh_wallet())
	items.add_child(heal)
	var shield := Button.new()
	shield.focus_mode = Control.FOCUS_ALL
	shield.text = "임시 보호막 · 18 고철 · +18"
	shield.pressed.connect(func(): facilities.buy_medical_shield(18, 18.0); _refresh_wallet())
	items.add_child(shield)

func _on_transaction_completed(kind: StringName, detail: Variant) -> void:
	message_label.text = "%s 완료: %s" % [String(kind).capitalize(), str(detail)]
	_refresh_wallet()

func _on_transaction_failed(kind: StringName, reason: String) -> void:
	message_label.text = "%s 실패: %s" % [String(kind).capitalize(), reason]
	_refresh_wallet()

func _on_shop_stock_ready(_stock: Array) -> void:
	if visible and facilities.active_facility == &"shop": _rebuild(&"shop")

func _on_wallet_changed(_value: int) -> void:
	_refresh_wallet()

func _on_debt_changed(_value: int, _limit: int) -> void:
	_refresh_wallet()

func _refresh_wallet() -> void:
	if wallet == null:
		wallet_label.text = ""
		return
	wallet_label.text = "고철 %d" % wallet.scrap
	if wallet.debt > 0:
		wallet_label.text += "  · 빚 %d / %d" % [wallet.debt, wallet.debt_limit]
	elif wallet.debt_enabled:
		wallet_label.text += "  · 외상 한도 %d" % wallet.available_credit()

func _grab_first_focus() -> void:
	await get_tree().process_frame
	for child in items.get_children():
		if child is Button and not (child as Button).disabled:
			(child as Button).grab_focus()
			return
	close_button.grab_focus()

func _facility_title(id: StringName) -> String:
	match id:
		&"shop": return "상점"
		&"crafting": return "제작실"
		&"medical": return "의료실"
	return String(id).capitalize()

func _offer_title(offer: RewardOffer) -> String:
	if offer.payload is Dictionary and not String(offer.payload.get("name", "")).is_empty():
		return String(offer.payload.get("name"))
	return String(offer.id).replace("_", " ").capitalize()

func _offer_description(offer: RewardOffer) -> String:
	if offer.payload is Dictionary:
		return String(offer.payload.get("description", ""))
	return ""

func _first_removable_owned_index() -> int:
	if facilities == null or facilities.run_state == null:
		return -1
	var inventory = facilities.run_state.run_context.get("inventory")
	if inventory != null and inventory.has_method("first_removable_record_index"):
		return int(inventory.call("first_removable_record_index"))
	var owned = facilities.run_state.run_context.get("owned_rewards")
	return 0 if owned is Array and not owned.is_empty() else -1
