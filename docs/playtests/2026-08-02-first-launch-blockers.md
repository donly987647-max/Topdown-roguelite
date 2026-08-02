# 2026-08-02 First Hands-On Playtest — Blocking Findings

## Context
First user hands-on launch of the Godot 4.7.1 P2 integrated slice after parser/boot CI was made green.

This document records the exact user-visible blockers, root causes, required behavior, implementation changes, and regression gates. These findings are release-blocking until fixed and verified.

## Finding 1 — Display does not fill the screen / route graph appears during combat

### User report
- Game window does not fill the display.
- Full run-map route nodes are visible during active combat.
- Required behavior: combat should remain visually focused on combat; after combat resolution, the route/map selection screen should appear for the next room choice.

### Root cause
1. `project.godot` used a 1920×1080 viewport but forced a 1280×720 desktop window override.
2. `RunUiBinder._unhandled_input()` allowed the full `RunMapPanel` to be toggled during gameplay. This conflated the GDD combat minimap requirement with the separate full route graph used for post-room decisions.

### Fix
- Desktop startup changed to fullscreen (`display/window/size/mode=3`).
- Canvas stretch aspect changed to `expand` so the game fills the available display area.
- Full route graph can no longer be opened as an in-combat overlay.
- `RunMapPanel` is now shown only when `route_panel_requested` is emitted after room/reward resolution.
- Room transition defensively hides the route panel.
- `toggle_map` is consumed during combat until a dedicated lightweight combat minimap is implemented separately.

### Acceptance criteria
- F5 launch opens fullscreen on desktop.
- Full route graph is hidden while enemies are active.
- After a room is cleared and any mandatory reward selection is resolved, the route graph opens and allows choosing the next room.
- Selecting a route hides the map before the next room begins.

## Finding 2 — Player bullets pass through normal enemies

### User report
Player projectiles visibly pass through enemies and do not apply damage.

### Root cause
`Projectile.tscn` correctly scans physics layer 5 (`EnemyBody`), but `zone1_melee.tscn` and `zone1_ranged.tscn` did not define collision layers and therefore remained on Godot's default layer 1. The boss already used the correct EnemyBody layer, which exposed the inconsistency.

Related collision audit also found:
- melee `AttackArea` was not configured for the `EnemyAttack → PlayerHurtbox` matrix;
- the ranged enemy projectile scene under `scenes/enemies/` had default collision settings instead of `EnemyProjectile` settings.

### Fix
- Zone 1 melee/ranged root bodies: `collision_layer=16` (EnemyBody), `collision_mask=3` (PlayerBody + World).
- Melee attack area: `collision_layer=64` (EnemyAttack), `collision_mask=4` (PlayerHurtbox).
- Enemy projectile scenes: `collision_layer=32` (EnemyProjectile), `collision_mask=7` (PlayerBody + World + PlayerHurtbox).
- Added CI regression assertions for the collision matrix.

### Acceptance criteria
- Service Pistol projectile collides with and damages both Zone 1 melee and ranged enemies.
- Enemy melee contact attack detects the player hurtbox.
- Ranged enemy projectiles collide with the player/hurtbox and world.
- Collision-layer regression smoke passes in CI.

## Finding 3 — Starter weapon reserve ammo can run out and block progression

### User report
A starter gun with finite total ammunition can leave the player unable to continue the run after reserve ammo is exhausted.

### Decision
Player weapons use a finite magazine/reload loop but **infinite reserve ammo**. Reload timing, magazine size, perfect reload, heat and weapon-part magazine behavior remain meaningful; total reserve depletion is not allowed to soft-lock a run.

This is an explicit user-directed implementation deviation from the current GDD wording that references reserve ammo/ammo purchases. The GDD/economy treatment of ammo pickups and shop ammo must later be reconciled around buffs/temporary resources rather than a hard total-ammo depletion gate.

### Fix
- Player `CombatController` starts with `infinite_reserve_ammo=true`.
- `StarterWeaponRuntime` explicitly enforces infinite reserve whenever a starting frame is applied.
- HUD already renders infinite reserve as `∞`.
- Added regression test: a starter weapon at `ammo=0`, `reserve_ammo=0` must still be able to begin reload.

### Acceptance criteria
- Magazine can reach zero and still auto/manual reload.
- Reserve ammo never prevents run progression.
- HUD shows infinite reserve.

## Regression gate added
`tools/first_playtest_regression_smoke.gd` verifies:
1. fullscreen display contract;
2. PlayerProjectile ↔ EnemyBody collision contract;
3. EnemyAttack/EnemyProjectile ↔ PlayerHurtbox collision contract;
4. infinite starter reserve ammo and zero-reserve reload;
5. full route map cannot be manually opened during combat and does open for post-combat route selection.

The Godot 4.7.1 validation workflow now runs this test before the existing runtime/P2 smoke suites.
