# Architecture baseline

## Core rule

Gameplay values live in data, not hard-coded content classes. Runtime code owns behavior; definitions own tuning.

## Current modules

- `GameManager`: run seed, time, kills, damage, run lifecycle
- `EventBus`: event-driven effect hooks
- `Player`: movement, aim, dodge, HP, damage protection
- `WeaponController`: ammo, fire cadence, reload, perfect reload
- `Projectile`: continuous segment collision test each physics tick
- `Enemy`: role-based movement and attack telegraphing
- `EncounterDirector`: wave composition and progression
- `HUD`: only combat-critical information

## Collision layers

1. Player
2. Enemy
3. Reserved for loot/interactables
4. World geometry

Projectiles intentionally use segment ray queries rather than relying only on discrete overlap checks. This is the first step toward the GDD requirement that fast bullets must not tunnel through targets.

## Next architecture work

The next implementation should convert weapon composition and item effects into reusable resources/components. The effect pipeline should subscribe to EventBus signals rather than branching on item IDs inside combat controllers.
