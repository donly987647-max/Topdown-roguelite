from pathlib import Path
import re, sys

root = Path(__file__).resolve().parents[1]
required = [
    'project.godot', 'scenes/main/Main.tscn',
    'scripts/input/input_router.gd', 'scripts/player/player_controller.gd',
    'scripts/combat/health_component.gd', 'scripts/weapons/service_pistol.gd',
    'scripts/projectiles/projectile.gd', 'scripts/projectiles/projectile_data.gd',
    'scripts/enemies/training_gunner.gd', 'scripts/world/test_room.gd',
    'scripts/camera/combat_camera.gd', 'tests/p1_test_runner.gd'
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
weapon = (root / 'scripts/weapons/service_pistol.gd').read_text(encoding='utf-8')
for literal in ['BASE_DAMAGE := 18.0', 'FIRE_INTERVAL := 0.24', 'MAGAZINE_CAPACITY := 10', 'RELOAD_TIME := 1.15']:
    if literal not in weapon:
        raise SystemExit('Service pistol mismatch: ' + literal)
print('P1 project structure and GDD constants validated.')
