class_name MedicalController
extends RefCounted

signal treatment_applied(treatment_id: StringName)
signal treatment_failed(reason: String)

var wallet: RunWallet

func configure(run_wallet: RunWallet) -> void:
	wallet = run_wallet

func heal_player(player: Node, scrap_cost: int, fraction: float = 0.35) -> bool:
	if wallet == null or player == null:
		treatment_failed.emit("missing_dependency")
		return false
	if not wallet.spend(maxi(0, scrap_cost)):
		treatment_failed.emit("insufficient_scrap")
		return false
	var max_health = player.get("max_health")
	var health = player.get("health")
	if not (max_health is float or max_health is int) or not (health is float or health is int):
		wallet.add(maxi(0, scrap_cost))
		treatment_failed.emit("player_health_contract_missing")
		return false
	player.set("health", minf(float(max_health), float(health) + float(max_health) * clampf(fraction, 0.0, 1.0)))
	treatment_applied.emit(&"heal")
	return true

func grant_shield(player: Node, scrap_cost: int, amount: float) -> bool:
	if wallet == null or player == null or not player.has_method("add_temporary_shield"):
		treatment_failed.emit("shield_contract_missing")
		return false
	if not wallet.spend(maxi(0, scrap_cost)):
		treatment_failed.emit("insufficient_scrap")
		return false
	player.call("add_temporary_shield", maxf(0.0, amount))
	treatment_applied.emit(&"shield")
	return true
