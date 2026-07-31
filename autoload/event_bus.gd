extends Node

signal player_spawned(player: Node)
signal player_stats_changed(snapshot: Dictionary)
signal ammo_changed(current: int, capacity: int, reloading: bool, weapon_name: String)
signal enemy_count_changed(count: int)
signal hit_landed(position: Vector2, strength: float, critical: bool)
signal player_damaged(amount: float, source_position: Vector2)
signal precision_dodge(position: Vector2)
signal screen_shake(strength: float, source_position: Vector2)
signal inventory_requested
signal run_reset_requested
