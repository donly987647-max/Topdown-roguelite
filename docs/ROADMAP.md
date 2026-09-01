# LAST MAGAZINE implementation roadmap

This roadmap follows the GDD development stages. The repository reset deliberately starts with mechanics, readability, and architecture before content volume.

## Phase 0 — reboot baseline (current)

- [x] Godot 4.x clean project
- [x] 1280×720 scalable viewport baseline
- [x] GameManager / EventBus
- [x] 260 px/s responsive movement
- [x] independent aim
- [x] 0.52 s dodge / 0.12–0.34 s invulnerability window
- [x] 100 HP and 0.75 s post-hit protection
- [x] Service Pistol
- [x] magazine / reserve ammo / reload
- [x] perfect reload timing hook
- [x] continuous ray-checked projectile travel
- [x] Scrap Runner AI
- [x] Bolt Shooter AI with telegraphed 3-round burst
- [x] wave encounter director
- [x] combat HUD
- [x] data-driven JSON definitions

## Phase 1 — GDD core prototype

Target: 10–15 minute playable run.

1. Weapon architecture
   - Frame / Barrel / Magazine / Core composition
   - power, weight, stability, overload penalties
   - three weapon frames
   - twelve interchangeable parts
2. Effect pipeline
   - pre-shot / post-shot
   - projectile spawn / hit
   - crit / kill
   - reload start / complete / perfect
   - dodge / perfect dodge / damaged / room clear
3. Inventory
   - grid placement
   - rotation
   - adjacency and connector graph
   - power routing
4. Rooms
   - 8 room templates
   - sealed combat state
   - reward selection
   - route selection
5. Enemies
   - 5 distinct roles
   - threat-budget spawning
   - separation / wall recovery
6. Economy
   - scrap drops
   - shop
   - simple crafting room
7. Boss
   - temporary GR-01 prototype
   - telegraphs + three health phases

## Phase 2 — vertical slice

Target: one sale-page-quality Zone 1 run (~20 minutes).

- one production-quality character
- five weapon frames
- twenty-four parts
- twenty modules
- eight enemies
- GR-01 complete boss
- complete UI/settings/save/gamepad loop
- finalized hit feedback baseline
- audio pass

## Non-negotiable QA gates

The GDD explicitly forbids cutting these to save schedule:

- control feel
- hit/dodge accuracy
- save stability
- frame stability
- combat readability
- boss quality
- base UI
- gamepad support
- tutorial
- sound feedback

## Performance target

Design toward worst-case 60 FPS with approximately 30 enemies, 500 player projectiles, 800 enemy projectiles, 1,500 particles and 100 drops. Pooling and off-screen update throttling enter before content scaling, not after.
