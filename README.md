# LAST MAGAZINE

GDD-driven reboot of the original Topdown-roguelite repository.

**Engine:** Godot 4.7.1  
**Primary development target:** Android / mobile portrait  
**Secondary target:** Windows PC / Steam  
**Genre:** 2D top-down bullet-hell action roguelite

## Current playable core

This repository was reset on 2026-09-01 and rebuilt from zero around the GDD's non-negotiable pillars:

- 720×1280 portrait-first mobile layout
- responsive 260 px/s base movement
- mobile twin-stick combat controls
- left virtual stick: movement
- right virtual stick: aim + fire
- dedicated touch buttons: dodge + reload
- keyboard/mouse and gamepad fallback for development
- 0.52 s dodge with timed invulnerability
- magazine + reserve ammo + reload loop
- Perfect Reload timing window
- continuous projectile ray checks to reduce tunneling
- role-based enemy AI (Scrap Runner / Bolt Shooter)
- telegraphed enemy attacks
- wave encounter director
- portrait combat HUD
- data-driven weapon/enemy definitions
- event bus foundation for item/effect hooks

### Weapon assembly prototype

The first GDD weapon-assembly slice is playable from the `BUILD` button:

- 3 frames: Service Pistol, Burst Carbine, Chain SMG
- 4 barrels: Precision, Scatter, Piercing, Ricochet
- 4 magazines: Large, Light, Explosive, Reverse
- 4 cores: Fire, Cooling, Electric, Corrosion
- power / weight / stability calculation
- power-overload reload + misfire penalty
- weight-overload movement + dodge-distance penalty
- modular projectile spread, pierce, ricochet and last-round explosion behavior
- Fire DoT, Frost slow, Electric chain damage and Corrosion vulnerability
- live stat comparison in a touch-friendly paused workshop
- CI regression audit across all 192 frame/part combinations

The GDD defines the part behaviors. Prototype-only power/weight capacities and some secondary tuning values are provisional and must be playtested before balance lock.

No external art assets are required for the prototype; gameplay objects are drawn procedurally so the core loop can be tested immediately.

## Mobile controls

- Left thumb: move
- Right thumb: aim; holding the stick away from center fires automatically
- `DODGE`: evasive roll
- `RELOAD`: reload / Perfect Reload timing input
- `BUILD`: pause and open weapon assembly
- Portrait orientation is the intended mobile layout

## Desktop debug controls

- Move: `WASD` / left stick
- Aim: mouse / right stick
- Fire: left mouse / RT
- Dodge: `Space` / gamepad B
- Reload: `R` / gamepad X
- Weapon assembly: `Tab`
- Pause: `Esc`

## Builds

Every push to `main` imports the Godot project, runs the weapon-assembly regression audit, and exports the Web playtest. Android APK CI runs the same audit before generating `LAST_MAGAZINE_Playtest.apk` as a GitHub Actions artifact.

## Next mobile milestone

Continue the GDD **Core Prototype** with the 6×5 spatial inventory, module placement/rotation/connectors, room rewards, route choice, shop and a simple boss. Every new interaction must be usable without keyboard or mouse.

See `docs/ROADMAP.md` for implementation order.
