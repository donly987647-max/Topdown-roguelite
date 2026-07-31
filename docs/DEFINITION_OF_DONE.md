# Definition of Done

A task is complete only when all applicable conditions pass.

## Code
- The change exists on `godot-main`.
- The project imports without parser errors.
- No unrelated generated files are committed.
- Ownership and dependencies follow `PROJECT_STRUCTURE.md`.

## Function
- The behavior is observable in an executable build.
- Keyboard/mouse and gamepad behavior are checked when relevant.
- Failure and boundary cases are documented and tested.

## Evidence
- Automated checks pass.
- Manual verification is recorded.
- Known limitations are explicit.
- The user has a reproducible build or test instruction.

## Naming
`Prototype`, `Vertical Slice`, `Alpha`, `Beta`, `Release Candidate`, and `1.0 Release` are used only after their matching gates pass. The labels `final`, `complete`, `release`, and `1.0` are prohibited before that point.
