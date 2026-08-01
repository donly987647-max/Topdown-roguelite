# LAST MAGAZINE — Project Roadmap & Handoff

> Operational source of truth. Read this file before changing the project in any future conversation.

## Goal
Build **LAST MAGAZINE** from scratch as a commercially releasable 2D top-down bullet-hell action roguelite for Windows PC / Steam. The canonical engine target is **Godot 4.7.1** per GDD. Target: paid Steam 1.0 quality, not prototype quality.

Core identity:
- Fast, precise top-down gun combat
- Manual weapon construction with frames and parts
- 6×5 spatial backpack
- Adjacency / connector / power-routing synergies
- Room-based roguelite runs
- Skill-first combat and high build variety

## Canonical Design / Coverage Sources
1. `LAST_MAGAZINE_GDD.md` — canonical design source whenever available in the repository/context.
2. `docs/GDD_COVERAGE.md` — mandatory implementation/validation coverage matrix for all GDD sections 1–80.
3. `PROJECT.md` — current implementation state, next work and handoff log.

Do not silently redesign major systems. Intentional deviations belong under Design Decisions and require explicit user approval when they change the promised product.

## Absolute User Review Gate
The user requested that feedback be requested **only after the GDD is fully represented and checked for omissions**.

Therefore:
- Do not present an M1/M2 prototype as the requested final feedback build.
- Do not request final gameplay feedback while mandatory GDD sections remain `NOT STARTED` or `PARTIAL` in `docs/GDD_COVERAGE.md`.
- Before presenting the requested feedback build, re-read the GDD, audit every section 1–80, audit launch content counts, and confirm no mandatory requirement was silently omitted.
- Runtime/device validation is required; code presence alone is not completion.
- If a GDD item is intentionally removed or reduced, it must be explicitly approved by the user and recorded here.

## Development / Playtest Rules
- Production-quality architecture over throwaway demo hacks.
- Implementation is not acceptance; runtime feel/quality gates still matter.
- Code changes + PROJECT.md + GDD_COVERAGE.md updates are one development unit.
- PC/Steam is primary release target; Android remains a supported development/playtest target using shared gameplay code.
- At the eventual meaningful review checkpoint, provide an Android APK when a compatible build environment is available.
- Never commit Android signing credentials.

## Full Phase Order
0 Foundation → 1 Player → 2 Gun Combat → 3 Enemy Framework → 4 Combat Readability → 5 Combat Rooms → 6 Run/Route → 7 Weapon Frames → 8 Gun Construction → 9 6×5 Backpack → 10 Backpack Synergies → 11 Reward Economy → 12 Facilities → 13 Boss Framework → 14 Complete Run → 15 Meta Progression → 16 Content Architecture → 17 Full Content → 18 Production Art → 19 VFX/Audio/Music → 20 UI/UX → 21 Tutorial → 22 Save → 23 Controller → 24 Settings/Accessibility → 25 Balance → 26 Optimization → 27 QA → 28 Steam Integration → 29 Store Assets → 30 RC → 31 Steam 1.0 → 32 Post-launch.

## Current Development State
**Last updated:** 2026-08-01

**Current milestone:** expanding from M1 combat foundation into GDD-wide production architecture.

**Important:** current build is NOT a GDD-complete feedback build.

### Implemented / partial foundations
Combat foundation:
- Player movement, aim, dash/i-frame hook, HP/damage/death.
- Player and enemy projectile paths.
- Magazine/reload and HUD.
- Chaser + Ranged enemy prototypes, ranged wind-up telegraph.
- Two-wave combat room, lockable doors, room-clear reward prototype.
- Android dual-stick/dash/reload input foundation.

GDD system expansion started:
- Reserve ammunition support.
- Auto-reload-on-empty option.
- Perfect-reload timing window hook.
- Dash-cancels-reload behavior.
- Weapon heat/overheat/cooling framework.
- Data Resource definitions for weapon frames, weapon parts, status effects and backpack items.
- Full 12-frame GDD weapon-frame catalog added as data.
- Full 12 GDD barrel catalog added as data.
- Full 12 GDD magazine catalog added as data.
- Full 12 GDD core catalog added as data.
- Seven GDD status effects cataloged as data.
- 6×5 BackpackGrid core supports placement, occupancy, rotation, adjacency and up to three expansion cells.

### Validation status
The current environment has not executed the Godot project. No system is marked runtime-validated solely because code exists.

### Current major gaps
See `docs/GDD_COVERAGE.md`. Most GDD sections remain unimplemented, including full weapon effect execution, backpack UI/connectors/synergies, characters, map generation, all zones, bosses, economy, curse/meta/hub, tutorial, full UI, accessibility, art/audio, save/stat/achievement/daily systems, Steam integration, full modes/endings, content-count targets, optimization and QA.

## Next Work — GDD coverage driven
1. Finish GDD 12–13 runtime rules: reserve ammo, perfect reload consequences, reload cancel variants, heat build hooks.
2. Build runtime weapon assembly/stat recomputation for frame + barrel + magazine + core and overload rules (GDD 14).
3. Implement effect/status execution layer for cataloged parts and GDD 19 statuses.
4. Complete 6×5 backpack runtime + connector types + adjacency/power routing (GDD 20,24).
5. Add GDD passive/active equipment data and execution architecture (21–22).
6. Replace single reward pickup with GDD selection/repetition-control flow (39).
7. Continue through `docs/GDD_COVERAGE.md` until every mandatory section is IMPLEMENTED, then VALIDATED.
8. Only after full GDD audit + runtime/device QA, produce the user feedback build/APK.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean restart confirmed.
- 2026-08-01: Steam 1.0 commercial quality is the end target.
- 2026-08-01: Android is a development/playtest target; PC/Steam stays primary.
- 2026-08-01: PC and Android share gameplay code.
- 2026-08-01: User final feedback request is gated by full GDD implementation and omission audit, not by M1 completion.
- 2026-08-01: `docs/GDD_COVERAGE.md` is mandatory and must be updated with meaningful implementation changes.
- 2026-08-01: Godot 4.7.1 is the canonical engine version from the GDD.

## Continuation Protocol
1. Read `PROJECT.md`.
2. Read `docs/GDD_COVERAGE.md`.
3. Read the canonical GDD before implementing any section.
4. Inspect current repository state; never trust stale chat state.
5. Continue from the highest-priority incomplete GDD coverage item.
6. Never restore discarded prototype code.
7. Do not ask the user for routine confirmation.
8. Update PROJECT.md and GDD_COVERAGE.md after meaningful work.
9. Do not present a final feedback build until the full GDD omission audit passes.

Suggested continuation prompt:
`@GitHub LAST MAGAZINE 이어서 개발해. PROJECT.md, docs/GDD_COVERAGE.md, GDD를 먼저 읽고 미구현 GDD 항목부터 계속 구현해.`

## Progress Log
### 2026-08-01 — Fresh restart
- Previous project removed; new Godot bootstrap created.

### 2026-08-01 — Combat / Android foundation
- Movement, shooting, reload, enemies, waves, room clear and Android touch foundations added.

### 2026-08-01 — Readability foundation
- Ranged telegraph, muzzle feedback and debug HUD added.

### 2026-08-01 — Full-GDD coverage policy + production data foundation
- Added `docs/GDD_COVERAGE.md` tracking all GDD sections 1–80 and launch content gates.
- Changed user review gate: no final feedback request until mandatory GDD implementation + omission audit + runtime validation are complete.
- Added data-driven definitions for frames, parts, statuses and backpack items.
- Added complete 12-frame, 12-barrel, 12-magazine and 12-core GDD catalogs.
- Added status catalog and 6×5 BackpackGrid core.
- Expanded weapon controller with reserve ammo, perfect reload hook, dash reload cancellation and heat/overheat framework.
