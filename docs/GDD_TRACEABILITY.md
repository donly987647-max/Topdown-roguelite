# GDD traceability — reboot baseline

This file maps the first implementation directly to `LAST_MAGAZINE_GDD.md` requirements.

| GDD section | Requirement | Current implementation |
|---|---|---|
| 7.1 / 7.2 | WASD + mouse, gamepad movement/aim/fire/dodge/reload | `scripts/player/player.gd`, `scripts/combat/weapon_controller.gd` |
| 8.1 | 260 px/s, 0.08 s accel, 0.06 s decel | `scripts/player/player.gd` |
| 9.1 | 0.52 s dodge, iframe 0.12–0.34 s, ~150 px, 0.35 s cooldown | `scripts/player/player.gd` |
| 10.1 / 10.2 | 100 HP, 0.75 s post-hit protection | `scripts/player/player.gd` |
| 11.1 | aim independent from movement | `scripts/player/player.gd` |
| 11.2 | projectile data + anti-tunneling collision direction | `scripts/combat/projectile.gd` uses per-physics-frame segment ray query |
| 12 | magazine, reserve ammo, manual/auto reload, perfect reload hook, dodge cancel | `scripts/combat/weapon_controller.gd` |
| 29 | role-based enemy movement and attack telegraph | `scripts/enemies/enemy.gd` |
| 30.3 | Scrap Runner / Bolt Shooter | `data/enemies/*.json` |
| 47 | combat-critical HUD | `scripts/ui/hud.gd` |
| 63.2 | data-driven content | `data/weapons`, `data/enemies` |
| 63.3 | event-driven effect hooks | `scripts/core/event_bus.gd` |
| 72.2 | Core Prototype target | `docs/ROADMAP.md` Phase 1 |
| 74.3 | control/hit/dodge/frame/UI/gamepad cannot be cut | treated as QA gates in roadmap |

## Intentional omissions in this baseline

The reboot baseline is not claiming GDD completion. The following are the immediate next implementation targets:

- frame/barrel/magazine/core weapon assembly
- equipment grid and connector graph
- reward selection and room routing
- threat-budget encounter composition
- additional Zone 1 enemies
- shop/crafting economy
- GR-01 boss prototype
- save/settings/accessibility layers

Every new system should add or update its traceability row rather than silently diverging from the GDD.
