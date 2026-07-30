#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "project.godot",
    "scenes/main/Main.tscn",
    "scripts/main/main.gd",
    "autoload/event_bus.gd",
    "autoload/game_state.gd",
    "core/constants.gd",
    "docs/PROJECT_STRUCTURE.md",
    "docs/DEFINITION_OF_DONE.md",
]

missing = [path for path in REQUIRED if not (ROOT / path).is_file()]
project = (ROOT / "project.godot").read_text(encoding="utf-8")
checks = {
    "main scene configured": 'run/main_scene="res://scenes/main/Main.tscn"' in project,
    "EventBus autoload configured": 'EventBus="*res://autoload/event_bus.gd"' in project,
    "GameState autoload configured": 'GameState="*res://autoload/game_state.gd"' in project,
    "Godot 4.6 feature declared": 'PackedStringArray("4.6"' in project,
}

if missing:
    print("Missing files:")
    for path in missing:
        print(f"- {path}")
if not all(checks.values()):
    print("Configuration failures:")
    for name, passed in checks.items():
        if not passed:
            print(f"- {name}")

if missing or not all(checks.values()):
    sys.exit(1)

print("Foundation structure validation: PASS")
for name in checks:
    print(f"- {name}")
