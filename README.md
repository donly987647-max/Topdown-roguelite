# LAST MAGAZINE

Official Godot production line for the 2D top-down action roguelite **LAST MAGAZINE**.

## Current stage

**Pre-production / Foundation**

This repository contains only the clean Godot foundation. The archived HTML prototype is reference material and is not a production-code dependency.

## Engine

- Godot 4.6.x
- GDScript
- GL Compatibility renderer during pre-production
- Primary target: Windows / Steam

## Open the project

1. Install Godot 4.6.x.
2. Import `project.godot`.
3. Run the project.
4. The foundation boot screen must appear without errors.

## Development order

1. Foundation and repository structure
2. GDD-to-backlog decomposition
3. Movement, aiming, firing, dash, damage and camera
4. Core prototype
5. Zone 1 vertical slice
6. Content expansion
7. Alpha, beta and release candidate

## Rules

- No feature is called complete without an executable build and checklist evidence.
- No generated quantity is accepted as unique content without unique behavior and testing.
- `final`, `release` and `1.0` labels are reserved for builds that pass the release checklist.
