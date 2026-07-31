# P1 Combat Prototype Implementation

## Completed backlog items

- `P1-INPUT-001`: unified keyboard/mouse, gamepad and mobile command layer, runtime rebinding API and local persistence
- `P1-MOVE-001`: 8-direction movement, diagonal normalization, 260 px/s, 0.08 s acceleration and 0.06 s deceleration
- `P1-AIM-001`: movement-independent mouse, right-stick and touch aiming
- `P1-DASH-001`: 0.52 s / 150 px dash with 0.12–0.34 s invulnerability and 0.35 s cooldown
- `P1-DASH-002`: separate near-miss precision-dodge detection and event
- `P1-DASH-003`: room-bound, obstacle and instant-hazard endpoint correction; high-difficulty bypass flag
- `P1-COMBAT-001`: temporary shield → armor plate → health damage order
- `P1-COMBAT-002`: 0.75 s post-hit protection and attack-ID duplicate rejection
- `P1-WEAPON-001`: data-backed service pistol, 18 damage, 0.24 s interval, 10-round magazine, 1.15 s reload
- `P1-PROJ-001`: complete projectile Resource contract from GDD §11.2
- `P1-PROJ-002`: swept ray collision each physics tick to prevent tunneling
- `P1-ENEMY-001`: training gunner with detection, preferred distance, separation, line-of-sight and 0.65 s telegraph
- `P1-ROOM-001`: handmade 20×12 tile combat room with walls, obstacles, spawn points, hazard and camera bounds
- `P1-CAM-001`: smooth follow, 80 px aim lead and room clamping
- `P1-CAM-002`: distance-scaled capped screen shake
- `P1-HIT-001`: hit stop, spark, flash, sound, knockback and critical-aware event path
- `P1-AUDIO-001`: distinguishable temporary fire, hit, dash, telegraph, reload and hurt cues
- `P1-TEST-001`: structure, GDD constants, health order, projectile contract, mobile bridge and PC input contract tests
- `P1-ART-001`: 640×360 and 960×540 engine captures compared; 960×540 selected
- `P1-ART-002`: tile, placeholder body, collider and planned authored-sprite scale contract recorded
- `P1-DESIGN-001`: design-pillar review passed
- `P1-GATE-001`: product owner approved P1 core combat feel and continuation to P2

## Validation evidence

- Godot version: 4.6.3 stable
- Final validation source: `5cbf25473c8aaca66ddcbb2f3523df57a8b58d97`
- CI run: `30595806394`
- Repository and GDD checks: passed
- Godot import: passed
- P1 automated tests: passed
- Resolution captures: passed
- Windows export: passed
- Android export: passed
- Product-owner mobile playtest: passed

## Carried risk

A short human Windows keyboard/mouse and gamepad feel check remains required before P2 can be marked complete. The automated PC input contract already passes. This risk is explicit and does not block beginning P2 implementation.

Therefore P1 is a **passed pre-production milestone**, not a final game, alpha or commercial release candidate.
