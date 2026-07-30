# Development Backlog

This directory converts `LAST_MAGAZINE_GDD.md` GDD 1.0 into an executable production backlog.

## Files

- `MASTER_BACKLOG.md`: summary and phase links
- `phases/P0.md` through `phases/P6.md`: complete task backlog
- `BACKLOG.csv`: spreadsheet/import-friendly task table in the downloadable package
- `EXECUTION_ORDER.md`: milestone gates and mandatory work order
- `TRACEABILITY_MATRIX.md`: GDD sections 1–80 mapped to task IDs
- `CONTENT_TARGETS.md`: vertical slice, alpha and 1.0 content quantities
- `RISK_REGISTER.md`: major risks and controlling backlog items

## Rules

1. Work proceeds in phase order.
2. A later production phase does not begin before the prior gate is approved.
3. Content count alone is never sufficient for completion.
4. Every completed task must satisfy `docs/DEFINITION_OF_DONE.md`.
5. GDD terminology and numerical targets remain the source of truth unless an explicit design decision updates the baseline.

Current backlog item count: **167**
Traceability gaps: **0** (none)