# LAST MAGAZINE — Project Roadmap & Handoff

> Operational source of truth. Read this file before changing the project in any future conversation.

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
`LAST_MAGAZINE_GDD.md` is the design source of truth. Do not silently redesign major systems. Intentional deviations belong under Design Decisions. Never restore the discarded legacy prototype as an implementation/design authority.

## Development / Playtest Rules
- Production-quality architecture over throwaway demo hacks.
- Implementation is not acceptance; runtime feel/quality gates still matter.
- Code changes and progress-document updates are one development unit.
- Do not ask the user to verify tiny intermediate changes. Build a substantial checkpoint first.
- PC/Steam remains the primary release target.
- Android is a supported development/playtest target using the same gameplay code.
- At a meaningful review checkpoint, provide an Android APK when a compatible build environment is available.
- Never commit Android signing credentials.

## Milestones
- **M1 — Core Combat Prototype:** foundation, player, gun combat, enemies, readability, combat-room loop.
- **M2 — Core Game Prototype:** `Combat → Reward → Gun Construction → Backpack → Route Choice → Combat → Boss`.
- **M3 — Commercial Vertical Slice:** one representative zone at store/trailer quality.
- **M4 — Alpha:** full run structurally playable start-to-ending.
- **M5 — Beta:** content complete, balance, accessibility, controller, localization, Steam, performance, saves, external testing.
- **M6 — RC / Steam 1.0:** feature freeze and release validation.

## Full Phase Order
0 Foundation → 1 Player → 2 Gun Combat → 3 Enemy Framework → 4 Combat Readability → 5 Combat Rooms → 6 Run/Route → 7 Weapon Frames → 8 Gun Construction → 9 6×5 Backpack → 10 Backpack Synergies → 11 Reward Economy → 12 Facilities → 13 Boss Framework → 14 Complete Run → 15 Meta Progression → 16 Content Architecture → 17 Full Content → 18 Production Art → 19 VFX/Audio/Music → 20 UI/UX → 21 Tutorial → 22 Save → 23 Controller → 24 Settings/Accessibility → 25 Balance → 26 Optimization → 27 QA → 28 Steam Integration → 29 Store Assets → 30 RC → 31 Steam 1.0 → 32 Post-launch.

## Current Development State
**Last updated:** 2026-08-01

**Current milestone:** `M1 — Core Combat Prototype`

**Current working phase:** `Phase 4/5 — Combat Readability + Combat Room flow`.

### Implemented
Foundation / player:
- Clean Godot project, 1920×1080 internal viewport, 60 Hz physics, named collision layers.
- WASD movement, normalized diagonal movement, acceleration/deceleration, mouse aim.
- Dash, cooldown, i-frame hook, HP, damage, knockback, death and hurt flash.
- Android left-stick movement, right-stick aim/fire, dash and reload controls.
- Windows and Android playtest export presets.

Gun combat:
- Reusable `WeaponController`.
- Automatic/semi-auto hook, fire cadence, magazine/reload, spread.
- Player projectile lifetime, collision, damage, knockback and piercing hook.
- Muzzle flash visual and `shot_fired` feedback hook.

Enemies:
- Target dummy.
- Chaser melee-pressure archetype.
- Ranged spacing archetype.
- Enemy projectile → player damage path.
- Ranged pre-shot telegraph/wind-up with visible aiming line before projectile release.
- Enemy HP, hit flash, knockback and death cleanup.

Combat room:
- Wave 1 Chasers → Wave 2 dynamically spawned Ranged enemies.
- Spawn markers, wave transition delay and enemy tracking.
- Doors lock during combat and unlock after final clear.
- Room-clear reward spawn and collection event.
- HUD for HP, ammo, reload, wave, hostiles, clear/reward status.
- Debug HUD for FPS, enemy count, player speed, dash cooldown, i-frame timer and desktop/mobile input mode.

### Validation status
The current ChatGPT environment has not executed the Godot project, so runtime acceptance is **still pending**. Implemented means code/scene structure exists in GitHub, not that feel or parsing has been accepted.

Runtime/device validation required before user review:
- Scene/script parse.
- Movement/collision/dash feel.
- Projectile masks and damage paths.
- Reload timing.
- Chaser pressure and Ranged spacing.
- Ranged telegraph readability and projectile cadence.
- Wave transition, door state and reward spawn.
- Muzzle/hurt feedback.
- Android multitouch, install and startup.

### Known technical debt / pending work
- No actual Godot runtime validation yet.
- No automated headless CI yet.
- Reward is still a single prototype salvage pickup rather than GDD reward choice.
- No production audio or camera shake yet.
- Placeholder geometry visuals only.
- Mobile layout still requires physical-device tuning.
- Android APK has not yet been produced/device-tested.
- Data-driven Resource definitions should be introduced before weapon/enemy content scales further.

## Next Work — continue without routine confirmation
1. Add first structured reward-choice prototype (three mutually exclusive choices).
2. Add lightweight impact feedback and bounded camera-shake hook.
3. Add room entry/exit transition hooks for future multi-room routing.
4. Introduce data Resources for weapon/enemy/reward definitions before content scale-up.
5. Add automated/headless parse validation if repository CI tooling permits it.
6. Runtime-validate and repair M1 in a real Godot environment.
7. Stabilize Android controls and export/install a playtest APK.
8. Ask user only for high-value feel judgment: movement, dash, shooting, enemy pressure/readability, mobile ergonomics.
9. Iterate until M1 quality gate passes, then enter M2.

## M1 Quality Gate Checklist
- [x] Fresh project baseline
- [x] Player movement/collision
- [x] Mouse aim
- [x] Dash/i-frame implementation
- [x] HP/damage/death
- [x] Gun firing pipeline
- [x] Magazine/reload
- [x] Projectile/damage pipeline
- [x] Chaser enemy
- [x] Ranged enemy + enemy projectile
- [x] Ranged pre-shot telegraph implementation
- [x] Multi-wave combat room
- [x] Door lock/unlock
- [x] Room-clear reward spawn
- [x] Basic combat HUD
- [x] Debug HUD
- [x] Player hurt + muzzle feedback hooks
- [x] Android touch-input foundation
- [ ] Structured reward choice
- [ ] Impact/camera feedback pass
- [ ] Godot runtime parsing/functional validation
- [ ] Android APK device validation
- [ ] M1 user playtest acceptance

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean restart confirmed.
- 2026-08-01: Steam 1.0 commercial quality is the end target.
- 2026-08-01: Code changes and progress-document updates are one unit.
- 2026-08-01: Android is a development/playtest target; PC/Steam stays primary.
- 2026-08-01: User review is batched at meaningful checkpoints and should use APK when practical.
- 2026-08-01: PC and Android share gameplay code; platform differences stay in input/presentation.
- 2026-08-01: M1 uses deliberately different melee and ranged pressure waves.

## Continuation Protocol
1. Read `PROJECT.md` first.
2. Read `LAST_MAGAZINE_GDD.md` for design/content/balance behavior.
3. Inspect current repository state before coding.
4. Continue from the first incomplete item in Next Work unless priority changes.
5. Never restore discarded prototype code.
6. Do not ask for frequent confirmation.
7. Update this document after meaningful implementation.

Suggested continuation prompt:
`@GitHub LAST MAGAZINE 이어서 개발해. PROJECT.md와 GDD를 먼저 읽고 Next Work의 첫 미완료 작업부터 진행해.`

## Progress Log
### 2026-08-01 — Fresh restart
- Previous project removed; new Godot bootstrap and Steam-quality roadmap created.

### 2026-08-01 — M1 player / gun / Android foundation
- Added movement, aim, dash/i-frame, HP/damage/death, weapon controller, projectiles, magazine/reload and Android controls.

### 2026-08-01 — M1 room/ranged expansion
- Added Chaser/Ranged pressure types, enemy projectiles, two-wave room flow, doors and room-clear reward.

### 2026-08-01 — M1 readability expansion
- Added Ranged pre-shot telegraph.
- Added player muzzle flash feedback hook.
- Added expanded debug HUD for runtime tuning.
- Runtime and APK validation remain pending before user feedback is requested.
