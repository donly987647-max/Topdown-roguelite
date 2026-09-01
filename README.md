# LAST MAGAZINE

GDD-driven reboot of the original Topdown-roguelite repository.

**Engine:** Godot 4.7.1  
**Primary development target:** Android / mobile landscape  
**Secondary target:** Windows PC / Steam  
**Genre:** 2D top-down bullet-hell action roguelite

## Current playable core

This repository was reset on 2026-09-01 and rebuilt from zero around the GDD's non-negotiable pillars:

- responsive 260 px/s movement
- mobile twin-stick combat controls
- left virtual stick: movement
- right virtual stick: aim + fire
- dedicated touch buttons: dodge + reload
- keyboard/mouse and gamepad fallback for development
- 0.52 s dodge with timed invulnerability
- magazine + reserve ammo + reload loop
- perfect-reload timing window
- continuous projectile ray checks to reduce tunneling
- role-based enemy AI (Scrap Runner / Bolt Shooter)
- telegraphed enemy attacks
- wave encounter director
- mobile-adjusted combat HUD
- data-driven weapon/enemy definitions
- event bus foundation for item/effect hooks

No external art assets are required for the prototype; gameplay objects are drawn procedurally so the core loop can be tested immediately.

## Mobile controls

- Left thumb: move
- Right thumb: aim; holding the stick away from center fires automatically
- `DODGE`: evasive roll
- `RELOAD`: reload / Perfect Reload timing input
- Landscape orientation is the intended mobile layout

## Desktop debug controls

- Move: `WASD` / left stick
- Aim: mouse / right stick
- Fire: left mouse / RT
- Dodge: `Space` / gamepad B
- Reload: `R` / gamepad X
- Pause: `Esc`

## Builds

Every push to `main` validates and exports the Web playtest. Android APK CI is also configured to generate `LAST_MAGAZINE_Playtest.apk` as a GitHub Actions artifact.

## Next mobile milestone

Build the GDD **Core Prototype** for touch play: 3 weapon frames, 12 parts, 5 enemies, 8 room templates, reward choice, 6×5 grid inventory, shop, and a simple boss for a 10–15 minute run. Every new interaction must be usable without keyboard or mouse.

See `docs/ROADMAP.md` for implementation order.
