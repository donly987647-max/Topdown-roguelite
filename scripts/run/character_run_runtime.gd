class_name CharacterRunRuntime
extends RefCounted

const BASE_MOVE_SPEED := 260.0

var selected: CharacterDefinition

func apply(character: CharacterDefinition, player: Player, wallet: RunWallet, context: Dictionary, grant_starting_resources: bool = true) -> bool:
	if character == null or not character.validate_definition().is_empty():
		return false
	selected = character
	if player != null:
		player.max_health = character.max_health
		if grant_starting_resources or player.health <= 0.0:
			player.health = character.max_health
			player.health_changed.emit(player.health, player.max_health)
		player.max_speed = BASE_MOVE_SPEED * character.move_speed_multiplier
		if grant_starting_resources:
			player.set_guard(character.starting_guard)
		player.set_meta("character_id", character.id)
		player.set_meta("crit_bonus", character.crit_bonus)
		player.set_meta("status_buildup_multiplier", character.status_buildup_multiplier)
		player.set_meta("healing_multiplier", character.healing_multiplier)
	if wallet != null and grant_starting_resources and character.starting_scrap > 0:
		wallet.add(character.starting_scrap)
	context["character_id"] = character.id
	context["starting_frame_id"] = character.starting_frame_id
	context["character_passive_id"] = character.passive_id
	context["character_active_id"] = character.active_id
	context["shop_price_multiplier"] = character.shop_price_multiplier
	return true

func serialize() -> Dictionary:
	return {"character_id": String(selected.id) if selected != null else ""}
