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

**Current milestone:** GDD-wide production architecture expansion; P2 one-zone run-loop architecture pass.

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

### Passive / active equipment runtime — GDD 21–22
- `PassiveModuleDefinition` and `PassiveModuleRuntime` provide data-driven stat modifiers, stack limits and event-trigger dispatch.
- `ActiveEquipmentDefinition` and `ActiveEquipmentRuntime` provide cooldown, charges, activation payload and generic execution dispatch.
- Final 60 passive / 20 active catalogs, concrete effect libraries, input binding and production UI remain incomplete.

### Reward system — GDD 39
- `RewardOffer` models category, rarity, payload and selection weight.
- `RewardSelector` now supports the GDD major-combat composition: current-build-related option, general random option and new-direction option.
- Same-ID duplication inside one offer is prevented; recent offers are suppressed and repeated claims reduce weight.
- A lightweight pity adjustment increases related-item weight after a prolonged dry streak without converting the system into fully personalized loot.
- `RewardGrantResolver` applies scrap, ammo, heal, temporary shield, backpack expansion and item/equipment rewards through generic run-context contracts.
- Reward history serializes/restores through the selector.
- Production reward UI and final inventory/economy contracts remain incomplete.

### Run state / room lifecycle — GDD 5–6 / P2
- `RunStateController` connects Start → room enter → room clear → reward choice → reward grant → route choice → Boss success/failure.
- Current room, visited rooms, cleared rooms, build tags, reward history and finished state serialize/restore.
- Route validation prevents entering nodes that are not connected from the current node.
- Boss clear produces run success; explicit failure path exists.
- Scene transitions, result screen, character selection, hub return and disk-level mid-run save integration remain incomplete.

### Handcrafted room templates — GDD 26–27
- `RoomTemplateDefinition` follows the GDD handcrafted-template model rather than procedural room geometry.
- Template data includes zone, size class/tile dimensions, entrances/exits, obstacles, hazard cells, enemy spawn cells, 1–3 wave count, recommended threat, allowed enemy IDs/tags, camera bounds and secret-connection eligibility.
- `RoomTemplateRegistry` selects templates by zone, room type, recommended threat proximity and prior usage count to limit repetitive layouts.
- `RoomEncounterRuntime` provides encounter start, wave-ready, enemy-removal, wave-clear and encounter-clear lifecycle signals.
- Non-combat templates complete immediately at this architecture layer; shop/event/rest/crafting/medical interaction controllers remain future work.

### Safe / risky route generation — GDD 26.4
- `RunGraphGenerator` remains seed-driven and guarantees a Start→Boss route with dead-end validation.
- Two-lane branches assign safe/risky metadata.
- Safe lanes reduce elite likelihood and increase shop/rest tendency.
- Risky lanes increase elite/event tendency, environmental-hazard multiplier and reward-rarity metadata.
- Full four-zone progression, secret routes and authored route rules remain incomplete.

### Threat-budget encounter planning — GDD 28 foundation
- `ThreatBudgetPlanner` registers enemies with threat cost and tags.
- It converts a room template's recommended threat into an encounter budget with difficulty and elite multipliers.
- Budget is distributed across the template's configured 1–3 waves.
- Enemy selection respects explicit allowed-enemy IDs or allowed tags.
- Exact GDD-wide enemy cost table, spawn timing, formation rules, elite affixes and gameplay balancing remain incomplete.

### Validation tooling/status
- `tools/gdd_runtime_smoke.gd` covers representative weapon/backpack contracts.
- `tools/run_system_smoke.gd` covers run-graph reachability, three-choice uniqueness and passive aggregation contracts.
- `tools/run_lifecycle_smoke.gd` covers room-template validation, threat-wave construction, run start/clear/reward/route progression and run-state restore contracts.
- GitHub currently exposes no successful CI/runtime execution associated with these new scripts.
- This environment has **not executed Godot 4.7.1**; parser/runtime/gameplay validation therefore remains pending.
- New systems remain `PARTIAL` until real headless/gameplay QA succeeds.

### Major gaps
See `docs/GDD_COVERAGE.md`. Immediate gaps now concentrate on actual scene loading/spawning, P2 menu/character/result flow, disk mid-run save integration, reward/map UI, shop/crafting/medical/event controllers, room-scoped magazine/core hooks, persistent drone behavior, environment/status interactions, exact content catalogs, zone/boss content, curses, meta/hub, tutorial, production UI/art/audio, Steam integration, optimization and QA.

## Next Work — GDD coverage driven
1. Bind `RunStateController`, `RoomTemplateRegistry` and `RoomEncounterRuntime` to actual Godot room scenes and enemy spawning.
2. Add a room-session coordinator that locks exits during combat, advances waves with <=1 s pacing and unlocks route/reward flow on clear.
3. Connect room lifecycle signals to Reactive Magazine per-room reset and Devour elite room persistence.
4. Build the first production P2 UI path: run start/character selection → map route choice → three-choice reward → result screen.
5. Add run-level wallet/economy plus first shop/crafting/medical interaction controllers.
6. Add one-zone authored room template set and starter enemy threat-cost table before scaling content quantities.
7. Integrate disk-level mid-run save/continue and then execute headless smoke tests in a runnable Godot 4.7.1 environment.
8. Continue coverage until mandatory GDD rows are IMPLEMENTED then VALIDATED; only after final omission audit + runtime/device QA produce feedback build/APK.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean restart.
- 2026-08-01: Steam 1.0 commercial quality is the target.
- 2026-08-01: Android is shared-code playtest target; PC/Steam primary.
- 2026-08-01: Final feedback gate requires full GDD implementation + omission audit.
- 2026-08-01: `docs/GDD_COVERAGE.md` is mandatory.
- 2026-08-01: Godot 4.7.1 is canonical.
- 2026-08-02: Weapon assembly and backpack synergies use data-driven runtime resolvers rather than per-item hardcoding.
- 2026-08-02: GDD projectile/status requirements are implemented as generic projectile/status payload systems.
- 2026-08-02: Frame identity is resolved by canonical frame ID; common projectile/core behavior remains composable.
- 2026-08-02: Stateful magazine rules use one MagazineRuntime attached to Player and bind to WeaponController signals.
- 2026-08-02: Backpack terminals are positional and directional; matching type alone is insufficient unless ports physically face each other.
- 2026-08-02: Passive/active/reward/run systems use data-driven definitions and generic runtime dispatch rather than hardcoding content before final catalogs are authored.
- 2026-08-02: Room geometry stays handcrafted; runtime procedural generation composes authored room templates into route graphs, matching GDD 26.1.
- 2026-08-02: Major combat reward selection explicitly preserves three roles — build-related, general random and new-direction — rather than returning three identically weighted random items.

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

### 2026-08-02 — Run lifecycle / room template / threat batch
- Added `RunStateController` with room progression, reward grant, route selection and run-state serialization.
- Expanded major rewards to GDD build-related/random/new-direction composition with dry-streak mitigation.
- Added generic `RewardGrantResolver`.
- Added handcrafted `RoomTemplateDefinition` + selection registry.
- Added `RoomEncounterRuntime` and `ThreatBudgetPlanner` for 1–3-wave threat-budget encounters.
- Added safe/risky route metadata and route-biased room generation.
- Added `tools/run_lifecycle_smoke.gd`; actual Godot execution remains pending.
