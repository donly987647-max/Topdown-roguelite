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

**Current milestone:** GDD-wide production architecture expansion; weapon runtime coverage pass.

**Current build is NOT a GDD-complete feedback build.**

### Combat foundation
- Player movement/aim/dash/i-frame hooks/HP/damage/death.
- Player/enemy projectile paths.
- Chaser + Ranged enemy prototypes and ranged wind-up.
- Two-wave combat room, doors and room-clear reward prototype.
- Android dual-stick/dash/reload foundation.
- Player temporary-shield runtime exists for absorption effects.

### GDD 11 projectile / collision runtime
- Projectile payload carries damage, speed, lifetime, pierce, ricochet, homing, knockback, critical chance, status, explosion, owner/faction and advanced core fields.
- Homing acquires enemy-group targets and piercing supports multiple enemy hits.
- Projectile motion now performs a swept ray query each physics frame to reduce high-speed tunneling.
- World ricochet uses the collision surface normal instead of simple 180-degree reversal.
- Explosion applies radial falloff damage and frame/core multipliers.
- Critical-hit multiplier, status payload and chained-hit payload are supported.
- Shrapnel Launcher projectiles can ignore world blockers as the current gameplay representation of arcing over obstacles.

### Frame-special weapon runtime
- **Service Pistol:** perfect reload arms exactly one guaranteed-critical first shot without permanently mutating build stats.
- **Burst Carbine:** three-round burst, 0.08 s internal spacing and 0.32 s post-burst recovery.
- **Chain SMG:** consecutive successful hits ramp fire rate; streak decays after a short miss/idle window.
- **Breach Shotgun:** minimum eight-pellet spread behavior.
- **Rail Lancer:** hold-to-charge and release-to-fire; damage interpolates toward 110/45 multiplier and pierce count scales with charge.
- **Rotary Cannon:** hold-fire spin-up state drives fire rate toward 14 rounds/s and uses the heat system.
- **Shrapnel Launcher:** large explosion payload, higher explosion damage multiplier and wall-blocker bypass foundation.
- **Arc Projector:** Shock payload and up to three nearby chain hits with damage falloff.
- **Beam Cutter:** continuous ray ticks, 72 DPS baseline, same-target damage ramp and heat/ammo consumption.
- **Sawblade Caster:** minimum three collision-normal ricochets.
- **Drone Controller:** two-offset projectile support-volley foundation exists; persistent summon/drone actors are still required for final GDD fidelity.
- **Compression Hammer:** short forward melee cone and enemy-projectile reflection foundation.

### Weapon assembly / part runtime
- `WeaponBuild` matches canonical `WeaponFrameDefinition` / `WeaponPartDefinition` fields and validates compatibility, power overload and weight overload.
- `WeaponController.apply_build()` binds assembled frame + parts into live damage, interval, magazine, reload, projectile and heat behavior.
- `WeaponEffectResolver` converts build modifiers/effect IDs into composable projectile/core payloads.
- Pellet/scatter, pierce, ricochet, homing, explosive and elemental/status effects compose through the generic payload path.
- Power-overloaded weapons have a tunable firing-failure chance in addition to their other penalties.
- Perfect reload provides a next-shot damage hook.

### Core runtime
- Fire, Cold, Shock, Corrosion and Bleed status cores feed the shared status payload system.
- Void core payload supports a low probability percentage-health bonus on normal enemies and fixed bonus damage behavior for boss-group targets.
- Impact core increases projectile knockback; wall-collision bonus damage remains a fidelity gap.
- Absorption core converts a portion of dealt damage into capped temporary player shield.
- Photon core effect mapping supports increased critical chance; full speed/damage tradeoff still depends on part stat data.
- Replication core can spawn a reduced-damage duplicate projectile; proc chance is normalized downward on rapid-fire weapons.
- Devour core grants a next-attack damage multiplier after a kill; elite-kill room-persistent behavior is not yet implemented.
- Inverse Phase core turns the projectile back toward its owner after an enemy pass/hit and refunds one round on successful return.

### Status runtime
- `StatusReceiver` implements Burn, Cold, Shock, Corrosion, Bleed, Confusion and Vulnerable.
- Burn/Corrosion/Bleed provide periodic damage.
- Cold reduces movement/attack rate and freezes non-boss targets at maximum stacks.
- Strong hits shatter a frozen normal enemy for bonus damage and consume Cold.
- Explosions against burning targets trigger bonus reaction damage.
- Mechanical targets receive additional Shock accumulation and amplified Shock tick damage.
- Shock periodically chains to a nearby enemy; Arc Projector also has direct multi-chain logic.
- Corrosion increases damage taken and scales more strongly on armored/shielded targets.
- Bleed rejects non-biological targets and deals higher tick damage while moving.
- Confusion reverses Chaser/Ranged movement intent as a first implementation; boss-specific accuracy/tracking downgrade remains for boss framework.
- Vulnerable increases incoming damage with single-stack short-duration behavior.

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
- Part effect IDs aggregate into runtime effect payloads.

### GDD 20/24 backpack architecture
- 6×5 `BackpackGrid` placement, rotation, occupancy and adjacency.
- Up to three run expansion cells supported.
- `BackpackSynergyResolver` foundation resolves adjacency pairs, connector compatibility, powered-item state and tag counts.
- Connector conventions include matching connectors plus power_in/power_out and signal_in/signal_out pairs.

### Validation status
- The GitHub connector reports no commit status/check results for the latest main commits.
- This environment has **not executed Godot 4.7.1**, so parser/runtime behavior, combat feel, collision masks, device input, save integrity and performance remain unvalidated.
- All new weapon/core items stay `PARTIAL` in `docs/GDD_COVERAGE.md` until an actual headless boot/gameplay QA pass succeeds.

### Major gaps
See `docs/GDD_COVERAGE.md`. Weapon-runtime fidelity gaps include persistent drone summons, Rail Lancer movement slowdown while charging, Shrapnel Launcher self-damage, Impact wall-collision bonus damage, Devour elite/room persistence, conductive/water terrain reactions, boss-specific Confusion behavior, and complete part-specific barrel/magazine rules. Beyond weapons, final backpack UI/power routing, passive/active catalogs, characters, procedural map, zones, bosses, economy, curses, meta/hub, tutorial, UI/accessibility, production art/audio, save/stat/achievement/daily, Steam, endings/modes, content quantities, optimization and QA remain incomplete.

## Next Work — GDD coverage driven
1. Close the remaining frame/core fidelity gaps and run an actual Godot parse/headless combat validation pass.
2. Implement the 12 barrel and 12 magazine unique runtime rules through the same data-driven effect path.
3. Complete backpack connector geometry, ammo/cooling/signal terminals, power budgets and explicit/tag synergies.
4. Add passive module and active equipment definitions/execution architecture.
5. Replace single reward pickup with three-choice GDD reward flow and repetition control.
6. Build run graph/map generator and room-type framework.
7. Continue coverage until all mandatory GDD rows are IMPLEMENTED then VALIDATED.
8. Only after final omission audit + runtime/device QA, produce feedback build/APK.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean restart.
- 2026-08-01: Steam 1.0 commercial quality is the target.
- 2026-08-01: Android is shared-code playtest target; PC/Steam primary.
- 2026-08-01: Final feedback gate requires full GDD implementation + omission audit.
- 2026-08-01: `docs/GDD_COVERAGE.md` is mandatory.
- 2026-08-01: Godot 4.7.1 is canonical.
- 2026-08-02: Weapon assembly and backpack synergies use data-driven runtime resolvers rather than per-item hardcoding.
- 2026-08-02: GDD projectile/status requirements are implemented as generic payload/receiver systems so weapon parts can compose effects without bespoke projectile classes for every item.
- 2026-08-02: Frame identity is resolved by canonical frame ID; common projectile/core behavior remains composable instead of creating twelve disconnected weapon controllers.

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

### 2026-08-02 — Frame-special firing / advanced core batch
- Added burst, hit-ramping SMG, charge, spin-up, beam, launcher, chain-projector, saw ricochet, support-volley and melee/reflection frame behaviors.
- Added swept projectile collision and surface-normal ricochet.
- Added Void, Absorption, Replication, Devour and Inverse Phase runtime payload hooks.
- Added player temporary shield support for Absorption core.
- Added Burn+Explosion and Frozen+Strong-Hit reactions plus stronger mechanical Shock accumulation.
- Remaining frame fidelity and actual Godot execution validation are explicitly tracked as incomplete rather than marked finished.
