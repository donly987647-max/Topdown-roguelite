# P1 Combat Prototype Implementation

## Implemented backlog items

- `P1-INPUT-001`: unified keyboard/mouse and gamepad command layer, runtime rebinding API and local persistence
- `P1-MOVE-001`: 8-direction movement, diagonal normalization, 260 px/s, 0.08 s acceleration and 0.06 s deceleration
- `P1-AIM-001`: movement-independent mouse and right-stick aiming
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
- `P1-TEST-001`: structure, GDD constant, health order and projectile contract tests

## Still blocked from completion

- `P1-ART-001`: 640×360 and 960×540 captured comparison requires an actual engine render review. Current implementation uses 960×540 as the provisional baseline.
- `P1-ART-002`: provisional vector placeholders exist, but final sprite/collider evidence awaits the art-scale review.
- `P1-DESIGN-001`: checklist created; requires product review during the first play session.
- `P1-GATE-001`: cannot pass until the user completes the five-minute combat-feel test.

Therefore this build is **P1 prototype candidate**, not a passed P1 milestone.
