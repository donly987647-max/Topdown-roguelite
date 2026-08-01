# LAST MAGAZINE — Project Roadmap & Handoff

> Operational source of truth. Read this file before changing the project in any future conversation.

## Goal
Build **LAST MAGAZINE** from scratch as a commercially releasable 2D top-down bullet-hell action roguelite for Windows PC / Steam. Canonical engine target: **Godot 4.7.1**. Target: paid Steam 1.0 quality.

Core identity: precise gun combat, manual frame/part weapon construction, 6×5 spatial backpack, adjacency/connector/power synergies, room-based roguelite runs, skill-first combat and build variety.

## Canonical Sources
1. `LAST_MAGAZINE_GDD.md` — design authority.
2. `docs/GDD_COVERAGE.md` — mandatory GDD 1–80 implementation/validation matrix.
3. `PROJECT.md` — live implementation state and handoff.

## Absolute User Review Gate
Do not request the user's final gameplay feedback until the GDD is fully represented and audited for omissions. Before presenting that build: re-read GDD 1–80, audit content-count gates, audit non-cuttable quality gates, run Windows/Android validation, and document any explicitly approved reductions. Code presence alone is never validation.

## Development Rules
- Production architecture over throwaway hacks.
- PC/Steam primary; Android shares gameplay code as playtest target.
- Do not interrupt for routine micro-decisions.
- Code + PROJECT.md + GDD_COVERAGE.md updates are one development unit.
- Never commit signing credentials.

## Full Phase Order
0 Foundation → 1 Player → 2 Gun Combat → 3 Enemy Framework → 4 Combat Readability → 5 Combat Rooms → 6 Run/Route → 7 Weapon Frames → 8 Gun Construction → 9 6×5 Backpack → 10 Backpack Synergies → 11 Reward Economy → 12 Facilities → 13 Boss Framework → 14 Complete Run → 15 Meta Progression → 16 Content Architecture → 17 Full Content → 18 Production Art → 19 VFX/Audio/Music → 20 UI/UX → 21 Tutorial → 22 Save → 23 Controller → 24 Settings/Accessibility → 25 Balance → 26 Optimization → 27 QA → 28 Steam Integration → 29 Store Assets → 30 RC → 31 Steam 1.0 → 32 Post-launch.

## Current Development State
**Last updated:** 2026-08-02

**Current milestone:** GDD-wide production architecture expansion.

**Current build is NOT a GDD-complete feedback build.**

### Combat foundation
- Player movement/aim/dash/i-frame hooks/HP/damage/death.
- Player/enemy projectile paths.
- Chaser + Ranged enemy prototypes and ranged wind-up.
- Two-wave combat room, doors and room-clear reward prototype.
- Android dual-stick/dash/reload foundation.

### GDD 11–19 live combat integration
- Projectile runtime now carries GDD-style payload fields: damage, speed, lifetime, pierce count, ricochet count, homing strength, knockback, critical chance, status payload, explosion radius, owner and faction.
- Homing acquires enemy-group targets.
- Piercing supports multiple enemy hits.
- Ricochet foundation reflects on world collision and consumes ricochet budget; accurate surface-normal reflection remains a later refinement.
- Explosion applies radial falloff damage to nearby enemies.
- Critical-hit damage multiplier is supported in projectile payload.
- `WeaponBuild` was corrected to match canonical `WeaponFrameDefinition` / `WeaponPartDefinition` fields and now validates compatibility, power overload and weight overload.
- `WeaponEffectResolver` converts build modifiers/effect IDs into live pellet/pierce/ricochet/homing/explosion/critical/status payloads.
- `WeaponController.apply_build()` now binds assembled frame + parts into live damage, interval, magazine, reload and heat behavior.
- Shotgun/scatter-style builds can emit multi-projectile pellet spreads.
- Power-overloaded weapons now have a low firing-failure chance in addition to reload/heat penalties.
- Perfect reload provides a next-shot damage hook and Service Pistol first-shot critical hook.

### Status runtime
- `StatusReceiver` implements GDD-oriented Burn, Cold, Shock, Corrosion, Bleed, Confusion and Vulnerable runtime states.
- Burn/Corrosion/Bleed provide periodic damage.
- Cold reduces move/attack rate and freezes non-boss targets at maximum stacks.
- Shock periodically damages and chains to a nearby enemy; mechanical targets take amplified shock tick damage.
- Corrosion increases damage taken, with stronger scaling on armored targets.
- Bleed rejects non-biological targets and deals higher tick damage while moving.
- Confusion reverses Chaser/Ranged movement intent as a first implementation; boss-specific accuracy/tracking downgrade remains for boss framework.
- Vulnerable increases incoming damage with single-stack short-duration behavior.
- Chaser and Ranged enemies now expose `apply_status_by_id()` so projectile status payloads affect live AI/combat.

### GDD 12–13 weapon runtime
- Magazine + reserve ammunition.
- Auto reload on empty option.
- Reload cancellation hook; player dash cancels reload.
- Perfect reload timing window and signal.
- Heat build/cooling/overheat lock/recovery framework.

### GDD 14–19 data/content architecture
- Data definitions for weapon frames, weapon parts and status effects.
- GDD catalogs: 12 frames, 12 barrels, 12 magazines, 12 cores, seven status effects.
- `WeaponBuild` runtime assembly resource combines frame + barrel + magazine + core.
- Runtime stat recomputation supports additive/multiplicative part modifiers.
- Power/weight overload ratios are computed; exact penalties remain balance-tunable.
- Part effect IDs aggregate into a runtime effect list.

### GDD 20/24 backpack architecture
- 6×5 `BackpackGrid` placement, rotation, occupancy and adjacency.
- Up to three run expansion cells supported.
- `BackpackSynergyResolver` foundation resolves adjacency pairs, connector compatibility, powered-item state and tag counts.
- Connector conventions include matching connectors plus power_in/power_out and signal_in/signal_out pairs.

### Validation status
This environment has not run Godot. Runtime parsing, feel, device input, save integrity and performance are not validated.

### Major gaps
See `docs/GDD_COVERAGE.md`. Beam/charge-specific firing behavior, accurate wall-normal ricochet, tunneling-safe continuous collision, full core-specific behaviors (chain rules, void, absorption shield, clone, devour, phase return), burn+explosive interaction, cold shatter, terrain/water interactions, final backpack UI/power routing, passive/active catalogs, characters, procedural map, zones, bosses, economy, curses, meta/hub, tutorial, UI/accessibility, production art/audio, save/stat/achievement/daily, Steam, endings/modes, content quantities, optimization and QA remain incomplete.

## Next Work — GDD coverage driven
1. Implement frame-special firing behaviors: burst, spin-up, charge, beam, launcher, saw/caster and heat-focused variants.
2. Implement remaining core-specific effects and cross-status reactions from GDD 18–19.
3. Improve ricochet with collision normal and add continuous/tunneling-safe projectile collision strategy.
4. Complete backpack connector geometry, ammo/cooling/signal terminals, power budgets and explicit/tag synergies.
5. Add passive module and active equipment definitions/execution architecture.
6. Replace single reward pickup with three-choice GDD reward flow and repetition control.
7. Build run graph/map generator and room-type framework.
8. Continue coverage until all mandatory GDD rows are IMPLEMENTED then VALIDATED.
9. Only after final omission audit + runtime/device QA, produce feedback build/APK.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean restart.
- 2026-08-01: Steam 1.0 commercial quality is the target.
- 2026-08-01: Android is shared-code playtest target; PC/Steam primary.
- 2026-08-01: Final feedback gate requires full GDD implementation + omission audit.
- 2026-08-01: `docs/GDD_COVERAGE.md` is mandatory.
- 2026-08-01: Godot 4.7.1 is canonical.
- 2026-08-02: Weapon assembly and backpack synergies use data-driven runtime resolvers rather than per-item hardcoding.
- 2026-08-02: GDD projectile/status requirements are implemented as generic payload/receiver systems so weapon parts can compose effects without bespoke projectile classes for every item.

## Continuation Protocol
1. Read PROJECT.md.
2. Read docs/GDD_COVERAGE.md.
3. Read canonical GDD for the section being implemented.
4. Inspect repository state.
5. Continue highest-priority incomplete GDD coverage.
6. Never restore discarded prototype.
7. Do not ask for routine confirmation.
8. Update PROJECT.md and GDD_COVERAGE.md.
9. No final feedback build before full omission audit passes.

Suggested continuation prompt:
`@GitHub LAST MAGAZINE 이어서 개발해. PROJECT.md, docs/GDD_COVERAGE.md, GDD를 먼저 읽고 미구현 GDD 항목부터 계속 구현해.`

## Progress Log
### 2026-08-01 — Fresh restart / combat foundation
- Clean Godot project, combat loop and Android input foundations created.

### 2026-08-01 — Full-GDD coverage policy / data foundation
- Added 80-section GDD coverage matrix and content gates.
- Added frame/part/status/backpack definitions and GDD catalogs.
- Added reserve ammo, perfect reload hooks and overheat framework.

### 2026-08-02 — Runtime assembly / status / backpack synergy foundation
- Added `WeaponBuild` runtime stat aggregation and overload calculation.
- Added reusable stacked/duration status-effect controller.
- Added backpack adjacency/connector/power/tag synergy resolver foundation.

### 2026-08-02 — Live weapon-effect and status integration
- Fixed WeaponBuild field compatibility with canonical data definitions.
- Expanded player projectiles to carry pierce/ricochet/homing/critical/explosion/status payloads.
- Bound assembled weapon stats/effects into live WeaponController firing.
- Added multi-pellet spread and power-overload firing-failure behavior.
- Added GDD status runtime receiver and wired Chaser/Ranged enemies to it.
- Next: frame-special firing logic and remaining core/status interactions.
