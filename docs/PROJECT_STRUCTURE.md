# Project structure

## Root services

- `autoload/EventBus`: cross-system signals only
- `autoload/GameState`: current build stage and run-level lifecycle state
- `core/`: constants and non-node shared types

## Runtime domains

- `scenes/`: composed Godot scenes
- `scripts/`: behavior grouped by gameplay domain
- `data/`: typed Godot resources and balance definitions
- `assets/`: production art and audio
- `tests/`: automated smoke, unit and integration checks
- `tools/`: validation and content-pipeline scripts

## Planned scene tree boundaries

1. Application flow
2. Run controller
3. Room graph controller
4. Combat world
5. UI layer
6. Save and settings services

No gameplay system may directly depend on the archived HTML prototype.
