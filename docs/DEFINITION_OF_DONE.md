# Definition of Done

A task is complete only when all applicable conditions pass.

## Code

- The change exists on the official Godot development branch.
- The project opens without parser errors.
- No unrelated generated files are committed.
- System ownership and dependencies follow the documented structure.

## Function

- The function is observable in an executable build.
- Keyboard/mouse and gamepad behavior are checked when relevant.
- Save/load behavior is checked when relevant.
- Failure and edge cases are documented and tested.

## Evidence

- Automated checks pass.
- Manual verification steps are recorded.
- Known limitations are stated explicitly.
- The user has an executable build or reproducible test instruction.

## Naming

- `Prototype`: incomplete proof of concept
- `Vertical Slice`: one sale-quality representative section
- `Alpha`: all major systems and content paths present
- `Beta`: content complete; stabilization in progress
- `Release Candidate`: candidate for 1.0 after full QA
- `1.0 Release`: all release criteria passed

The labels `final`, `complete`, `release` and `1.0` are prohibited before the matching criteria are met.
