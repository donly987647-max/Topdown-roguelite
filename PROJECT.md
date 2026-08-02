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

**Current milestone:** P2 one-zone integrated vertical slice with frontend, combat HUD, facilities, live character kits and GR-01 settlement.

**Current build is NOT GDD-complete. The entry scene and full headless suite pass locally under Godot 4.7.1; GDD rows remain unpromoted until the repaired workflow also succeeds on GitHub Actions.**

### Default executable flow
`project.godot` launches `scenes/main/RunMain.tscn`.

Current flow:
**Main Menu → Character Select → Zone 1 Run → Combat / Reward / Route / Facilities → GR-01 → Boss Reward Settlement → Result → Retry / Character Change**.

`P2GameFlow` and `RunUiBinder` gate player and weapon processing so frontend/map/reward/facility modals cannot leave combat firing behind the UI.

### Gamepad / input — GDD 7 and UI completion foundation
- Added `GameInputSetup` to register runtime gamepad bindings without discarding existing keyboard/mouse bindings.
- Left stick: movement. Right stick: aim. Right trigger: fire.
- Face buttons cover dash/reload/interact/character active; Back toggles map; D-pad and accept/cancel drive Control focus navigation.
- Main menu, character select, result, run map, reward choice and facility UI now explicitly grab focus for controller navigation.
- Touch/mobile controls remain shared from the existing mobile path; full device QA is still pending.

### Player defense / HUD — GDD 10 / 47
- Player now has a real **guard** resource separate from temporary shield, with `guard_changed` and `health_changed` signals.
- Damage resolution is temporary shield → one guard charge → HP.
- Healing routes through `Player.heal()` so character healing modifiers apply consistently to rewards and medical treatment.
- Added `CombatHud` + `combat_hud.tscn`:
  - top-left: character, HP, guard, temporary shield, status slot;
  - bottom-right: weapon, magazine/reserve ammo, heat, reload progress, perfect-reload window;
  - bottom-left: character active/charge and passive description;
  - top-right: room/run context, scrap/debt, key/curse placeholders.
- Key/curse/status layers are placeholders until those systems exist; therefore HUD remains PARTIAL rather than production-complete.

### Characters — GDD 25 live kits
`CharacterDefinition`, `CharacterCatalog`, `CharacterRunRuntime`, `CharacterAbilityRuntime` and `CharacterSelectPanel` now form one runtime path.

#### Mara
- HP 100, one starting guard, Service Pistol.
- Field Modification: crafting cost multiplier 0.80 and one free dismantle allowance at run/zone setup; part-economy integration is live, while the incompatible-part power-penalty reduction still needs final weapon-assembly integration.
- Emergency Repair: enemy kills charge the active; activation restores one guard, or heals 15 if guard is already full. Kill threshold is provisional P2 tuning until balance QA.

#### Kane
- HP 90, movement multiplier 105%, Burst Carbine, critical bonus applied to the weapon runtime.
- Combat Focus: rapid consecutive kills add focus stacks; stacks improve movement plus effective fire/reload cadence, decay without kills, and are reduced on taking damage.
- Tactical Reload: instant full magazine and the following virtual magazine refunds consumed rounds. Cooldown/focus coefficients are provisional tuning.

#### Nova
- HP 80, Arc Projector, increased status buildup and reduced healing.
- Unstable Cells now reacts to actual status application events:
  - fire + cold → steam burst/AoE;
  - shock + corrosion → conductive chain damage;
  - bleed + cold → stronger hit plus Vulnerable.
- Forced Mutation applies two different random statuses to nearby enemies.
- Exact proc/damage coefficients remain provisional until runtime balance QA.

#### Rex
- HP 95, Sawblade Caster, lower shop multiplier and additional starting scrap.
- RunWallet supports credit/debt; purchases may use a configured debt limit and later scrap repays debt first.
- Shops may receive one discounted defective offer; selling value is increased.
- Price Manipulation rerolls one active reward slot and marks the replacement defective/high-risk. Focus-selection UX for the reroll can still be polished.

Shell-07 remains a locked secret catalog entry.

### Weapon / backpack foundations
- 12 frames, 12 barrels, 12 magazines and 12 cores retain their data-driven runtime foundations.
- Seven primary status runtimes and multiple reactions exist.
- 6×5 backpack, rotation, expansion cells, directional connectors, power networks, serialization and synergy aggregation remain implemented foundations.
- Remaining weapon fidelity still includes persistent drones, Rail Lancer charge slowdown, launcher self-damage, Impact wall-collision bonus, terrain conductivity and full balance/QA.

### Facilities — GDD 27 / 41
- `RunFacilityCoordinator` now exposes real transaction methods rather than state only.
- Added `FacilityPanel` + `facility_panel.tscn` with gamepad-focusable shop/crafting/medical actions.
- Shop: price validation, purchase, sold state, refund on failed grant, Rex defective offers and item selling.
- Crafting: character-adjusted recipe cost, ammo/shield/guard recipes and dismantle support; Mara receives the provisional free-dismantle rule.
- Medical: paid HP recovery and temporary shield treatment using the shared wallet and character healing modifier.
- Full inventory grid UI, production item cards, final price table and economy tuning remain incomplete.

### Handcrafted Zone 1 rooms
- Canonical room tile world size is 32 px.
- `AuthoredRoomShellBuilder` uses World collision layer 2 and creates explicit boundaries/obstacles/hazards/spawns/entrances/exits from authored template cells.
- Zone 1 starter `.tscn` set currently includes combat, elite, shop, crafting, medical, rest, event and dedicated boss arena resources.
- Visuals/set dressing and final hazard art remain placeholder-level.

### GR-01 — GDD 31
- `GR01Boss` + `gr01_boss.tscn` + `z1_boss_press.tscn` + `GR01Arena` form the dedicated boss runtime.
- Phase 1: compression, metal-shard fan, conveyor direction changes, falling blocks.
- Phase 2 at <=60%: tighter arena, center rotating press, tracking saws and minions. Active minions are capped to prevent uncontrolled accumulation.
- Phase 3 at <=25%: faster patterns, sequential safe zones, unsafe-zone periodic damage and timed core exposure; exposed core receives 1.75× damage.
- Added pattern/phase banners and explicit telegraph signals; arena now visualizes phase transitions/core opportunities.
- Boss settlement now occurs **before run completion**:
  - mandatory GR-01 exclusive part;
  - mandatory next-zone access key;
  - probabilistic permanent factory record (35% is provisional P2 tuning because the GDD specifies probability but no fixed percentage);
  - player choice between one backpack expansion cell and +15 max HP (value provisional).
- Pending boss/reward choices serialize so Continue does not replay a cleared boss or duplicate mandatory rewards.
- Final art/VFX/audio, animation, accessibility telegraphs and repeated-play balance QA are still open.

### Checkpoint save / continue
- `RunSaveService` is now **SAVE_VERSION = 4**.
- Atomic temp-file replacement remains in place.
- Save set includes graph/run state, current/pending reward choices, selected character, room/template bindings, wallet including Rex debt, backpack, acquired rewards, HP, guard, temporary shield, active frame, ammo/reserve/heat, and character active/focus state.
- Continue restores pending reward settlement directly instead of respawning an already-cleared combat/boss room.
- Full arbitrary assembled-part persistence, migration fixtures, corruption recovery UX and Steam Cloud policy remain incomplete.

### Validation automation
- `.github/workflows/godot-4-7-validation.yml` installs canonical Godot 4.7.1, imports/parses the project, loads the default entry scene, then runs the six-script smoke suite.
- `tools/run_godot_check.sh` now rejects non-zero exits, timeouts, parser/compiler/script/runtime error logs and missing success markers. This prevents a failed GDScript dependency from printing a misleading `PASS` or hanging until the job timeout.
- `p2_frontend_boss_smoke.gd` now covers frontend/HUD/facility scene loading, runtime gamepad actions, character starters, all Zone 1 room resources, GR-01 phase/core behavior, facility reward rules, GR-01 mandatory/choice settlement and Rex debt semantics.
- To obtain an observable pull-request-triggered run, validation branch `validation/godot-p2-batch` and **PR #8** were opened.
- Observed Actions run **#91 / run id 30729733320** was cancelled after 20 minutes: `weapon_build.gd` failed Variant type inference, `RunGraph.connect()` conflicted with `Object.connect()`, additional strict-warning parser errors were exposed, and the run-system script then stayed alive.
- The parser/type errors, ranged telegraph constructor error, camera utility leak and run-system assertion flaw are repaired on `agent/fix-godot-validation`. Local Godot 4.7.1 import, entry-scene smoke and all six scripted smokes pass with the strict wrapper. Remote Actions confirmation is still required before promotion to `VALIDATED`.

## Immediate Gaps / Next Work
1. Publish `agent/fix-godot-validation`, obtain a green Godot 4.7.1 Actions run, then synchronize the CI result in this handoff and the coverage matrix.
2. Complete the remaining character fidelity edge cases, especially Mara incompatible-part power penalty and Rex reward-slot selection polish.
3. Finish Zone 1 P4 content target: at least eight distinct enemies, production hazard behavior, art/animation/VFX/audio and encounter pacing.
4. Complete inventory/backpack Control UX and make acquired frame/barrel/magazine/core/passive/active rewards modify the live build rather than only generic ownership records where still applicable.
5. Perform repeated GR-01 completion/balance passes once executable validation is available.
6. Only after the one-zone vertical slice is stable, expand Zones 2–4, secret zone, hub/meta, tutorial, accessibility, achievements/daily challenge and Steam integration.

## Design Decisions
- 2026-08-01: Legacy prototype discarded; clean Godot restart.
- 2026-08-01: Steam 1.0 commercial quality target; Android secondary shared-code target.
- 2026-08-01: Final feedback gate requires full GDD omission audit + runtime/device QA.
- 2026-08-01: Godot 4.7.1 canonical.
- 2026-08-02: Data-driven weapon/backpack/passive/active/reward/run architecture.
- 2026-08-02: Room geometry remains handcrafted; run generation composes authored room templates.
- 2026-08-02: Combat exits remain locked until reward/route resolution.
- 2026-08-02: Room-scoped gameplay rules use generic lifecycle listeners.
- 2026-08-02: Zone 1 uses explicit 32×32 authored cell geometry.
- 2026-08-02: Character starts may use frame-only WeaponBuild state until parts are acquired.
- 2026-08-02: Default project entry is the integrated P2 `RunMain.tscn`.
- 2026-08-02: Runtime controller mappings are registered by `GameInputSetup` while retaining keyboard/mouse support.
- 2026-08-02: Boss completion is gated by mandatory GR-01 settlement and the backpack/max-HP choice.
- 2026-08-02: No CI/code status is called VALIDATED until an observed Godot 4.7.1 workflow succeeds.
- 2026-08-02: Headless checks must fail on Godot error logs and require a per-suite success marker; process exit code alone is insufficient.

## Continuation Protocol
1. Read `PROJECT.md`.
2. Read `docs/GDD_COVERAGE.md`.
3. Read canonical GDD for the target section.
4. Inspect current repository and latest Godot validation run.
5. Fix validation failures before broadening features.
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
- Added P2 menu/character/result flow, authored Zone 1 `.tscn` resources, GR-01 three-phase runtime and save v3.

### 2026-08-02 — HUD / controller / live character / facility / boss-settlement batch
- Added gamepad runtime mappings and focus navigation.
- Added real guard resource and GDD-layout combat HUD foundation.
- Added live Mara/Kane/Nova/Rex passive/active runtime behavior.
- Added playable facility modal and transaction integration.
- Added Rex debt/defective-shop economy and character-aware medical/crafting behavior.
- Added GR-01 rotating press, phase telegraphs, unsafe safe-zone mechanic, minion cap and complete GDD reward-settlement structure.
- Upgraded save to v4 including guard/debt/character ability and pending reward state.
- Opened PR #8 solely to obtain observable Godot 4.7.1 pull-request validation; run #91 later failed parser checks and was cancelled on timeout.

### 2026-08-02 — Godot 4.7.1 validation repair
- Renamed the graph edge method to avoid `Object.connect()` override conflicts and added strict Variant/typed-array conversions required by Godot 4.7.1.
- Repaired ranged-enemy telegraph construction and converted the stateless room-entry camera helper to `RefCounted`, eliminating the default-scene shutdown leak.
- Corrected the passive multiplier smoke expectation and changed the run-system smoke to aggregate failures before choosing its exit status.
- Added strict error/timeout/success-marker enforcement to every headless check.
- Local result: project import, default entry scene and all six scripted smoke suites pass under `4.7.1.stable.official.a13da4feb`; remote Actions confirmation pending.
