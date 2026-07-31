from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
required = [
    'project.godot', 'scenes/main/Main.tscn',
    'scripts/input/input_router.gd', 'scripts/player/player_controller.gd',
    'scripts/combat/health_component.gd', 'scripts/weapons/service_pistol.gd',
    'scripts/weapons/weapon_frame_data.gd', 'scripts/weapons/weapon_frame_catalog.gd',
    'scripts/weapons/weapon_part_data.gd', 'scripts/weapons/weapon_part_catalog.gd',
    'scripts/weapons/weapon_build_calculator.gd', 'scripts/weapons/prototype_weapon.gd',
    'scripts/projectiles/projectile.gd', 'scripts/projectiles/projectile_data.gd',
    'scripts/enemies/training_gunner.gd', 'scripts/world/test_room.gd',
    'scripts/camera/combat_camera.gd', 'scripts/ui/mobile_touch_controls.gd',
    'tests/p1_test_runner.gd', 'tests/p2_weapon_test_runner.gd'
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

legacy_pistol = (root / 'scripts/weapons/service_pistol.gd').read_text(encoding='utf-8')
for literal in ['BASE_DAMAGE := 18.0', 'FIRE_INTERVAL := 0.24', 'MAGAZINE_CAPACITY := 10', 'RELOAD_TIME := 1.15']:
    if literal not in legacy_pistol:
        raise SystemExit('Service pistol regression mismatch: ' + literal)

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

prototype = (root / 'scripts/weapons/prototype_weapon.gd').read_text(encoding='utf-8')
for literal in ['WeaponBuildCalculator.compile', 'equip_frame_with_parts', 'pierce_damage_decay', 'ricochet_damage_multiplier', 'clone_chance', 'status_type']:
    if literal not in prototype:
        raise SystemExit('P2 weapon part runtime missing: ' + literal)

projectile = (root / 'scripts/projectiles/projectile.gd').read_text(encoding='utf-8')
for literal in ['_remaining_ricochets', 'direction.bounce', 'apply_status_buildup', 'pierce_damage_decay']:
    if literal not in projectile:
        raise SystemExit('P2 projectile modifier runtime missing: ' + literal)

mobile = (root / 'scripts/ui/mobile_touch_controls.gd').read_text(encoding='utf-8')
for literal in ['InputEventScreenTouch', 'InputEventScreenDrag', 'pulse_mobile_dash', 'pulse_mobile_reload', 'pulse_mobile_weapon_next']:
    if literal not in mobile:
        raise SystemExit('Mobile control contract missing: ' + literal)

input_router = (root / 'scripts/input/input_router.gd').read_text(encoding='utf-8')
for literal in ['weapon_slot_1', 'weapon_slot_2', 'weapon_slot_3', 'weapon_next']:
    if literal not in input_router:
        raise SystemExit('Weapon input action missing: ' + literal)

exports = (root / 'export_presets.cfg').read_text(encoding='utf-8')
if 'name="Android"' not in exports:
    raise SystemExit('Android export preset missing')

print('P1 regression and P2 weapon-frame/part structure validated.')
