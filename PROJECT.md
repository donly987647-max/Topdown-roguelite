# LAST MAGAZINE — Project Roadmap & Handoff

> Operational source of truth. Read this file before changing the project in any future conversation.

## Goal
Build **LAST MAGAZINE** as a commercially releasable 2D top-down bullet-hell action roguelite for Windows PC / Steam. Canonical engine: **Godot 4.7.1**. Android remains a shared-code secondary playtest target.

Core identity: precise gun combat, manual frame/part weapon construction, 6×5 spatial backpack, connector/power synergies, handcrafted rooms composed into branching runs, skill-first combat and build variety.

## Canonical Sources
1. `LAST_MAGAZINE_GDD.md` — design authority.
2. `docs/GDD_COVERAGE.md` — mandatory GDD 1–80 implementation/validation matrix.
3. `PROJECT.md` — live implementation state and handoff.

## Absolute User Review Gate
Do not request final gameplay feedback until the GDD is fully represented and audited for omissions. Code presence is not validation. Before a feedback/release-candidate build: run Windows/Android validation, audit GDD 1–80, content-count gates and non-cuttable quality gates, and document approved reductions.

## Development Rules
- Production architecture over throwaway hacks.
- PC/Steam primary; Android shared gameplay code.
- Do not interrupt for routine micro-decisions.
- Code + `PROJECT.md` + `docs/GDD_COVERAGE.md` are one development unit.
- Never restore the discarded legacy prototype.
- Never commit signing credentials.

## Current Development State
**Last updated:** 2026-08-02

**Current milestone:** P2 one-zone integrated run with frontend and GR-01 boss architecture.

**Current build is NOT GDD-complete and NOT runtime-validated yet.**

### Default executable flow
`project.godot` now launches `scenes/main/RunMain.tscn`, not the old M1 combat lab.

Current frontend flow:
**Main Menu → Character Select → Zone 1 Run → Reward / Route / Facilities → GR-01 → Success or Failure Result → Retry / Character Change**.

`P2GameFlow` disables player/weapon processing while menu, character-select and result overlays are active, preventing combat input behind frontend UI.

### Characters — GDD 25 foundation
- Added `CharacterDefinition`, `CharacterCatalog`, `CharacterRunRuntime` and `CharacterSelectPanel`.
- Four base characters are selectable: Mara, Kane, Nova and Rex.
- Shell-07 exists as a secret catalog entry and is hidden until its unlock key is provided.
- Base HP, movement multiplier, starting scrap and canonical starting weapon frame apply at run start.
- Starting frames: Mara/service pistol, Kane/burst carbine, Nova/arc projector, Rex/sawblade caster.
- Character passives/actives and several character-specific rules are currently represented as data/metadata; their full combat/economy implementations are still incomplete.

### Player / combat alignment
- Base player movement now follows the GDD 260 px/s target, with acceleration/deceleration adjusted toward the 0.08 s / 0.06 s response targets.
- Player now emits a `died` signal; the run flow converts death into `RunStateController.fail_run()` and shows the result screen.
- Player scene now includes a Camera2D used by room camera-limit application.
- Existing weapon/status/backpack foundations remain: 12 frames, 12 barrels, 12 magazines, 12 cores, seven main statuses, 6×5 backpack/network/synergy architecture.

### Starting weapon frame runtime
- Added `WeaponFrameCatalog` reading canonical frame data from `data/weapons/weapon_frames.json`.
- Added `StarterWeaponRuntime` so a character may legally begin with its frame before finding barrel/magazine/core parts.
- Frame-only starter state configures actual WeaponController damage/rate/magazine/reload/heat behavior and later remains compatible with the assembly pipeline.
- Full assembled weapon persistence is still incomplete; checkpoint persistence currently restores the active frame and live ammo resources, not an arbitrary complete future part build.

### P2 UI
- Existing clickable `RunMapPanel` and `RewardChoicePanel` remain bound through `RunUiBinder`.
- Added `MainMenuPanel`, `CharacterSelectPanel` and `RunResultPanel` Control scenes.
- Result screen reports character, rooms visited/cleared, scrap and acquired reward records.
- Production combat HUD, facility UI, controller navigation, animations, accessibility and final visual treatment remain incomplete.

### Handcrafted Zone 1 rooms — GDD 26 / 30
- Canonical room tile world size corrected to **32 px**, matching GDD 26.3.
- `AuthoredRoomShellBuilder` now builds into authored scene roots, uses World collision layer 2 for boundaries/obstacles, and creates entrance/spawn/exit/hazard nodes from explicit template cells.
- Added actual `.tscn` resources for Zone 1 starter rooms: `z1_line_a`, `z1_line_b`, `z1_sorter`, `z1_press_lane`, `z1_elite_press`, `z1_shop_bay`, `z1_crafting_bay`, `z1_med_bay`, `z1_rest_bay`, `z1_event_scrapyard`, plus the dedicated `z1_boss_press` arena.
- These scenes are structurally authored and playable foundations; their visuals/set dressing remain placeholder-level and therefore are not production-art complete.

### Zone 1 enemy content
- Starter profiles remain Scrap Runner, Line Guard, Bolt Spitter, Fork Drone, Crusher Brute, Elite Line Guard and GR-01.
- Profiles map to concrete PackedScenes and apply runtime stat/tag/group overrides.
- Enemy projectiles now optionally support homing, used by GR-01 tracking-saw attacks.
- Final P4 target of eight Zone 1 enemies and final animation/role polish is not yet met.

### GR-01 — GDD 31 runtime
- Replaced the old melee-base loop-completion boss slot with `GR01Boss` + `gr01_boss.tscn` and a dedicated `z1_boss_press.tscn` arena.
- Boss is spawned exactly once by the encounter/SpawnRegistry path, then dynamically binds to `GR01Arena`.
- Phase 1 implements wall compression pulse, metal-shard fan, conveyor direction changes and falling-block warnings.
- Phase 2 begins at <=60% HP and adds stronger arena compression, center-press attacks, tracking saw projectiles and minion summons.
- Phase 3 begins at <=25% HP and adds faster attacks, cycling safe-zone indicators and timed core exposure; exposed core takes amplified damage.
- Arena runtime moves compression walls, pushes the player by conveyor direction, telegraphs/drops block hazards and shows safe zones/core exposure.
- This is a functional boss state-machine foundation, not final animation/VFX/audio/balance/QA quality. Boss reward package is also not final.

### Run / reward / facility flow
- `RunStateController`, `RoomSceneRuntime`, `RunSceneCoordinator` and `Zone1RunBootstrap` remain the one-zone runtime spine.
- Combat exits stay locked until reward resolution; routes are then bound to `RoomExitGate` targets.
- Facility/non-combat rooms no longer incorrectly generate generic combat 3-choice rewards; they clear into route availability while the facility coordinator exposes shop/crafting/medical interaction state.
- RunWallet + shop/crafting/medical controllers are present, but production facility Control scenes and final balance/inventory application remain incomplete.

### Checkpoint save / continue
- `RunSaveService` upgraded to **SAVE_VERSION = 3**.
- Atomic temporary-file replacement remains in place.
- Checkpoint data now includes graph/run state, selected character, room/template bindings, wallet, backpack, template usage, acquired rewards, player HP, temporary shield, active frame ID, magazine ammo, reserve ammo and heat.
- Continue restores the selected character without duplicating starting resources, restores/creates the saved active frame, applies live player/weapon resources, then reloads the current room.
- Arbitrary complete future weapon-part assembly persistence, migration fixtures, corruption-recovery UX and Steam Cloud policy remain incomplete.

### Validation automation
- Added `.github/workflows/godot-4-7-validation.yml`.
- Intended CI sequence: install Godot 4.7.1 → headless editor import/parse → run six smoke suites.
- Smoke suites now include `p2_frontend_boss_smoke.gd`, which checks 4+1 character locking, canonical starter frames, frontend resources, all Zone 1 room resources, GR-01 phase/core contracts and facility-room reward behavior.
- Existing smoke suites cover weapon/backpack, graph/reward/passives, lifecycle/save, room scene contracts and P2 integration.
- **Current GitHub combined commit status is still empty; no successful Godot 4.7.1 run is visible through the connector yet. Therefore no system is upgraded to VALIDATED on the basis of this workflow.**

## Immediate Gaps / Next Work
1. Treat actual Godot 4.7.1 CI/headless failures as the highest priority and fix every parse/runtime error before broadening architecture.
2. Add production combat HUD (HP/guard/ammo/heat/scrap/boss health) and gamepad/controller navigation for all P2 frontend/reward/map screens.
3. Build facility Control UI and wire shop/crafting/medical purchases to actual inventory/passive/active grants.
4. Finish live character passives/actives, starting guard behavior, Rex economy rules, Nova mutation rules, Kane focus/tactical reload and Mara repair/modification rules.
5. Polish GR-01 telegraphs, damage zones, minion tracking, boss reward package, VFX/audio and balance; validate repeated completion.
6. Finish Zone 1 P4 content target (at least 8 distinct enemies, production art/animation, hazard behaviors, final encounter pacing) before scaling bulk content.
7. Expand from one-zone P2/P4 toward Zones 2–4, secret zone, meta progression, tutorial, accessibility and Steam features only after the core vertical slice is stable.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean Godot restart.
- 2026-08-01: Steam 1.0 commercial quality target; Android secondary shared-code target.
- 2026-08-01: Final feedback gate requires full GDD omission audit + runtime/device QA.
- 2026-08-01: Godot 4.7.1 canonical.
- 2026-08-02: Data-driven weapon/backpack/passive/active/reward/run architecture.
- 2026-08-02: Room geometry remains handcrafted; run generation composes authored room templates.
- 2026-08-02: Combat exits remain locked until reward/route resolution.
- 2026-08-02: Room-scoped gameplay rules use generic lifecycle listeners.
- 2026-08-02: Zone 1 uses explicit 32×32 authored cell geometry; generated shell logic is a reusable authored-data renderer, not random map generation.
- 2026-08-02: Character starts may use frame-only WeaponBuild state until parts are acquired.
- 2026-08-02: Default project entry moved from M1 combat lab to integrated P2 RunMain.
- 2026-08-02: CI exists but statuses remain unverified; no validation claim without an observed successful Godot run.

## Continuation Protocol
1. Read `PROJECT.md`.
2. Read `docs/GDD_COVERAGE.md`.
3. Read canonical GDD for the target section.
4. Inspect current repository state and latest validation result.
5. Fix validation failures before expanding features.
6. Continue highest-priority incomplete GDD coverage.
7. Never restore discarded prototype.
8. Update code + PROJECT + GDD_COVERAGE together.
9. No final feedback build until full omission audit and runtime/device QA pass.

## Progress Log
### 2026-08-01 — Fresh restart
- Clean Godot project and combat foundation.

### 2026-08-02 — Weapon/backpack/run architecture
- Data-driven weapon/status/backpack/passive/active/reward/run systems.
- Run state, handcrafted room templates, threat budgets, room scenes, exits, facilities, save and Zone 1 starter content.

### 2026-08-02 — P2 frontend / authored Zone 1 / GR-01 batch
- Added Godot 4.7.1 headless CI workflow and expanded smoke coverage.
- Added 4 base + 1 secret character catalog, selection UI, character stat/start-frame application and selected-character persistence.
- Added main menu and run result UI and made integrated `RunMain.tscn` the default project scene.
- Added actual Zone 1 starter `.tscn` resources and corrected room tile/collision scale to GDD 32 px.
- Added GR-01 three-phase boss runtime, dedicated arena, homing saws, compression/conveyor/block/safe-zone/core mechanics.
- Fixed duplicate boss ownership and noncombat-room generic reward leakage.
- Upgraded checkpoint save to v3 with live player/weapon resource restoration.
- Actual Godot 4.7.1 success remains unobserved and pending.
