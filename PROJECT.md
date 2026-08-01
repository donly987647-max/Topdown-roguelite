# LAST MAGAZINE — Project Roadmap & Handoff

> Operational source of truth for development continuity. Read this file before changing the project in any future conversation.

## Goal
Build **LAST MAGAZINE** from scratch as a commercially releasable 2D top-down bullet-hell action roguelite for Windows PC / Steam in Godot 4.x. The target is paid Steam 1.0 quality, not prototype quality.

Core identity:
- Fast, precise top-down gun combat
- Manual weapon construction with frames and parts
- 6×5 spatial backpack
- Adjacency / connector / power-routing synergies
- Room-based roguelite runs
- Skill-first combat and high build variety

## Canonical Design Source
`LAST_MAGAZINE_GDD.md` is the design source of truth. Do not silently redesign major systems. Intentional deviations must be recorded under Design Decisions. The discarded legacy prototype is not an authority and must not be restored.

## Development Quality Rules
- Production-quality architecture over throwaway demo hacks.
- A feature is not done merely because it executes.
- Each feature must work in play, handle obvious edge cases, avoid error spam, remain maintainable, and support expansion.
- Do not mass-produce content before core combat and the core game loop pass their quality gates.
- Code changes and progress-document updates are one development unit.
- Do not interrupt the user for routine micro-decisions. Develop a substantial playable checkpoint first, then request focused feedback.

## User Playtest / APK Policy
The project is primarily targeting PC/Steam, but development must remain testable on Android because the user may review builds from mobile.

Rules:
1. Keep gameplay logic shared between PC and Android. Do not fork core combat logic into a separate mobile game.
2. PC input: keyboard/mouse.
3. Android input: virtual movement stick + aim/fire stick + dash/reload controls.
4. When user feedback becomes necessary, first implement as much of the current milestone as reasonably possible.
5. Do not ask the user to verify tiny intermediate changes one by one.
6. At a meaningful playtest checkpoint, provide an Android APK when a build environment is available, alongside the exact items that need judgment.
7. Android playtest APKs are test artifacts; Steam/PC remains the primary release target unless the product direction changes.
8. `export_presets.cfg` contains Windows and Android playtest export presets. Android release signing credentials must never be committed.

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
Connect: `Combat → Reward → Gun Construction → Backpack → Route Choice → Combat → Boss`.

### M3 — Commercial Vertical Slice
One representative production-quality zone slice with art, UI, audio and gameplay suitable for Steam store/trailer footage.

### M4 — Alpha
Full run playable start-to-ending; major systems complete; all zones structurally present; content substantially populated.

### M5 — Beta
Content complete; balance; accessibility; controller; localization; Steam features; performance; save validation; external testing.

### M6 — Release Candidate / Steam 1.0
Feature freeze. Zero known progression blockers/save-corruption defects/major collision defects; stable performance; complete KBM/controller runs; validated Steam packaging.

## Full Phase Order
0 Foundation → 1 Player → 2 Gun Combat → 3 Enemy Framework → 4 Combat Readability → 5 Combat Rooms → 6 Run/Route → 7 Weapon Frames → 8 Gun Construction → 9 6×5 Backpack → 10 Backpack Synergies → 11 Reward Economy → 12 Facilities → 13 Boss Framework → 14 Complete Run → 15 Meta Progression → 16 Content Architecture → 17 Full Content → 18 Production Art → 19 VFX/Audio/Music → 20 UI/UX → 21 Tutorial → 22 Save → 23 Controller → 24 Settings/Accessibility → 25 Balance → 26 Optimization → 27 QA → 28 Steam Integration → 29 Store Assets → 30 Release Candidate → 31 Steam 1.0 → 32 Post-launch.

Detailed feature behavior and launch counts remain defined by the GDD.

## Current Development State

**Last updated:** 2026-08-01

**Current milestone:** `M1 — Core Combat Prototype`

**Current working phase:** `Phase 3 — Enemy Combat Framework`, while Phase 2 and an early Phase 5 room-clear slice are implemented but still awaiting runtime validation.

### Implemented in the fresh codebase
Foundation:
- Clean Godot project bootstrap and main scene.
- 1920×1080 internal viewport.
- 60 Hz physics tick foundation.
- Named 2D physics layers for player/world/hurtboxes/projectiles/enemies/attacks/pickups.
- Input actions: WASD movement, mouse fire, Space dash, R reload, E interact.
- Windows and Android playtest export presets.

Player:
- CharacterBody2D player scene.
- 8-direction normalized movement.
- Acceleration/deceleration.
- Mouse aiming and rotating aim pivot.
- World collision.
- Dash, cooldown, direction fallback and invulnerability timer.
- HP, damage reception, hit invulnerability, knockback hook and death state.
- Mobile movement/aim override hooks without forking gameplay logic.

Gun combat:
- Reusable `WeaponController` component.
- Fire cadence.
- Automatic/semi-auto support hook.
- Magazine capacity and ammo state.
- Manual and empty-mag reload behavior.
- Reload progress API/signals.
- Spread.
- Projectile speed/damage configuration.
- Reusable projectile scene.
- Projectile lifetime.
- Damage delivery.
- Knockback delivery.
- Piercing hook.
- World/enemy collision routing.

Enemy/combat target framework:
- Damageable stationary target dummy.
- First active enemy archetype: Chaser.
- Chaser player targeting and acceleration-based pursuit.
- Chaser contact attack, attack cooldown and player knockback.
- Enemy HP, damage response, knockback, hit flash and death cleanup.
- Enemy group registration for room state tracking.

Combat room / UI:
- M1 combat-lab arena with physical boundary walls.
- Multiple stationary damage targets.
- Multiple active Chaser enemies.
- Combat-room controller tracking active enemy exits.
- Room-start and room-clear events.
- HUD for HP, ammo, reload progress and room state.

Android controls:
- Shared Player controller accepts mobile movement/aim overrides.
- Dual touch-zone concept implemented: left movement stick and right aim/fire stick.
- Aim stick automatically fires past a threshold.
- Dedicated dash and reload buttons.
- Mobile controls hidden on non-mobile platforms.
- Action-button touch positions are prevented from becoming aim touches.

### Primary implementation files
- `project.godot`
- `export_presets.cfg`
- `scenes/main/Main.tscn`
- `scripts/main/main.gd`
- `scenes/player/Player.tscn`
- `scripts/player/player.gd`
- `scenes/combat/Projectile.tscn`
- `scripts/combat/projectile.gd`
- `scripts/combat/weapon_controller.gd`
- `scenes/enemies/TargetDummy.tscn`
- `scripts/enemies/target_dummy.gd`
- `scenes/enemies/ChaserEnemy.tscn`
- `scripts/enemies/chaser_enemy.gd`
- `scripts/rooms/combat_room.gd`
- `scenes/ui/MobileControls.tscn`
- `scripts/ui/mobile_controls.gd`

### Validation status
The current environment has written/inspected repository code but has **not executed the Godot project**. Therefore all completed items above mean "implementation exists", not "runtime accepted".

Before requesting user gameplay judgment, use a real Godot runtime/build environment to validate:
- Project/scene/script parsing.
- Player movement and collision.
- Mouse aim and mobile aim.
- Dash timing and i-frames.
- Projectile spawn direction and collision masks.
- Magazine/reload timing.
- Enemy pursuit/contact damage.
- Knockback behavior.
- Enemy death and room-clear event.
- HUD signal wiring.
- Multi-touch behavior on Android.
- Android export/install/startup.

### Known technical debt / pending foundation
- No automated headless validation/CI yet.
- Exact engine version is not pinned in repository metadata; use a verified stable Godot 4.x version compatible with the GDD before CI/release locking.
- No data Resource conventions yet; introduce before weapon/enemy content scales.
- Placeholder geometric visuals only.
- Combat sound/VFX/camera feedback not implemented.
- Enemy ranged/telegraph archetypes not implemented.
- Room door lock/unlock visuals and reward spawn not implemented.
- Mobile control sizes/positions require physical-device tuning.
- Android APK has not yet been produced or device-tested.

## Next Work — execute without asking for routine confirmation
1. Runtime-validate and repair the current M1 combat lab as soon as a Godot execution environment is available.
2. Add combat feedback: muzzle flash, hit feedback, player hurt feedback and controlled camera shake hooks.
3. Add at least one ranged enemy archetype with explicit telegraphing.
4. Add enemy spawn/wave controller instead of only pre-placed enemies.
5. Add actual room lock/clear/unlock state and first reward spawn.
6. Add debug overlay useful for DPS, player state, enemy count and input state.
7. Stabilize Android dual-stick behavior and playtest layout.
8. Produce Android playtest APK at the first meaningful M1 feedback checkpoint.
9. Ask user to judge only high-value feel questions: movement speed, dash feel, aiming/shooting feel, enemy pressure/readability, mobile control ergonomics.
10. Iterate until M1 acceptance passes before entering M2 systems.

## M1 Quality Gate Checklist
Implementation status is separated from runtime acceptance.

- [x] Clean fresh project baseline implemented
- [x] Player movement implementation
- [x] World collision implementation
- [x] Mouse aim implementation
- [x] Dash/i-frame implementation
- [x] Player HP/damage/death implementation
- [x] Gun firing pipeline implementation
- [x] Magazine/reload implementation
- [x] Projectile/damage pipeline implementation
- [x] First enemy AI implementation
- [x] Basic combat-room clear controller implementation
- [x] Basic HP/ammo/reload/room HUD implementation
- [x] Android touch-input foundation implementation
- [ ] Godot runtime parsing/functional validation
- [ ] Combat readability/feedback pass
- [ ] Ranged telegraphed enemy
- [ ] Wave/spawn flow
- [ ] Door/reward room flow
- [ ] Android APK device validation
- [ ] M1 playtest acceptance

## Definition of Done
For every implementation task:
- Works in actual play once runtime validation is available.
- No obvious error spam.
- Relevant edge cases handled.
- Architecture supports expansion.
- User-facing behavior is understandable.
- `PROJECT.md` status is updated.

For milestones, technical completion alone is insufficient; the gameplay quality gate must pass.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean restart confirmed.
- 2026-08-01: Steam 1.0 commercial quality is the end target; prototype completion is not the finish line.
- 2026-08-01: Code changes and progress-document updates are one development unit.
- 2026-08-01: Phase 0 infrastructure is introduced incrementally when required so playable combat iteration is not blocked by speculative framework work.
- 2026-08-01: Android is a development/playtest target while PC/Steam remains the primary release target.
- 2026-08-01: User review requests should be batched at meaningful playable checkpoints; Android APK should be provided when feedback is required and a build environment is available.
- 2026-08-01: PC and Android share the same gameplay code; platform differences belong in input/presentation layers.

## Continuation Protocol
In another ChatGPT conversation:
1. Read `PROJECT.md` first.
2. Read `LAST_MAGAZINE_GDD.md` for design/content/balance behavior.
3. Inspect current repository files rather than trusting old chat state.
4. Continue from the first incomplete item in `Next Work` unless the user changes priority.
5. Never restore the discarded prototype.
6. Do not ask for frequent user confirmation; build toward the next meaningful playtest checkpoint.
7. Update this document after meaningful implementation.

Suggested continuation prompt:
`@GitHub LAST MAGAZINE 이어서 개발해. PROJECT.md와 GDD를 먼저 읽고 Next Work의 첫 미완료 작업부터 진행해.`

## Progress Log
### 2026-08-01 — Fresh restart
- Previous project removed.
- New Godot bootstrap created.
- Steam-quality roadmap/handoff policy established.

### 2026-08-01 — M1 player foundation
- Added input/physics foundation.
- Added combat-lab arena and world collision.
- Added Player scene/controller with movement, mouse aim, dash, i-frame, HP/damage/death hooks.

### 2026-08-01 — M1 gun combat and Android input foundation
- Added reusable weapon controller, projectile pipeline, magazine/reload and basic HUD.
- Added stationary targets and first active Chaser enemy with contact damage.
- Added combat-room enemy tracking and room-clear event.
- Added Android dual-stick/dash/reload input foundation while keeping shared gameplay logic.
- Added Windows/Android playtest export presets.
- Runtime and APK device validation remain pending before user feedback is requested.
