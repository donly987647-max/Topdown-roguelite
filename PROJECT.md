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

**Current milestone:** GDD-wide production architecture expansion; reward/run architecture pass.

**Current build is NOT a GDD-complete feedback build.**

### Combat foundation
- Player movement/aim/dash/i-frame hooks/HP/damage/death.
- Player/enemy projectile paths.
- Chaser + Ranged enemy prototypes and ranged wind-up.
- Two-wave combat room, doors and room-clear reward prototype.
- Android dual-stick/dash/reload foundation.
- Player temporary-shield runtime exists for absorption effects.
- Player exposes a damage event consumed by reactive magazine runtime.

### Weapon / status runtime
- 12 weapon-frame identities have live firing behavior foundations.
- 12 barrel identities and 12 magazine identities have data-driven projectile/reload runtime foundations.
- 12 core identities feed generic projectile/status hooks; remaining fidelity gaps are tracked separately.
- Burn/Cold/Shock/Corrosion/Bleed/Confusion/Vulnerable runtime exists with several cross-status reactions.
- Swept projectile collision and collision-normal ricochet are implemented.

### GDD 20/24 backpack architecture
- `BackpackGrid` supports 6×5 placement, occupancy, rotation, removal and up to three expansion cells.
- `BackpackState` adds definition registration, unique item-instance IDs, automatic placement, serialization and restore.
- Connector geometry resolves connector cell + facing direction into world ports after rotation.
- Connector channels support `power`, `signal`, `ammo`, `cooling` plus directional `_in` / `_out` pairs.
- Resolver builds per-network power graphs, computes supply/draw/overload, allocates powered items, collects adjacency effect IDs and calculates tag tiers.
- `BackpackSynergyExecutor` provides a data-driven execution layer for explicit adjacency and tag-tier synergies.
- UI drag/drop and full production synergy catalog remain incomplete.

### Passive module runtime — GDD 21 foundation
- Added `PassiveModuleDefinition` as a backpack-compatible passive item definition.
- Added data-driven stat modifiers, stack limits and trigger effect IDs.
- Added `PassiveModuleRuntime` for module aggregation, duplicate-stack limiting, additive/multiplicative stat composition and event-trigger dispatch.
- Exact 60-module content catalog and per-effect combat implementations remain incomplete.

### Active equipment runtime — GDD 22 foundation
- Added `ActiveEquipmentDefinition` with cooldown, charges, effect IDs and arbitrary activation payload.
- Added `ActiveEquipmentRuntime` with equip, cooldown ticking, charge consumption/refill, reset and activation dispatch.
- Exact 20-equipment content catalog, input/UI binding and concrete effect implementations remain incomplete.

### Reward selection — GDD 39 foundation
- Added `RewardOffer` model with category, rarity, payload and selection weight.
- Added `RewardSelector` with default three-choice generation, duplicate-ID prevention, recent-offer suppression, repeated-claim weight reduction and rarity weighting.
- Reward claim history can be serialized/restored.
- Existing room-clear pickup still needs to be replaced by UI-driven three-choice presentation and inventory/economy application.

### Run graph / room-route foundation — GDD 26–27
- Added `RoomNodeDefinition` with room type, difficulty, reward tags and metadata.
- Added `RunGraph` directed graph model with node/edge management, next-room lookup, reachability and serialization.
- Added `RunGraphGenerator` producing branching seeded routes from Start to Boss.
- Current generated room categories include combat, elite, shop, event and rest plus start/boss endpoints.
- Added structural validation for missing endpoints, unreachable boss and non-boss dead ends.
- Zone-specific generation, secret routes, room templates, threat budgeting and actual scene loading remain incomplete.

### Validation tooling/status
- `tools/gdd_runtime_smoke.gd` covers representative weapon/backpack contracts.
- `tools/run_system_smoke.gd` covers run-graph reachability, three-choice uniqueness and passive aggregation contracts.
- GitHub currently exposes no successful CI/runtime execution associated with these new scripts.
- This environment has **not executed Godot 4.7.1**; parser/runtime/gameplay validation therefore remains pending.
- New systems remain `PARTIAL` until real headless/gameplay QA succeeds.

### Major gaps
See `docs/GDD_COVERAGE.md`. Immediate architectural gaps now concentrate on reward UI/application, room lifecycle/state, room template selection, threat budgets, persistent drone behavior, environment/status interactions, exact content catalogs, characters, zones/bosses, economy, curses, meta/hub, tutorial, production UI/art/audio, full save/stat/achievement/daily support, Steam integration, optimization and QA.

## Next Work — GDD coverage driven
1. Bind the generated run graph to a run-state controller with current node, visited nodes, room-enter/clear events and save/restore.
2. Replace the single room-clear pickup with a three-choice reward flow that applies weapon part/passive/active/economy rewards.
3. Build room-template selection and threat-budget spawning on top of room-node metadata.
4. Add concrete starter passive/active catalogs and effect executor implementations without prematurely claiming the final target quantities.
5. Use room lifecycle hooks to finish Reactive Magazine per-room reset and Devour elite room persistence.
6. Continue toward zones, bosses, economy and complete-run loop.
7. Execute headless smoke tests once a runnable Godot environment is available and fix parse/runtime failures before upgrading coverage statuses.
8. Only after final omission audit + runtime/device QA, produce feedback build/APK.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean restart.
- 2026-08-01: Steam 1.0 commercial quality is the target.
- 2026-08-01: Android is shared-code playtest target; PC/Steam primary.
- 2026-08-01: Final feedback gate requires full GDD implementation + omission audit.
- 2026-08-01: `docs/GDD_COVERAGE.md` is mandatory.
- 2026-08-01: Godot 4.7.1 is canonical.
- 2026-08-02: Weapon assembly and backpack synergies use data-driven runtime resolvers rather than per-item hardcoding.
- 2026-08-02: GDD projectile/status requirements are implemented as generic payload/receiver systems.
- 2026-08-02: Frame identity is resolved by canonical frame ID; common projectile/core behavior remains composable.
- 2026-08-02: Stateful magazine rules use one MagazineRuntime attached to Player and bind to WeaponController signals.
- 2026-08-02: Backpack terminals are positional and directional; matching type alone is insufficient unless ports physically face each other.
- 2026-08-02: Passive/active/reward/run systems use data-driven definitions and generic runtime dispatch rather than hardcoding content before the final catalogs are authored.

## Continuation Protocol
1. Read PROJECT.md.
2. Read docs/GDD_COVERAGE.md.
3. Read canonical GDD for the section being implemented when available.
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
- Expanded player projectiles and bound assembled weapon effects into live firing.
- Added GDD status runtime and enemy integration.

### 2026-08-02 — Frame / part / network expansion
- Added frame-special firing, advanced core runtime, barrel/magazine execution and directional backpack networks.
- Added backpack instance identity, serialization, auto-placement and synergy execution.

### 2026-08-02 — Passive / active / reward / run batch
- Added passive module definition/runtime aggregation and event dispatch.
- Added active equipment cooldown/charge activation runtime.
- Added weighted three-choice reward selector with repetition suppression/history.
- Added room-node/run-graph models, seeded branching generation and validation.
- Added run-system smoke coverage; execution remains pending.
