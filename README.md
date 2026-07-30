# LAST MAGAZINE

Official Godot production line for the 2D top-down action roguelite **LAST MAGAZINE**.

## Current stage

**P1 Pre-production — combat prototype candidate**

The archived HTML prototype is reference material only and is not a production-code dependency.

## Engine

- Godot 4.6.x
- GDScript
- GL Compatibility renderer during pre-production
- Primary target: Windows / Steam
- Provisional internal viewport: 960×540

## Run

1. Install Godot 4.6.x.
2. Import `project.godot`.
3. Run `scenes/main/Main.tscn`.
4. Use WASD, mouse, left click, Space, R and F5.

## Current playable scope

- movement, independent aiming and dash;
- temporary shield, armor and health damage order;
- service pistol, reload and swept projectiles;
- telegraphed training gunner AI;
- handmade 20×12 combat room;
- camera lead, shake, hit feedback and prototype audio;
- headless P1 tests.

See [`docs/P1_IMPLEMENTATION.md`](docs/P1_IMPLEMENTATION.md) for implemented and blocked backlog items. P1 is not passed until the manual five-minute gate is approved.

## Rules

- No feature is called complete without executable evidence.
- No generated quantity counts as unique content without unique behavior and testing.
- `final`, `release` and `1.0` remain prohibited before their matching gates.
