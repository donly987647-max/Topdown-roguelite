# LAST MAGAZINE — Project Roadmap & Handoff

> This document is the operational source of truth for development continuity.
> Any future developer or ChatGPT conversation should read this file first before making changes.

## 1. Project Goal

Build **LAST MAGAZINE** from scratch as a commercially releasable 2D top-down bullet-hell action roguelite for **Windows PC / Steam**, using **Godot 4.x**.

The target is **not a prototype-quality game**. The project must reach a quality bar suitable for a paid Steam 1.0 release.

Core identity:

- Fast, precise top-down combat
- Manual gun construction using weapon frames and parts
- 6×5 spatial backpack / inventory system
- Adjacency, connector and power-routing synergies
- Room-based roguelite progression
- Skill-first combat rather than permanent-stat grinding
- High-replayability runs with meaningful build variation

## 2. Canonical Design Source

The canonical game design is the document **LAST_MAGAZINE_GDD.md (GDD 1.0)**.

When implementation details conflict with the GDD:

1. Treat the GDD as the design source of truth.
2. Do not silently redesign major systems.
3. If implementation requires a deliberate design change, document the decision in this file under `Design Decisions`.
4. Do not reuse the discarded legacy prototype as a design authority.

## 3. Fresh-Start Rule

The previous prototype/codebase has been intentionally discarded.

Development is a **clean restart**.

Rules:

- Do not restore old prototype systems merely because they previously existed.
- Do not copy architecture from the discarded project without a clear reason.
- Build systems cleanly for the current GDD and Steam release target.
- Temporary placeholder assets are allowed during system development, but temporary architecture should not become production architecture by accident.

## 4. Release Quality Principle

Every milestone has a quality gate. A feature being "implemented" is not enough.

Systems should be:

- Functionally complete for their milestone
- Stable
- Maintainable
- Data-driven where appropriate
- Testable
- Compatible with future content expansion
- Polished enough for the current milestone

Do not move to mass content production while the core combat and game loop still feel weak.

## 5. Full Development Order

### Phase 0 — Project Foundation

Build the production-ready technical base.

- Godot project structure
- Git workflow
- Naming conventions
- Autoload/global service policy
- Scene ownership rules
- Input map
- Collision layers/masks
- Data/resource conventions
- Debug overlay/tools
- Logging/error handling
- Build configuration
- Basic automated/manual validation process

**Exit condition:** the project has a clean structure that can support the full game without needing a rewrite after the prototype stage.

---

### Phase 1 — Player Controller

- 8-direction movement
- Acceleration/deceleration if appropriate
- Mouse aiming
- Character facing
- Collision
- Dash
- Dash cooldown
- Invulnerability frames
- Knockback response
- Damage reception
- HP
- Death state

**Quality gate:** movement and aiming must already feel responsive and predictable.

---

### Phase 2 — Gun Combat

- Fire input
- Fire rate
- Projectile spawning
- Projectile collision
- Damage
- Magazine capacity
- Ammo state
- Reload
- Reload interruption rules
- Spread
- Recoil
- Burst / automatic-fire support
- Projectile lifetime
- Piercing support
- Ricochet support hooks
- Critical-hit support hooks

Add combat feel:

- Muzzle flash
- Hit flash
- Hit stop where appropriate
- Camera shake controls
- Impact VFX hooks
- Audio hooks

**Quality gate:** shooting must feel satisfying before the weapon-content count expands.

---

### Phase 3 — Enemy Combat Framework

- Enemy base class / composition policy
- State machine or equivalent AI architecture
- Aggro/targeting
- Movement
- Melee attacks
- Ranged attacks
- Telegraphs
- Damage
- Knockback
- Death
- Drops/hooks
- Spawn system

Build several deliberately different enemy archetypes rather than many cosmetic variants.

**Quality gate:** player can fight multiple enemies at once and clearly understand threats and damage sources.

---

### Phase 4 — Combat Readability & Feedback

- Enemy attack telegraphs
- Projectile readability
- Danger colors/shapes policy
- Damage feedback
- Player hurt feedback
- Enemy hurt feedback
- Death feedback
- Layering/z-order rules
- Screen shake limits
- Flash limits
- Damage numbers if retained by GDD/UI direction
- Audio priority rules

**Quality gate:** difficult combat is readable rather than visually confusing.

---

### Phase 5 — Combat Room System

- Room entry
- Door locking
- Enemy spawn points
- Wave controller
- Wave completion
- Room clear state
- Door unlock
- Reward spawn
- Next-room transition

**Quality gate:** one room provides a complete enter → fight → clear → reward → leave loop.

---

### Phase 6 — Run / Route Structure

- Room graph
- Route choice
- Normal rooms
- Elite rooms
- Reward rooms
- Shop rooms
- Event rooms
- Recovery rooms
- Boss rooms
- Zone progression
- Seed/randomization architecture

**Quality gate:** one zone can be played from entrance through its boss.

---

### Phase 7 — Weapon Frame System

Implement weapon frames as data-driven gameplay foundations.

Examples include pistol/SMG/shotgun-style frames where appropriate to the GDD.

Each frame must define meaningful mechanical identity rather than only numerical differences.

---

### Phase 8 — Gun Construction System

Core differentiator #1.

- Frame slots
- Barrel / magazine / core and other GDD-defined part categories
- Compatibility rules
- Equip/remove/swap
- Runtime stat recomputation
- Attack-pattern modification
- Effect hooks
- Tooltip/stat preview
- Invalid-build prevention

**Quality gate:** changing parts can materially change how the same weapon plays.

---

### Phase 9 — 6×5 Spatial Backpack

Core differentiator #2.

- 6×5 grid
- Item footprints
- Placement
- Drag/move
- Rotation
- Occupancy validation
- Removal
- Swap/move UX
- Item preview

**Quality gate:** spatial inventory interaction is reliable and fast enough not to interrupt run pacing excessively.

---

### Phase 10 — Backpack Synergy System

- Adjacency bonuses
- Connectors
- Power routing
- Set/link effects
- Orientation-sensitive effects if defined
- Recalculation
- Visual connection feedback
- Invalid/disabled state presentation

**Quality gate:** backpack layout produces meaningful build decisions instead of simple Tetris busywork.

---

### Phase 11 — Reward Economy

- Gold/currency
- Combat drops
- Reward choices
- Rarity
- Reward tables
- Reroll
- Risk/reward rules
- Loot presentation

---

### Phase 12 — Run Facilities

- Shop
- Crafting/workshop
- Medical/recovery facility
- Event rooms
- Secret rooms
- Other GDD-defined special rooms

---

### Phase 13 — Boss Framework

- Boss state machine
- Pattern sequencing
- Phase changes
- Telegraphs
- Arena control
- Boss HP UI
- Death sequence
- Boss reward

**Quality gate:** first-zone boss is learnable, readable and replayable rather than a simple HP sponge.

---

### Phase 14 — Complete Run

Connect the game from run start through zones, bosses, final boss and ending flow.

**Quality gate:** a player can start a run and reach an ending without developer intervention.

---

### Phase 15 — Meta Progression

- Unlocks
- Characters
- Weapon/part unlocks
- New room/event pools
- Difficulty unlocks
- Hub progression

Permanent progression should primarily expand choices rather than make raw stats overwhelm player skill.

---

### Phase 16 — Content Production Architecture

Before mass production:

- Resource/data definitions
- Enemy data
- Weapon-frame data
- Part data
- Module data
- Room definitions
- Reward tables
- Localization keys
- Content validation tools

**Quality gate:** designers/content work should not require editing core combat code for every new item.

---

### Phase 17 — Full Content Production

Expand toward GDD launch scope:

- Characters
- 4 main zones
- Secret zone if retained
- Enemy roster
- Elite roster
- Boss roster
- Weapon frames
- Gun parts
- Backpack modules
- Events
- Shops/rewards
- Narrative records
- Endings

Do not inflate quantity with low-value duplicates solely to hit counts.

---

### Phase 18 — Production Art

Replace temporary assets with coherent production assets.

- Player characters
- Enemies
- Bosses
- Tilesets
- Environments
- Props
- Weapons/parts
- Items
- Icons
- Animation
- UI art

Art direction: high-resolution pixel art per GDD.

---

### Phase 19 — VFX / Audio / Music

- Weapon audio
- Impact audio
- Enemy audio
- Boss audio
- Environment audio
- UI audio
- Music
- Combat intensity handling
- VFX polish

Maintain combat readability while increasing spectacle.

---

### Phase 20 — Full UI/UX

- Main menu
- HUD
- Inventory
- Gun construction UI
- Shop
- Route/map
- Pause
- Settings
- Tooltips
- Reward screens
- Run-result screen
- Hub UI

**Quality gate:** a first-time player can operate the game without developer explanation.

---

### Phase 21 — Tutorial / Onboarding

Teach:

- Movement
- Aim/fire
- Dash
- Reload
- Weapon construction
- Backpack placement/synergy
- Rewards
- Route choice

Avoid excessive forced tutorialization.

---

### Phase 22 — Save System

- Settings save
- Unlock save
- Progress/meta save
- Statistics
- Save versioning
- Validation
- Corruption handling/recovery strategy
- Safe write policy

**Release-blocking rule:** save corruption is a critical defect.

---

### Phase 23 — Controller Support

- Full gameplay
- Aim solution
- Menus
- Backpack
- Gun construction
- Shops
- Route map
- Text/UI navigation

**Quality gate:** the game can be completed from launch to ending without requiring a mouse.

---

### Phase 24 — Settings & Accessibility

- Rebindable controls
- Master/music/SFX volume
- Resolution/display mode
- Screen shake control
- Flash/intensity controls where applicable
- Readability options
- Other GDD-defined accessibility requirements

---

### Phase 25 — Balance

Balance using run data and deliberate playtesting.

- DPS
- Survivability
- Reload economy
- Difficulty curve
- Reward economy
- Drop rates
- Build diversity
- Boss difficulty
- Character differences
- Dominant strategy suppression

A strong build may feel powerful, but one universally correct build should not dominate the game.

---

### Phase 26 — Optimization

- Projectile pooling
- Enemy pooling where useful
- AI costs
- Physics costs
- Rendering
- Particle limits
- Memory
- Loading
- Scene transitions
- Stutter

**Quality gate:** stable target framerate under realistic late-run load.

---

### Phase 27 — QA

- Functional QA
- Regression QA
- Edge cases
- Save/load
- Long-session tests
- Repeated run tests
- Resolution tests
- Input-device tests
- Alt-tab/focus behavior
- Crash testing

**Release blockers:** progression blockers, save corruption and major crashes must be zero at release candidate approval.

---

### Phase 28 — Steam Integration

- Steamworks
- Achievements
- Statistics
- Steam Cloud
- Build/depot setup
- Release branches
- Steam Deck consideration/validation

---

### Phase 29 — Store / Release Assets

- Capsule art
- Screenshots
- Trailer
- Store copy
- Feature descriptions
- Pricing preparation
- Release metadata

Store media must show actual representative gameplay.

---

### Phase 30 — Release Candidate

Feature freeze. No casual feature expansion.

Focus on:

- Regression
- Save stability
- Performance
- Controller
- UI across resolutions
- Full-run validation
- Balance outliers
- Packaging/build correctness

---

### Phase 31 — Steam 1.0

Release the validated commercial build.

---

### Phase 32 — Post-launch

- Crash/bug fixes
- Balance patches
- Quality-of-life updates
- Content updates where justified

## 6. Milestone Structure

### M1 — Core Combat Prototype

Phases 0–5.

Order:

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

**M1 acceptance:** moving, aiming, shooting, dodging and fighting must already be enjoyable. Do not proceed merely because the checklist technically runs.

### M2 — Core Game Prototype

Phases 6–13.

Connect:

`Combat → Reward → Gun Construction → Backpack → Route Choice → Combat → Boss`

By the end of M2, the game's identity must be visible in actual play.

### M3 — Commercial Vertical Slice

Create approximately one production-quality zone slice using representative final-quality art, UI, sound and gameplay.

It should be good enough that footage could be used in a Steam trailer/store presentation.

### M4 — Alpha

- Full run playable start-to-ending
- Major systems complete
- All zones structurally present
- Content substantially populated
- No routine developer intervention needed

### M5 — Beta

- Content complete
- Balance pass
- Accessibility
- Controller
- Localization pipeline/content as required
- Steam features
- Performance
- Save validation
- External playtesting

### M6 — Release Candidate / 1.0

No major new features.

Target:

- Zero known progression blockers
- Zero known save-corruption defects
- Zero known major collision defects
- Stable performance
- Complete keyboard/mouse and controller runs
- Validated builds and Steam packaging

## 7. Launch Scope / Non-negotiable Quality Floor

The GDD defines the final launch scope; use it for exact counts and details.

The commercial 1.0 must at minimum include the major promised pillars:

- Multiple playable characters
- Four main zones
- Final boss and ending flow
- Meaningful weapon-frame variety
- Meaningful gun-part variety
- Meaningful backpack-module variety
- Full run structure
- Meta unlocks
- Save/settings
- Controller support
- Accessibility/readability settings
- Steam integration
- Enough replayable content to justify a paid package release

Never cut these quality-sensitive items simply to declare the game finished:

- Control responsiveness
- Hit/collision reliability
- Save stability
- Performance stability
- Combat readability
- Boss quality
- UI usability
- Controller support
- Onboarding

## 8. Current Development State

**Current milestone:** `M1 — Core Combat Prototype`

**Current phase:** `Phase 0 — Project Foundation`, immediately transitioning into player/combat implementation.

Repository was deliberately reset and development restarted from scratch.

Current foundation files created on `main` include the new Godot project/bootstrap structure.

The next implementation sequence is fixed as:

1. Audit/finish project foundation
2. Player scene/controller
3. Movement + collision
4. Mouse aim
5. Gun/fire pipeline
6. Magazine + reload
7. Dash + i-frames
8. HP/damage/death
9. Basic enemy framework and first archetypes
10. Combat-room controller
11. Combat feedback and feel pass
12. M1 playtest/acceptance review

## 9. Current Definition of Done

For any task, "done" should mean:

- Feature works in actual play
- No obvious error spam
- Edge cases for that feature are handled
- Architecture is reasonable for expansion
- User-facing behavior is understandable
- Relevant project documentation/status is updated

For milestones, technical completion alone is insufficient. The milestone's gameplay quality gate must also pass.

## 10. Development Rules for Future Conversations

When continuing this project in another ChatGPT conversation:

1. Open/read `PROJECT.md` first.
2. Read the canonical `LAST_MAGAZINE_GDD.md` when the task touches game design, balance, content or feature behavior.
3. Inspect the current GitHub repository before coding; do not assume an old conversation accurately reflects current code.
4. Identify the current milestone/phase from this document.
5. Continue from the first incomplete item unless the user explicitly changes priority.
6. Do not restore discarded legacy prototype code.
7. Do not skip directly to mass content production before M1/M2 quality gates pass.
8. Prefer production-quality architecture over throwaway demo hacks.
9. After meaningful implementation, update the `Current Development State` section when milestone/phase/status changes.
10. Record intentional GDD deviations under `Design Decisions`.
11. Treat Steam 1.0 commercial quality as the end target at all times.

A useful continuation request is simply:

> `@GitHub LAST MAGAZINE 이어서 개발해. PROJECT.md와 GDD 먼저 읽고 현재 단계 다음 작업부터 진행해.`

That should be sufficient context to resume work.

## 11. Design Decisions

Record deliberate deviations/clarifications here. Do not silently change core design.

### DD-001 — Clean Restart

**Status:** Accepted  
**Decision:** Discard the previous prototype and rebuild LAST MAGAZINE from scratch.  
**Reason:** The target is commercial Steam-release quality, and the new implementation should not inherit prototype architecture by default.

### DD-002 — Quality-gated Milestones

**Status:** Accepted  
**Decision:** Do not advance milestones based only on feature checklist completion.  
**Reason:** Core combat feel, usability, stability and production readiness are explicit acceptance requirements.

## 12. Progress Log

### 2026-08-01

- Confirmed complete clean restart.
- Existing prototype/project files were removed.
- Fresh Godot project/bootstrap files were created on `main`.
- Established the development sequence from project foundation through Steam 1.0.
- Added this handoff/roadmap document so development can continue safely across separate conversations.

---

**End target: paid Steam 1.0 release quality, not a disposable prototype.**
