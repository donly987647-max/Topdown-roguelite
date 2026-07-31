# Project Structure

- `autoload/`: cross-system services only.
- `core/`: shared constants and non-node types.
- `scripts/input/`: device-neutral command model and rebinding.
- `scripts/player/`: player motion and state ownership.
- `scripts/combat/`: damage and health contracts.
- `scripts/weapons/`: weapon behavior.
- `scripts/projectiles/`: projectile data and continuous collision.
- `scripts/enemies/`: role-specific enemy behavior.
- `scripts/world/`: handmade room ownership and hazards.
- `scripts/camera/`, `scripts/ui/`, `scripts/vfx/`: presentation domains.
- `tests/`: headless automated checks.
- `tools/`: repository validation and production utilities.

No gameplay system may depend on the archived HTML prototype.
