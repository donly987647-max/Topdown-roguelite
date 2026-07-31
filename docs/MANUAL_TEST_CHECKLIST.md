# P1 Five-minute Manual Test — Recorded

## Controls

- [x] Movement reacts immediately and diagonal speed does not exceed cardinal speed. Mobile feel approved by the product owner; diagonal normalization is automated.
- [x] Aiming remains independent while moving. Approved on touch; mouse independence is covered by the PC input contract.
- [x] Keyboard/mouse and gamepad device switching does not lock the command layer. Automated contract passed.
- [x] Dash travels consistently and cannot be redirected mid-dash. Mobile play approval plus fixed P1 constants and automated checks.
- [x] Reload duration remains 1.15 seconds. Automated constant check passed and mobile control was usable.

## Readability and fairness

- [x] Enemy shots use a visible line and pre-attack sound path.
- [x] No unexplained hit or unreadable attack issue was reported during the mobile playtest.
- [x] Dash invulnerability uses the locked 0.12–0.34 second interval.
- [x] Precision dodge rejects duplicate triggers per projectile ID.
- [x] Hazard endpoint correction remains enabled in normal mode.

## Combat feel

- [x] Product owner reported the P1 build felt acceptable and approved continued development.
- [x] Service pistol remains semi-automatic at the 0.24 second fire interval.
- [x] Hit, player damage, dash, reload and enemy telegraph cues use separate feedback paths.
- [x] No camera-nausea or screen-shake readability issue was reported during the mobile playtest.
- [x] No crash, softlock or control loss was reported during the completed mobile playtest.

## Approval record

- Tester: Product owner
- Date: 2026-07-31
- Input device: Android touch controls
- Result: PASS for P1 core combat-feel gate
- Product-owner decision: proceed to the next development phase
- Required changes before P2 completion: perform a short human Windows keyboard/mouse and gamepad feel check; automated PC input contracts already pass.

The deferred desktop feel check is tracked as a P2 completion requirement. It does not block starting P2 implementation, but it cannot be silently omitted from the P2 gate.
