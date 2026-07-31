# P1 Internal Resolution and Scale Decision

## Final P1 baseline: 960×540

The 20×12 tile test room is 640×384 pixels at the GDD's 32 px tile size. Two engine captures were generated from the same P1 scene on Godot 4.6.3.

### Capture evidence

- Source commit: `5cbf25473c8aaca66ddcbb2f3523df57a8b58d97`
- CI run: `30595806394`
- 640×360 capture SHA-256: `b53a7b41e37eacb62e8bbf15e8bffde92e5a0a9e16e70030f2ae6d4e53639c0c`
- 960×540 capture SHA-256: `7ad26fca637d13ff084ff6f4fba499e4e08a01831321d9fc55d19ae2a11dd1c8`

### Comparison

640×360 cannot display the full 384 px room height and the bottom HUD at the same time. The capture crops the room framing and removes the control-status line. It would require camera zoom changes or a smaller tile scale, both of which reduce threat readability.

960×540 displays the full small-room combat area, top enemy counter and bottom status line without zoom changes. Enemy telegraphs, hazards, cover and the player aim indicator remain separated at the current scale.

### Locked P1 scale contract

- Internal viewport: 960×540
- Tile size: 32 px
- Player collision radius: 11 px
- Player placeholder body radius: 15 px
- Planned authored player sprite envelope: approximately 48×64 px
- Collider remains smaller than the visible sprite and should not be expanded to the full sprite envelope without a new fairness review.

The authored art is not final, but the gameplay scale and collider relationship are accepted for P1. `P1-ART-001` and `P1-ART-002` are complete.
