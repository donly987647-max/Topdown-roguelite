# LAST MAGAZINE — Project Roadmap & Handoff

> Operational source of truth. Read this file before changing the project in any future conversation.

## Goal
Build **LAST MAGAZINE** from scratch as a commercially releasable 2D top-down bullet-hell action roguelite for Windows PC / Steam. Canonical engine target: **Godot 4.7.1**. Android shares gameplay code as a secondary playtest target.

Core identity: precise gun combat, manual frame/part weapon construction, 6×5 spatial backpack, adjacency/connector/power synergies, handcrafted room templates assembled into branching roguelite runs, skill-first combat and build variety.

## Canonical Sources
1. `LAST_MAGAZINE_GDD.md` — design authority.
2. `docs/GDD_COVERAGE.md` — mandatory GDD 1–80 implementation/validation matrix.
3. `PROJECT.md` — live implementation state and handoff.

## Absolute User Review Gate
Do not request final gameplay feedback until the GDD is fully represented and audited for omissions. Before presenting that build: re-read GDD 1–80, audit content-count gates, audit non-cuttable quality gates, run Windows/Android validation, and document any explicitly approved reductions. Code presence alone is never validation.

## Development Rules
- Production architecture over throwaway hacks.
- PC/Steam primary; Android shares gameplay code.
- Do not interrupt for routine micro-decisions.
- Code + `PROJECT.md` + `docs/GDD_COVERAGE.md` updates are one development unit.
- Never restore discarded legacy prototype.
- Never commit signing credentials.

## Current Development State
**Last updated:** 2026-08-02

**Current milestone:** P2 one-zone run loop architecture; live room-scene integration.

**Current build is NOT a GDD-complete feedback build.**

### Combat / weapon runtime
- Player movement, aim, dash, i-frame, HP, damage, death and temporary shield foundations exist.
- Player/enemy projectile paths, swept projectile collision and collision-normal ricochet exist.
- Chaser and Ranged enemy prototypes exist.
- 12 weapon frames, 12 barrels, 12 magazines and 12 cores have data-driven runtime foundations.
- Burn/Cold/Shock/Corrosion/Bleed/Confusion/Vulnerable runtime and several reactions exist.
- Remaining weapon fidelity includes persistent drones, Rail Lancer movement slowdown, Shrapnel self-damage, Impact wall collision bonus, Devour elite persistence, conductive terrain and final balance/QA.

### Backpack / modules / equipment
- 6×5 spatial `BackpackGrid`, rotation, occupancy, up to three expansion cells, instance IDs, auto-placement and serialization/restore exist.
- Directional power/signal/ammo/cooling terminals and network power allocation exist.
- `BackpackSynergyExecutor` supports explicit adjacency and tag-tier effect aggregation.
- `PassiveModuleDefinition` / `PassiveModuleRuntime` and `ActiveEquipmentDefinition` / `ActiveEquipmentRuntime` provide generic execution foundations.
- Production inventory UI and final content quantities remain incomplete.

### Reward / run state
- `RewardSelector` supports major-combat three-choice composition: build-related, general random and new-direction.
- Duplicate choice prevention, recent-offer suppression, repeated-claim reduction and related-item dry-streak mitigation exist.
- `RewardGrantResolver` has generic contracts for scrap, ammo, heal, shield, backpack expansion and equipment/item grants.
- `RunStateController` connects start → room enter → room clear → reward choice → grant → route choice → boss success/failure.
- Current room, visited/cleared rooms, build tags and reward history serialize/restore.

### Handcrafted room / route architecture
- `RoomTemplateDefinition` follows GDD handcrafted-room composition rather than generating room geometry procedurally.
- Templates include zone, room type, size, tile dimensions, entrances/exits, obstacles, hazards, enemy spawn cells, 1–3 waves, recommended threat, allowed enemy IDs/tags, camera bounds, environment tags and secret-connection eligibility.
- Templates now also carry optional `scene_path` plus entrance/exit/spawn/camera group contracts for authored Godot scenes.
- `RoomTemplateRegistry` selects templates using zone, room type, threat proximity and usage count.
- `RunGraphGenerator` provides seeded branching routes with Start→Boss reachability and safe/risky route metadata.

### Threat / encounter runtime
- `ThreatBudgetPlanner` converts recommended threat into 1–3 wave encounter budgets and filters enemies by ID/tag.
- `RoomEncounterRuntime` emits encounter start, wave-ready, wave-clear and encounter-clear lifecycle signals.
- `EnemySpawnRegistry` maps enemy IDs to PackedScenes and reports missing enemy scene registrations.

### Live room scene integration — current batch
- `RoomSceneRuntime` loads authored room scenes from `RoomTemplateDefinition.scene_path`; if no scene is assigned it can create a generated shell for architecture tests.
- Room spawn markers may come from scene groups or template cell coordinates.
- Threat-budget wave entries instantiate through `EnemySpawnRegistry` and are placed at resolved spawn points.
- Enemy removal is tracked through tree exit and advances `RoomEncounterRuntime` waves.
- `RoomExitGate` is a reusable authored-scene exit contract with lock state and target-room assignment.
- Combat exits stay locked during combat **and remain locked after combat until reward/route resolution completes**.
- `RunSceneCoordinator` binds `RunStateController`, `RoomTemplateRegistry` and `RoomSceneRuntime`.
- Coordinator handles room transition, template selection/binding, room clear, reward panel request, route panel request and map-state events.
- When route choices become available, exit targets are assigned and gates unlock; entering a gate requests the connected graph room.
- `MagazineRuntime` now joins the generic `room_lifecycle_listener` group and resets Reactive Magazine's once-per-room state on room entry.

### UI data contracts
- `RunMapViewModel` converts RunGraph + visited/cleared/current state into node/edge presentation data including route class and reward grade.
- `RewardChoiceViewModel` converts `RewardOffer` choices into UI-ready title/description/rarity/category/tag records.
- Actual Control scenes, controller navigation, animations and final production UX remain incomplete.

### Validation tooling/status
- `tools/gdd_runtime_smoke.gd`: weapon/backpack representative contracts.
- `tools/run_system_smoke.gd`: graph reachability, reward uniqueness and passive aggregation.
- `tools/run_lifecycle_smoke.gd`: room template, threat waves, run progression and restore.
- `tools/room_scene_smoke.gd`: room scene metadata, exit gate and enemy registry contracts.
- This environment has **not executed Godot 4.7.1**. Parser/runtime/gameplay validation remains pending.
- GitHub status/check presence must not be treated as runtime validation unless an actual Godot workflow executes successfully.

## Major Gaps
- Devour elite-kill room persistence still needs direct weapon lifecycle integration.
- Actual authored room `.tscn` content and enemy scene registration tables are not yet populated to release quantities.
- P2 Control scenes for map, reward, character select and result flow are not yet implemented.
- Shop/crafting/medical/event controllers and full run economy are incomplete.
- Disk-level mid-run save/continue, version migration and failure recovery are incomplete.
- Characters, four zones + secret zone, bosses, curses, hub/meta, tutorial, accessibility, production art/audio/VFX, stats, achievements, daily challenge and Steam integration remain incomplete.
- Final content quantity, optimization and QA gates remain open.

## Next Work — GDD coverage driven
1. Build actual P2 `Control` scenes for map route selection and three-choice reward selection using the new view models.
2. Add a run-level wallet plus shop, crafting and medical interaction controllers.
3. Add an authored Zone 1 room-template starter set and concrete enemy PackedScene/threat-cost registrations.
4. Bind camera bounds and player entrance placement to authored room scene markers.
5. Finish Devour elite room-persistent behavior through the room lifecycle listener contract.
6. Add disk mid-run save/continue and restore scene/template bindings.
7. Execute headless Godot 4.7.1 smoke tests once a runnable validation environment is available and repair parser/runtime failures before upgrading statuses.
8. Continue coverage until all mandatory GDD rows are IMPLEMENTED then VALIDATED; only after final omission audit + runtime/device QA produce feedback build/APK.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean restart.
- 2026-08-01: Steam 1.0 commercial quality is the target.
- 2026-08-01: Android is shared-code playtest target; PC/Steam primary.
- 2026-08-01: Final feedback gate requires full GDD implementation + omission audit.
- 2026-08-01: Godot 4.7.1 is canonical.
- 2026-08-02: Weapon, backpack, passive/active, reward and run systems use data-driven definitions and generic runtime dispatch.
- 2026-08-02: Room geometry stays handcrafted; procedural generation composes authored room templates into routes.
- 2026-08-02: Major combat rewards preserve build-related / general-random / new-direction roles.
- 2026-08-02: Combat exits do not unlock merely because enemies are dead; reward and route resolution gate room departure.
- 2026-08-02: Room-scoped gameplay effects receive generic `room_lifecycle_listener` callbacks rather than coupling directly to one room controller.

## Continuation Protocol
1. Read `PROJECT.md`.
2. Read `docs/GDD_COVERAGE.md`.
3. Read canonical GDD for the section being implemented.
4. Inspect repository state.
5. Continue highest-priority incomplete GDD coverage.
6. Never restore discarded prototype.
7. Do not ask for routine confirmation.
8. Update `PROJECT.md` and `docs/GDD_COVERAGE.md`.
9. No final feedback build before full omission audit passes.

## Progress Log
### 2026-08-01 — Fresh restart / combat foundation
- Clean Godot project, combat loop and Android input foundations created.

### 2026-08-02 — Weapon / backpack / run architecture
- Added data-driven weapon assembly, status runtime, backpack networks, passive/active foundations, three-choice rewards and seeded run graph architecture.

### 2026-08-02 — Run lifecycle / handcrafted room / threat batch
- Added RunStateController, RewardGrantResolver, handcrafted room-template model/registry, safe/risky routes, RoomEncounterRuntime and ThreatBudgetPlanner.

### 2026-08-02 — Live room scene integration batch
- Added room `scene_path`/group contracts and `EnemySpawnRegistry`.
- Added `RoomSceneRuntime` for authored scene loading, threat-wave spawning and enemy lifetime tracking.
- Added reusable `RoomExitGate`.
- Added `RunSceneCoordinator` to connect scene lifecycle, reward flow, route flow and graph traversal.
- Changed combat exit policy so reward/route resolution gates departure.
- Connected Reactive Magazine to room lifecycle reset.
- Added map/reward view models and `tools/room_scene_smoke.gd`.
- Actual Godot execution remains pending.
