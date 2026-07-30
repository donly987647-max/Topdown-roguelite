# P1 Internal Resolution Decision

## Provisional baseline: 960×540

The 20×12 tile test room is 640×384 pixels at the GDD's 32 px tile size. A 640×360 internal viewport cannot display the full small-room height without cropping or zoom changes. The prototype therefore uses 960×540, which:

- preserves integer-friendly 16:9 output;
- gives enough vertical room for a 384 px combat area plus UI;
- supports the planned 48×64 player sprite scale;
- provides more readable projectile telegraphs on modern monitors.

This remains provisional until two engine captures and a playability comparison are reviewed under `P1-ART-001`.
