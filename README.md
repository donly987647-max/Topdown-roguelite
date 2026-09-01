# LAST MAGAZINE

GDD-driven reboot of the original Topdown-roguelite repository.

**Engine:** Godot 4.x  
**Target:** Windows PC / Steam  
**Genre:** 2D top-down bullet-hell action roguelite

## Current playable core

This repository was reset on 2026-09-01 and rebuilt from zero around the GDD's non-negotiable pillars:

- responsive 260 px/s movement
- independent mouse/gamepad aim
- 0.52 s dodge with timed invulnerability
- magazine + reserve ammo + reload loop
- perfect-reload timing window
- continuous projectile ray checks to reduce tunneling
- role-based enemy AI (Scrap Runner / Bolt Shooter)
- telegraphed enemy attacks
- wave encounter director
- combat HUD
- data-driven weapon/enemy definitions
- event bus foundation for item/effect hooks

No external art assets are required for the prototype; gameplay objects are drawn procedurally so the core loop can be tested immediately.

## Run

1. Open the repository folder in Godot 4.x.
2. Run the project (`F6/F5`).
3. Controls:
   - Move: `WASD` / left stick
   - Aim: mouse / right stick
   - Fire: left mouse / RT
   - Dodge: `Space` / gamepad B
   - Reload: `R` / gamepad X
   - Pause: `Esc`

## Next milestone

Build the GDD **Core Prototype**: 3 weapon frames, 12 parts, 5 enemies, 8 room templates, reward choice, grid inventory, shop, and a simple boss for a 10–15 minute run.

See `docs/ROADMAP.md` for implementation order.
