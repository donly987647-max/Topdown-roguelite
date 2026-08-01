# LAST MAGAZINE — Project Roadmap & Handoff

> Operational source of truth for development continuity. Read this file before changing the project in any future conversation.

## Goal
Build **LAST MAGAZINE** from scratch as a commercially releasable 2D top-down bullet-hell action roguelite for Windows PC / Steam in Godot 4.x. Target: paid Steam 1.0 quality, not prototype quality.

Core identity:
- Fast, precise top-down gun combat
- Manual weapon construction with frames and parts
- 6×5 spatial backpack
- Adjacency / connector / power-routing synergies
- Room-based roguelite runs
- Skill-first combat and high build variety

## Canonical Design Source
`LAST_MAGAZINE_GDD.md` is the design source of truth. Do not silently redesign major systems. Intentional deviations must be recorded under Design Decisions. The discarded legacy prototype must not be restored.

## Development Quality Rules
- Production-quality architecture over throwaway demo hacks.
- A feature is not done merely because it executes.
- Each feature must work in play, handle obvious edge cases, avoid error spam, remain maintainable, and support expansion.
- Do not mass-produce content before core combat and the core game loop pass their quality gates.
- Code changes and progress-document updates are one development unit.
- Do not interrupt the user for routine micro-decisions. Build a substantial playable checkpoint first, then request focused feedback.

## User Playtest / APK Policy
PC/Steam remains the primary release target, but Android is a supported development/playtest target.

Rules:
1. Gameplay logic is shared between PC and Android.
2. PC input: keyboard/mouse.
3. Android input: virtual movement stick + aim/fire stick + dash/reload controls.
4. Do not ask the user to verify tiny intermediate changes.
5. At a meaningful checkpoint, provide Android APK when a compatible build environment is available.
6. APK feedback should focus on high-value feel questions, not implementation details.
7. Android release signing credentials must never be committed.

## Milestones
### M1 — Core Combat Prototype (Phases 0–5)
1. Project foundation
2. Player movement/collision
3. Mouse aim
4. Firing
5. Magazine/reload
6. Dash/i-frames
7. Damage/HP/death
8. Basic enemy AI
9. Combat room
10. Combat feedback/polish

Acceptance: moving, aiming, shooting, dodging and fighting must already be enjoyable, readable and predictable.

### M2 — Core Game Prototype (Phases 6–13)
`Combat → Reward → Gun Construction → Backpack → Route Choice → Combat → Boss`

### M3 — Commercial Vertical Slice
One representative production-quality zone slice suitable for Steam store/trailer footage.

### M4 — Alpha
Full run playable start-to-ending; major systems complete; all zones structurally present.

### M5 — Beta
Content complete; balance; accessibility; controller; localization; Steam features; performance; save validation; external testing.

### M6 — Release Candidate / Steam 1.0
Feature freeze; zero known progression blockers/save corruption/major collision defects; stable performance; complete KBM/controller runs; validated Steam packaging.

## Full Phase Order
0 Foundation → 1 Player → 2 Gun Combat → 3 Enemy Framework → 4 Combat Readability → 5 Combat Rooms → 6 Run/Route → 7 Weapon Frames → 8 Gun Construction → 9 6×5 Backpack → 10 Backpack Synergies → 11 Reward Economy → 12 Facilities → 13 Boss Framework → 14 Complete Run → 15 Meta Progression → 16 Content Architecture → 17 Full Content → 18 Production Art → 19 VFX/Audio/Music → 20 UI/UX → 21 Tutorial → 22 Save → 23 Controller → 24 Settings/Accessibility → 25 Balance → 26 Optimization → 27 QA → 28 Steam Integration → 29 Store Assets → 30 Release Candidate → 31 Steam 1.0 → 32 Post-launch.

## Current Development State
**Last updated:** 2026-08-01

**Current milestone:** `M1 — Core Combat Prototype`

**Current working phase:** `Phase 4/5 — Combat Readability + Combat Room flow`, with core Phase 1–3 implementation present but runtime acceptance still pending.

### Implemented
Foundation:
- Clean Godot project bootstrap and main scene.
- 1920×1080 internal viewport.
- 60 Hz physics tick.
- Named collision layers.
- Windows/Android playtest export presets.

Player:
- 8-direction normalized movement.
- Acceleration/deceleration.
- Mouse aim.
- World collision.
- Dash, cooldown and i-frame timing hooks.
- HP, damage, knockback and death.
- Player hurt flash.
- Mobile move/aim input overrides.

Gun combat:
- Reusable `WeaponController`.
- Automatic/semi-auto hook.
- Magazine/ammo state.
- Manual and empty-mag reload.
- Spread.
- Projectile speed/damage configuration.
- Projectile lifetime, world/enemy collision, damage, knockback and piercing hook.

Enemies:
- Stationary damage target dummy.
- Chaser melee-pressure archetype with pursuit/contact damage.
- Ranged enemy archetype with preferred/retreat distance behavior.
- Enemy projectile scene and player damage path.
- Enemy HP, hit flash, knockback and death cleanup.

Combat room:
- Combat lab arena.
- Wave 1: pre-placed Chasers.
- Wave 2: dynamically spawned Ranged enemies from room spawn markers.
- Wave transition delay.
- Enemy tracking and room-clear detection.
- Lockable room-door components.
- Doors lock while combat is active and unlock on final clear.
- Reward scene spawned after final clear.
- Reward collection event.
- HUD updates for wave, hostiles, room clear and reward collection.

Android controls:
- Shared gameplay code with mobile input layer.
- Left movement touch zone.
- Right aim/fire touch zone.
- Aim threshold to fire.
- Dash and reload touch buttons.
- Hidden automatically on desktop.

### New primary files
- `scripts/combat/enemy_projectile.gd`
- `scenes/combat/EnemyProjectile.tscn`
- `scripts/enemies/ranged_enemy.gd`
- `scenes/enemies/RangedEnemy.tscn`
- `scripts/rooms/room_door.gd`
- `scenes/rooms/RoomDoor.tscn`
- `scripts/rewards/reward_pickup.gd`
- `scenes/rewards/RewardPickup.tscn`

### Validation status
The current environment has not executed the Godot project. Therefore implementation exists, but runtime acceptance is not claimed.

Required runtime validation before user review:
- Parse all scenes/scripts.
- Verify player movement/collision and dash.
- Verify projectile collision masks.
- Verify reload timing.
- Verify Chaser contact damage.
- Verify Ranged enemy spacing/fire cadence.
- Verify enemy projectile → player damage path.
- Verify wave 1 → wave 2 transition.
- Verify final room clear, door unlock and reward spawn.
- Verify reward collection signal.
- Verify Android multitouch and export/install/startup.

### Known technical debt / pending work
- No Godot runtime test yet.
- No automated headless validation/CI.
- Ranged enemy currently fires directly without a pre-shot telegraph; add readable wind-up before M1 acceptance.
- Doors are functional blockers/indicators but the combat lab is not yet connected to neighboring rooms.
- Reward is still a prototype salvage pickup, not the final GDD reward-choice system.
- No camera shake/muzzle flash/audio layer yet.
- Placeholder geometric visuals only.
- Mobile control sizing requires physical-device tuning.
- Android APK not yet produced/device-tested.

## Next Work — execute without asking for routine confirmation
1. Add ranged-enemy pre-shot telegraph and cancel behavior.
2. Add muzzle flash and limited hit-impact feedback.
3. Add lightweight debug overlay for player state, enemy count, wave and input mode.
4. Add room-entry/exit hooks so door lock/unlock can later connect to multiple rooms.
5. Add first structured reward-choice prototype instead of a single pickup.
6. Introduce data-driven Resource definitions before enemy/weapon content count grows.
7. Runtime-validate and repair the M1 combat lab when Godot execution becomes available.
8. Stabilize Android controls and produce APK at the first meaningful feedback checkpoint.
9. Ask user only for feel feedback: movement, dash, shooting, enemy pressure/readability, mobile ergonomics.
10. Iterate until M1 acceptance passes, then enter M2.

## M1 Quality Gate Checklist
- [x] Clean fresh project baseline implemented
- [x] Player movement/collision implementation
- [x] Mouse aim implementation
- [x] Dash/i-frame implementation
- [x] Player HP/damage/death implementation
- [x] Gun firing pipeline implementation
- [x] Magazine/reload implementation
- [x] Projectile/damage pipeline implementation
- [x] Melee-pressure enemy implementation
- [x] Ranged enemy implementation
- [x] Enemy projectile implementation
- [x] Multi-wave combat-room implementation
- [x] Door lock/unlock implementation
- [x] Room-clear reward spawn implementation
- [x] Basic HUD implementation
- [x] Android touch-input foundation implementation
- [ ] Ranged attack telegraph pass
- [ ] Muzzle/impact readability pass
- [ ] Godot runtime parsing/functional validation
- [ ] Android APK device validation
- [ ] M1 playtest acceptance

## Definition of Done
For each task:
- Works in actual play once runtime validation is available.
- No obvious error spam.
- Relevant edge cases handled.
- Architecture supports expansion.
- User-facing behavior is understandable.
- `PROJECT.md` updated.

Milestones require gameplay quality acceptance, not technical completion alone.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean restart confirmed.
- 2026-08-01: Steam 1.0 commercial quality is the end target.
- 2026-08-01: Code changes and progress-document updates are one development unit.
- 2026-08-01: Android is a development/playtest target; PC/Steam remains primary release target.
- 2026-08-01: User review requests are batched at meaningful checkpoints; provide APK when feedback is required and build tooling is available.
- 2026-08-01: PC and Android share gameplay code; platform differences belong in input/presentation layers.
- 2026-08-01: M1 combat room uses two deliberately different pressure types: melee Chaser wave followed by Ranged wave.

## Continuation Protocol
1. Read `PROJECT.md` first.
2. Read `LAST_MAGAZINE_GDD.md` for design/content/balance behavior.
3. Inspect current repository state before coding.
4. Continue from the first incomplete item in `Next Work` unless priority changes.
5. Never restore discarded prototype code.
6. Do not ask for frequent confirmation.
7. Update this document after meaningful implementation.

Suggested continuation prompt:
`@GitHub LAST MAGAZINE 이어서 개발해. PROJECT.md와 GDD를 먼저 읽고 Next Work의 첫 미완료 작업부터 진행해.`

## Progress Log
### 2026-08-01 — Fresh restart
- Previous project removed.
- New Godot bootstrap created.
- Steam-quality roadmap/handoff policy established.

### 2026-08-01 — M1 player foundation
- Added movement, aim, dash, i-frame, HP/damage/death hooks.

### 2026-08-01 — M1 gun combat and Android input foundation
- Added weapon controller, projectile pipeline, magazine/reload, HUD, Chaser enemy and Android controls.

### 2026-08-01 — M1 wave/ranged/reward expansion
- Added Ranged enemy and enemy projectiles.
- Added two-wave combat flow.
- Added combat room door lock/unlock components.
- Added room-clear salvage reward and collection state.
- Added player hurt flash and expanded HUD wave/reward feedback.
- Runtime and APK validation remain pending before user feedback is requested.
