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

**Current milestone:** P2 one-zone integrated starter run loop.

**Current build is NOT a GDD-complete feedback build.**

### Combat / weapon runtime
- Player movement, aim, dash, i-frame, HP, damage, death and temporary shield foundations exist.
- Player/enemy projectile paths, swept projectile collision and collision-normal ricochet exist.
- Chaser and Ranged enemy foundations exist.
- 12 weapon frames, 12 barrels, 12 magazines and 12 cores have data-driven runtime foundations.
- Burn/Cold/Shock/Corrosion/Bleed/Confusion/Vulnerable runtime and several reactions exist.
- Reactive Magazine now resets its once-per-room state from the generic room lifecycle contract.
- `DevourRoomRuntime` watches elite deaths and preserves the Devour 1.35× next-attack state for the remainder of the room, then resets at room lifecycle boundaries.
- Remaining weapon fidelity includes persistent drones, Rail Lancer movement slowdown, Shrapnel self-damage, Impact wall collision bonus, conductive terrain and final balance/QA.

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
- `Zone1RewardCatalog` provides a starter pool so the three-choice flow is populated during the one-zone run.
- `RunStateController` connects start → room enter → room clear → reward choice → grant → route choice → boss success/failure.
- Current room, visited/cleared rooms, build tags, reward history and node→room-template bindings serialize/restore.

### P2 Control UI
- `RunMapViewModel` converts graph state into UI node/edge data and now reads the canonical `route_risk` + rarity-bonus metadata.
- `RewardChoiceViewModel` converts reward offers into UI-ready title/description/rarity/category/tag records.
- `RunMapPanel` is a clickable `Control` that renders route nodes and emits selected graph-room IDs.
- `RewardChoicePanel` renders the live three-choice reward cards and emits the chosen index.
- `RunUiBinder` binds both panels to `RunSceneCoordinator`.
- `scenes/ui/run_map_panel.tscn`, `reward_choice_panel.tscn` and `run_ui_root.tscn` provide instantiable P2 UI scenes.
- Controller-navigation polish, animations, final art, accessibility and production UX remain incomplete.

### Handcrafted room / route architecture
- `RoomTemplateDefinition` follows GDD handcrafted-room composition rather than generating random geometry.
- Templates include zone, room type, size, entrances/exits, obstacles, hazards, enemy spawn cells, 1–3 waves, recommended threat, allowed enemy IDs/tags, camera bounds, environment tags and secret-connection eligibility.
- Optional authored `.tscn` paths remain supported.
- `AuthoredRoomShellBuilder` now turns authored template cells into functional fallback collision boundaries, obstacles, hazards, spawn markers, entrance markers and `RoomExitGate` exits. This is a playable architecture fallback, not production art.
- `RoomTemplateRegistry` selects templates using zone, room type, threat proximity and usage count; the previous missing `select()` contract used by the coordinator was fixed.
- `RunGraphGenerator` provides seeded Start→Boss branching routes with safe/risky metadata and now includes explicit shop, crafting and medical facility node types.

### Threat / encounter / enemy runtime
- `ThreatBudgetPlanner` converts recommended threat into 1–3 wave encounter budgets and filters enemies by ID/tag.
- The planner no longer repeatedly overspends when the cheapest enemy exceeds the remaining budget; this prevents duplicate boss prototypes in a one-boss wave.
- `RoomEncounterRuntime` emits encounter start, wave-ready, wave-clear and encounter-clear lifecycle signals.
- `EnemySpawnRegistry` maps enemy IDs to PackedScenes and now applies `EnemySpawnProfile` stat overrides, tags and elite metadata before the enemy enters the tree.
- `scenes/enemies/zone1_melee.tscn`, `zone1_ranged.tscn` and `enemy_projectile.tscn` provide concrete starter spawn scenes.

### Zone 1 starter content
- `Zone1ContentCatalog` currently defines **11 authored starter room templates**: 4 combat, 1 elite, shop, crafting, medical, rest, event and one boss-slot room.
- The templates contain explicit obstacle/hazard/spawn layouts and are rendered by the authored room-shell fallback when no production `.tscn` is assigned.
- The catalog currently defines **7 starter enemy profiles** with threat costs, tags, scene paths and per-ID stat overrides: Scrap Runner, Line Guard, Bolt Spitter, Fork Drone, Crusher Brute, Elite Line Guard and a GR-01 prototype slot.
- The GR-01 entry is only a loop-completion prototype using the melee base scene; it is **not** the final GDD boss implementation and must remain PARTIAL.

### Live room scene integration
- `RoomSceneRuntime` loads authored `.tscn` rooms when available and otherwise builds the authored-data fallback shell.
- Threat-budget wave entries instantiate through `EnemySpawnRegistry` and spawn at scene-group markers or template cells.
- Enemy removal advances waves.
- Combat exits remain locked after the last enemy until reward/route resolution finishes.
- `RunSceneCoordinator` binds run state, template selection, room loading, reward flow, route flow and graph traversal.
- `RoomEntryCameraController` places the player at authored entrance markers/cells and applies room-specific Camera2D world limits.
- `RoomExitGate` receives route targets and requests the connected graph room when entered.

### Run economy / facilities
- `RunWallet` provides the run-level scrap currency and matches the `RewardGrantResolver.add_currency` contract.
- `ShopController` provides stock, price validation, purchase/refund-on-grant-failure and sold state.
- `CraftingController` provides recipe registration, scrap payment and grant/refund behavior.
- `MedicalController` provides paid healing and temporary-shield treatment contracts.
- `RunFacilityCoordinator` activates shop/crafting/medical facilities from room type and shares one wallet across them.
- Final facility Control scenes, full price/balance tables, reroll rules and complete item inventory integration remain incomplete.

### Mid-run checkpoint save / continue
- `RunGraphCodec` reconstructs serialized run graphs.
- `RunSaveService` persists graph, run state, wallet, backpack state, room-template usage and acquired reward records to `user://last_magazine_run.json`.
- Save versioning is explicit (`SAVE_VERSION = 2`). Unknown future versions are rejected.
- Saves write through a temporary file before replacement to reduce partial-write corruption risk.
- Restore rebuilds graph/run state, wallet, backpack state, template usage and reward ownership, then rebinds registered room templates.
- `Zone1RunBootstrap` autosaves at room-entry checkpoints and removes the checkpoint when the run finishes.
- Full migration fixtures, corruption recovery UI, cloud/Steam save policy and save-during-arbitrary-combat-state support remain incomplete.

### Integrated Zone 1 bootstrap
- `Zone1RunBootstrap` constructs `RunStateController`, room registry, spawn registry, threat planner, wallet, backpack, reward pool, `RoomSceneRuntime`, `RunSceneCoordinator`, facilities, Reactive Magazine attachment and Devour room runtime.
- It can start a seeded new run or continue an existing checkpoint.
- It builds the shared run-context used by rewards and automatically derives current weapon build tags for build-aware reward selection.
- When a UI parent is provided it instantiates `scenes/ui/run_ui_root.tscn` and binds the P2 map/reward UI.

### Validation tooling/status
- `tools/gdd_runtime_smoke.gd`: weapon/backpack representative contracts.
- `tools/run_system_smoke.gd`: graph reachability, reward uniqueness and passive aggregation.
- `tools/run_lifecycle_smoke.gd`: room template, threat waves, run progression and restore.
- `tools/room_scene_smoke.gd`: room scene metadata, exit gate and enemy registry contracts.
- `tools/p2_integration_smoke.gd`: Zone 1 content/scene registration, authored room shell, boss budget, wallet, UI scene loading and checkpoint roundtrip contracts.
- The current local environment does **not** contain a Godot executable, so these scripts have not been executed here.
- GitHub commit statuses/checks must not be treated as runtime validation unless a real Godot 4.7.1 workflow executes successfully.

## Major Gaps
- Godot 4.7.1 parser/headless execution remains the immediate technical validation blocker.
- Zone 1 room shell is functionally generated from authored cells but lacks production visuals, authored `.tscn` set dressing, active hazard behavior and final encounter pacing.
- GR-01 is only a loop-completion prototype; the GDD boss pattern/state-machine quality bar is not implemented.
- Facility UI and full inventory/equipment granting remain incomplete.
- Characters, four full zones + secret zone, remaining enemies/elites/minibosses/bosses, curses, hub/meta, tutorial, accessibility, production art/audio/VFX, stats, achievements, daily challenge and Steam integration remain incomplete.
- Final content quantity, optimization and QA gates remain open.

## Next Work — GDD coverage driven
1. Run all smoke scripts under actual Godot 4.7.1 (local or CI), fix every parser/runtime failure and add a repeatable headless validation workflow.
2. Turn Zone 1 fallback rooms into production `.tscn` rooms with visuals, active hazards, camera polish, spawn timing and authored encounter pacing.
3. Replace GR-01 prototype with the full GDD boss state machine/pattern set.
4. Build production facility UI and complete inventory/passive/active reward application rather than storing generic owned-reward records.
5. Add character selection/result flow and complete one-zone P2 UX.
6. Expand Zone 1 enemy variety/content counts, then move into Zones 2–4 and secret-zone architecture/content.
7. Harden checkpoint migrations/corruption handling and connect final save architecture to meta progression/Steam policy.
8. Continue coverage until all mandatory GDD rows are IMPLEMENTED then VALIDATED; only after final omission audit + runtime/device QA produce feedback build/APK.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean restart.
- 2026-08-01: Steam 1.0 commercial quality is the target.
- 2026-08-01: Android is shared-code playtest target; PC/Steam primary.
- 2026-08-01: Final feedback gate requires full GDD implementation + omission audit.
- 2026-08-01: Godot 4.7.1 is canonical.
- 2026-08-02: Weapon, backpack, passive/active, reward and run systems use data-driven definitions and generic runtime dispatch.
- 2026-08-02: Room geometry stays handcrafted; procedural run generation composes authored room templates into routes.
- 2026-08-02: Major combat rewards preserve build-related / general-random / new-direction roles.
- 2026-08-02: Combat exits do not unlock merely because enemies are dead; reward and route resolution gate room departure.
- 2026-08-02: Room-scoped gameplay effects receive generic `room_lifecycle_listener` callbacks.
- 2026-08-02: Missing production room `.tscn` files fall back to geometry generated from **authored template cells**, not random geometry, preserving the handcrafted-room design rule.
- 2026-08-02: Mid-run save is a room-entry checkpoint system until arbitrary-frame combat restoration is explicitly implemented and validated.

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
- Added room scene/group contracts, EnemySpawnRegistry, RoomSceneRuntime, RoomExitGate and RunSceneCoordinator.
- Connected Reactive Magazine to room lifecycle reset.
- Added map/reward view models and room-scene smoke coverage.

### 2026-08-02 — Integrated Zone 1 P2 batch
- Added clickable map/reward Control scenes and RunUiBinder.
- Added RunWallet, Shop/Crafting/Medical controllers and RunFacilityCoordinator.
- Added concrete Zone 1 enemy/projectile scenes, profile stat overrides and 11 authored starter room templates.
- Added AuthoredRoomShellBuilder, camera/player entrance application and fixed RoomTemplateRegistry selection contract.
- Added Devour elite room-persistent runtime.
- Added RunGraphCodec + versioned checkpoint save/continue with wallet/backpack/template/reward restore.
- Added Zone1RewardCatalog and Zone1RunBootstrap to assemble the one-zone starter loop.
- Added P2 integration smoke coverage and fixed threat-budget repeated overspend.
- Actual Godot 4.7.1 execution remains pending.
