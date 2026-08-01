# LAST MAGAZINE — Project Roadmap & Handoff

> Operational source of truth for development continuity. Read this before changing the project in any future conversation.

## Goal
Build LAST MAGAZINE from scratch as a commercially releasable 2D top-down bullet-hell action roguelite for Windows PC / Steam in Godot 4.x. The target is paid Steam 1.0 quality, not prototype quality.

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
- After meaningful code changes, update this file in the same development session.

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

Acceptance: moving, aiming, shooting, dodging and fighting must already be enjoyable and predictable.

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

The detailed feature behavior and launch counts remain defined by the GDD.

## Current Development State

**Last updated:** 2026-08-01

**Current milestone:** `M1 — Core Combat Prototype`

**Current phase:** `Phase 1 — Player Controller` (Phase 0 minimum runtime foundation established; additional production infrastructure will be added when first needed rather than blocking playable iteration.)

### Completed in current fresh codebase
- Clean Godot project bootstrap and main scene.
- 1920×1080 internal viewport with desktop override.
- 60 Hz physics tick foundation.
- Input actions added: WASD movement, mouse fire, Space dash, R reload, E interact.
- M1 combat-lab arena with physical boundary walls.
- New production-oriented `Player` CharacterBody2D scene.
- 8-direction normalized movement.
- Acceleration/deceleration movement model.
- Mouse aiming and aim pivot.
- Player collision against world layer.
- Dash movement, cooldown and dash-direction fallback.
- Dash invulnerability timer hook.
- HP, damage reception, short post-hit invulnerability, knockback hook and death state.
- Placeholder body/gun visuals only; these are intentionally not production art.

### Current implementation files
- `project.godot`
- `scenes/main/Main.tscn`
- `scripts/main/main.gd`
- `scenes/player/Player.tscn`
- `scripts/player/player.gd`

### Current validation status
Code and scene structure have been written to GitHub. A real Godot runtime playtest has **not yet been performed in this ChatGPT environment**, so runtime correctness and feel are not claimed as validated. The next available local/editor test should check parsing, collision, diagonal speed, acceleration/deceleration, mouse aim, dash direction, dash cooldown and arena boundaries.

### Known technical debt / pending foundation
- Collision layer names are not yet declared in project settings.
- No debug overlay/logging service yet.
- No automated headless validation/CI yet.
- No data Resource conventions implemented yet because weapon/enemy data has not started.
- Player visuals are placeholders.
- Player hurtbox exists as a future combat hook but damage-area wiring begins with enemy combat.

## Next Work — execute in this order
1. Validate/fix the new Player scene in Godot runtime when execution becomes available.
2. Implement Phase 2 gun-combat foundation: weapon component, projectile scene, firing cadence and projectile collision.
3. Add magazine state and reload rules.
4. Add recoil/spread and hooks for later burst/automatic/pierce/ricochet behavior.
5. Add minimal HUD for HP/ammo/reload/debug state.
6. Implement first enemy target and damage interface.
7. Continue into enemy AI only after the fire/damage pipeline is stable.

## M1 Quality Gate Checklist
- [x] Clean fresh project baseline
- [x] Player movement implementation
- [x] World collision implementation
- [x] Mouse aim implementation
- [x] Dash/i-frame implementation
- [x] Player HP/damage/death hooks
- [ ] Runtime validation of player controller
- [ ] Gun firing pipeline
- [ ] Magazine/reload
- [ ] Projectile/damage pipeline
- [ ] Basic enemy AI
- [ ] Combat room controller
- [ ] Combat readability/feedback pass
- [ ] M1 playtest acceptance

## Definition of Done
For every implementation task:
- Works in actual play once runtime validation is available.
- No obvious error spam.
- Relevant edge cases handled.
- Architecture supports expansion.
- User-facing behavior is understandable.
- PROJECT.md status is updated.

For milestones, technical completion alone is insufficient; the gameplay quality gate must pass.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean restart confirmed.
- 2026-08-01: Steam 1.0 commercial quality is the end target; prototype completion is not the finish line.
- 2026-08-01: Code changes and progress-document updates are treated as one development unit.
- 2026-08-01: Phase 0 infrastructure is introduced incrementally when required so playable combat iteration is not blocked by speculative framework work.

## Continuation Protocol
In another ChatGPT conversation:
1. Read `PROJECT.md` first.
2. Read `LAST_MAGAZINE_GDD.md` for any design/content/balance behavior.
3. Inspect current repository files rather than trusting old chat state.
4. Continue from the first incomplete item in `Next Work` unless the user changes priority.
5. Never restore the discarded prototype.
6. Update this document after meaningful implementation.

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
- Runtime playtest remains pending; gun combat is next.
