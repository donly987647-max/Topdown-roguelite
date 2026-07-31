from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
required = [
    'project.godot', 'scenes/main/Main.tscn',
    'scripts/main/main.gd',
    'scripts/input/input_router.gd', 'scripts/player/player_controller.gd',
    'scripts/combat/health_component.gd', 'scripts/weapons/service_pistol.gd',
    'scripts/weapons/weapon_frame_data.gd', 'scripts/weapons/weapon_frame_catalog.gd',
    'scripts/weapons/weapon_part_data.gd', 'scripts/weapons/weapon_part_catalog.gd',
    'scripts/weapons/weapon_build_calculator.gd', 'scripts/weapons/prototype_weapon.gd',
    'scripts/rewards/weapon_part_reward_picker.gd',
    'scripts/inventory/backpack_item_data.gd', 'scripts/inventory/backpack_grid.gd',
    'scripts/routes/route_room_data.gd', 'scripts/routes/prototype_route_run.gd',
    'scripts/projectiles/projectile.gd', 'scripts/projectiles/projectile_data.gd',
    'scripts/enemies/training_gunner.gd', 'scripts/world/test_room.gd',
    'scripts/camera/combat_camera.gd', 'scripts/ui/mobile_touch_controls.gd',
    'scripts/ui/weapon_reward_panel.gd', 'scripts/ui/backpack_cell.gd',
    'scripts/ui/backpack_panel.gd', 'scripts/ui/route_choice_panel.gd',
    'scripts/ui/route_status_panel.gd',
    'tests/p1_test_runner.gd', 'tests/p2_weapon_test_runner.gd',
    'tests/p2_reward_test_runner.gd', 'tests/p2_inventory_test_runner.gd',
    'tests/p2_loadout_persistence_test_runner.gd', 'tests/p2_route_test_runner.gd',
    'tests/p2_route_runtime_test_runner.gd'
]
missing = [p for p in required if not (root / p).exists()]
if missing:
    raise SystemExit('Missing required files: ' + ', '.join(missing))

project = (root / 'project.godot').read_text(encoding='utf-8')
assert 'run/main_scene="res://scenes/main/Main.tscn"' in project
assert 'InputRouter=' in project

player = (root / 'scripts/player/player_controller.gd').read_text(encoding='utf-8')
checks = {
    'MOVE_SPEED': r'MOVE_SPEED := 260\.0',
    'DASH_DURATION': r'DASH_DURATION := 0\.52',
    'DASH_DISTANCE': r'DASH_DISTANCE := 150\.0',
    'DASH_COOLDOWN': r'DASH_COOLDOWN := 0\.35',
}
for name, pattern in checks.items():
    if not re.search(pattern, player):
        raise SystemExit(f'GDD constant mismatch: {name}')
for literal in ['get_move_speed_multiplier', 'get_dash_distance_multiplier']:
    if literal not in player:
        raise SystemExit('Player overload movement link missing: ' + literal)

legacy_pistol = (root / 'scripts/weapons/service_pistol.gd').read_text(encoding='utf-8')
for literal in ['BASE_DAMAGE := 18.0', 'FIRE_INTERVAL := 0.24', 'MAGAZINE_CAPACITY := 10', 'RELOAD_TIME := 1.15']:
    if literal not in legacy_pistol:
        raise SystemExit('Service pistol regression mismatch: ' + literal)

frame_data = (root / 'scripts/weapons/weapon_frame_data.gd').read_text(encoding='utf-8')
for literal in ['max_power', 'max_weight', 'stability']:
    if literal not in frame_data:
        raise SystemExit('P2 frame assembly limit missing: ' + literal)

catalog = (root / 'scripts/weapons/weapon_frame_catalog.gd').read_text(encoding='utf-8')
for literal in [
    'data.frame_id = &"service_pistol"',
    'data.base_damage = 18.0',
    'data.fire_interval = 0.24',
    'data.magazine_capacity = 10',
    'data.frame_id = &"burst_carbine"',
    'data.base_damage = 11.0',
    'data.burst_count = 3',
    'data.burst_interval = 0.08',
    'data.burst_recovery = 0.32',
    'data.magazine_capacity = 24',
    'data.frame_id = &"breach_shotgun"',
    'data.base_damage = 7.0',
    'data.pellet_count = 8',
    'data.fire_interval = 0.75',
    'data.magazine_capacity = 5',
    'data.max_power =', 'data.max_weight =', 'data.stability =',
]:
    if literal not in catalog:
        raise SystemExit('P2 weapon catalog mismatch: ' + literal)

part_catalog = (root / 'scripts/weapons/weapon_part_catalog.gd').read_text(encoding='utf-8')
for literal in [
    '&"precision_barrel"', '&"spread_barrel"', '&"piercing_barrel"', '&"ricochet_barrel"',
    '&"extended_magazine"', '&"lightweight_magazine"', '&"compressed_magazine"', '&"reverse_magazine"',
    '&"impact_core"', '&"photon_core"', '&"clone_core"', '&"flame_core"',
    '"spread_degrees": 0.65', '"pellet_count": 2.0', '"pierce_count": 2.0',
    '"ricochet_count": 2.0', '"magazine_capacity": 1.60', '"ammo_cost": 2',
    '"reverse_round_damage_decay": 0.03', '"status_type": &"burn"',
]:
    if literal not in part_catalog:
        raise SystemExit('P2 weapon part catalog mismatch: ' + literal)

calculator = (root / 'scripts/weapons/weapon_build_calculator.gd').read_text(encoding='utf-8')
for literal in ['power_overload_ratio', 'weight_overload_ratio', 'misfire_chance', 'move_speed_multiplier', 'dash_distance_multiplier']:
    if literal not in calculator:
        raise SystemExit('P2 overload compiler missing: ' + literal)

prototype = (root / 'scripts/weapons/prototype_weapon.gd').read_text(encoding='utf-8')
for literal in [
    'WeaponBuildCalculator.compile', 'equip_frame_with_parts', 'pierce_damage_decay',
    'ricochet_damage_multiplier', 'clone_chance', 'status_type', '_roll_misfire',
    'get_move_speed_multiplier', 'get_dash_distance_multiplier'
]:
    if literal not in prototype:
        raise SystemExit('P2 weapon part runtime missing: ' + literal)

projectile = (root / 'scripts/projectiles/projectile.gd').read_text(encoding='utf-8')
for literal in ['_remaining_ricochets', 'direction.bounce', 'apply_status_buildup', 'pierce_damage_decay']:
    if literal not in projectile:
        raise SystemExit('P2 projectile modifier runtime missing: ' + literal)

reward_picker = (root / 'scripts/rewards/weapon_part_reward_picker.gd').read_text(encoding='utf-8')
for literal in ['roll_options', 'excluded_ids', 'replace_slot', 'equipped_ids']:
    if literal not in reward_picker:
        raise SystemExit('P2 reward picker contract missing: ' + literal)

reward_panel = (root / 'scripts/ui/weapon_reward_panel.gd').read_text(encoding='utf-8')
for literal in ['part_selected', 'KEY_1', 'KEY_2', 'KEY_3', 'get_tree().paused = true']:
    if literal not in reward_panel:
        raise SystemExit('P2 reward UI contract missing: ' + literal)

backpack_item = (root / 'scripts/inventory/backpack_item_data.gd').read_text(encoding='utf-8')
for literal in ['base_cells', 'cells_for_rotation', 'connector_types', 'precision_barrel', 'compressed_magazine', 'clone_core']:
    if literal not in backpack_item:
        raise SystemExit('P2 backpack item profile missing: ' + literal)

backpack_grid = (root / 'scripts/inventory/backpack_grid.gd').read_text(encoding='utf-8')
for literal in [
    'WIDTH := 6', 'HEIGHT := 5', 'can_place', 'place_item', 'rotate_item',
    'auto_place', 'auto_arrange', 'create_snapshot', 'restore_snapshot',
    'evaluate_connections', 'TERMINAL_CELLS'
]:
    if literal not in backpack_grid:
        raise SystemExit('P2 backpack grid contract missing: ' + literal)

backpack_panel = (root / 'scripts/ui/backpack_panel.gd').read_text(encoding='utf-8')
for literal in [
    'BackpackCell', 'equip_requested', 'loadout_restore_requested',
    'ROTATE [R]', 'AUTO PLACE', 'AUTO ARRANGE', 'RESTORE',
    'get_tree().paused = true'
]:
    if literal not in backpack_panel:
        raise SystemExit('P2 backpack UI contract missing: ' + literal)

route_data = (root / 'scripts/routes/route_room_data.gd').read_text(encoding='utf-8')
for literal in ['enum RoomType', 'COMBAT', 'ELITE', 'BOSS_GATE', 'enemy_health_multiplier', 'enemy_damage_multiplier', 'reward_tier']:
    if literal not in route_data:
        raise SystemExit('P2 route room data contract missing: ' + literal)

route_run = (root / 'scripts/routes/prototype_route_run.gd').read_text(encoding='utf-8')
for literal in [
    'TOTAL_ROOMS := 8', 'get_next_options', 'choose_next', 'get_progress_snapshot',
    '&"assembly_entry"', '&"crusher_bypass"', '&"overclocked_cell"',
    '&"foreman_gate"', '&"gr01_antechamber"'
]:
    if literal not in route_run:
        raise SystemExit('P2 eight-room route contract missing: ' + literal)

route_panel = (root / 'scripts/ui/route_choice_panel.gd').read_text(encoding='utf-8')
for literal in ['RESTART_ID', 'SELECT NEXT ROUTE', 'ROUTE COMPLETE', 'KEY_1', 'KEY_2', 'route_selected']:
    if literal not in route_panel:
        raise SystemExit('P2 route choice UI contract missing: ' + literal)

route_status = (root / 'scripts/ui/route_status_panel.gd').read_text(encoding='utf-8')
for literal in ['update_progress', 'ROOM %d/%d', 'current_room']:
    if literal not in route_status:
        raise SystemExit('P2 route status HUD contract missing: ' + literal)

room = (root / 'scripts/world/test_room.gd').read_text(encoding='utf-8')
for literal in [
    'reward_requested', 'room_cleared', '_active_enemy_count', '_offer_reward',
    'can_open_inventory', 'configure(profile', 'carried_player', 'enemy_health_multiplier',
    'enemy_damage_multiplier', 'BOSS_GATE'
]:
    if literal not in room:
        raise SystemExit('P2 route-aware room contract missing: ' + literal)

enemy = (root / 'scripts/enemies/training_gunner.gd').read_text(encoding='utf-8')
for literal in ['health_multiplier', 'damage_multiplier', 'elite_rank', 'data.damage = 10.0 *']:
    if literal not in enemy:
        raise SystemExit('P2 route threat scaling missing: ' + literal)

main = (root / 'scripts/main/main.gd').read_text(encoding='utf-8')
for literal in [
    'WeaponRewardPanel', '_on_reward_requested', 'WeaponPartRewardPicker.replace_slot',
    'BackpackGrid.new', 'BackpackPanel.new', '_on_backpack_equip_requested',
    'add_and_auto_place', 'inventory_requested', 'PrototypeRouteRun.new',
    'RouteChoicePanel.new', '_transition_to_room', 'route_run.choose_next',
    'route_status.update_progress'
]:
    if literal not in main:
        raise SystemExit('P2 reward, backpack or route connection missing: ' + literal)

mobile = (root / 'scripts/ui/mobile_touch_controls.gd').read_text(encoding='utf-8')
for literal in [
    'InputEventScreenTouch', 'InputEventScreenDrag', 'pulse_mobile_dash',
    'pulse_mobile_reload', 'pulse_mobile_weapon_next', 'inventory_requested', 'BAG'
]:
    if literal not in mobile:
        raise SystemExit('Mobile control contract missing: ' + literal)

input_router = (root / 'scripts/input/input_router.gd').read_text(encoding='utf-8')
for literal in ['weapon_slot_1', 'weapon_slot_2', 'weapon_slot_3', 'weapon_next', 'inventory']:
    if literal not in input_router:
        raise SystemExit('Weapon or inventory input action missing: ' + literal)

exports = (root / 'export_presets.cfg').read_text(encoding='utf-8')
if 'name="Android"' not in exports:
    raise SystemExit('Android export preset missing')

print('P1 regression and P2 weapon, overload, reward, backpack and eight-room route structure validated.')
