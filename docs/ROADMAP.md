# LAST MAGAZINE implementation roadmap

This roadmap follows the GDD development stages. The repository reset deliberately starts with mechanics, readability, and architecture before content volume.

## Phase 0 — reboot baseline

- [x] Godot 4.7.1 clean project
- [x] 720×1280 portrait-first mobile viewport baseline
- [x] GameManager / EventBus
- [x] 260 px/s responsive movement
- [x] independent aim
- [x] mobile twin-stick input + dodge/reload touch controls
- [x] 0.52 s dodge / 0.12–0.34 s invulnerability window
- [x] 100 HP and 0.75 s post-hit protection
- [x] magazine / reserve ammo / reload
- [x] Perfect Reload timing hook
- [x] continuous ray-checked projectile travel
- [x] Scrap Runner AI
- [x] Bolt Shooter AI with telegraphed 3-round burst
- [x] wave encounter director
- [x] portrait combat HUD
- [x] data-driven JSON definitions
- [x] Web export + GitHub Pages
- [x] Android arm64 debug APK CI export

## Phase 1 — GDD core prototype (in progress)

Target: 10–15 minute playable run.

1. Weapon architecture — **playable slice complete / balance provisional**
   - [x] Frame / Barrel / Magazine / Core composition
   - [x] power, weight, stability, overload penalties
   - [x] three weapon frames
   - [x] twelve interchangeable parts (4 barrels + 4 magazines + 4 cores)
   - [x] touch-friendly BUILD workshop and live stat comparison
   - [x] 192-combination automated resolver audit
   - [ ] persist assembly state in save data
   - [ ] final compatibility tags and balance lock
2. Effect pipeline — **partial**
   - [x] shot / projectile hit / kill events
   - [x] reload start / complete / perfect events
   - [x] weapon-build-changed event
   - [x] Fire / Frost / Electric / Corrosion combat effects
   - [ ] generalized pre-shot / post-shot modifier pipeline
   - [ ] crit event and crit resolver
   - [ ] dodge / perfect dodge / damaged / room-clear effect hooks
3. Inventory — **next**
   - [ ] 6×5 grid placement
   - [ ] item rotation
   - [ ] adjacency and connector graph
   - [ ] power routing
   - [ ] touch drag / tap controls
   - [ ] save / restore
4. Rooms
   - [ ] 8 room templates
   - [ ] sealed combat state
   - [ ] reward selection
   - [ ] route selection
5. Enemies
   - [ ] 5 distinct roles
   - [ ] threat-budget spawning
   - [ ] separation / wall recovery
6. Economy
   - [ ] scrap drops
   - [ ] shop
   - [ ] simple crafting room
7. Boss
   - [ ] temporary GR-01 prototype
   - [ ] telegraphs + three health phases

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
