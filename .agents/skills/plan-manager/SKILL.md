---
name: plan-manager
description: >
  Tier selection (T0–T3), plan split, lifecycle. Use before any new plan folder.
  Keeps plan cost proportional to risk. Prefer scripts over hand-written structure.
compatibility: Any agent that can create files and/or run .agents/scripts/
metadata:
  version: "1.0.0"
---

# Plan Manager

## Tier (lowest viable)

| Signal | Tier |
|--------|------|
| 1 file, obvious | **T0** — no files |
| ≤3 files, clear acceptance | **T1** — `plan.md` only |
| 4–15 files / new module | **T2** — plan + tasks + context |
| multi-milestone / cross-cutting | **T3** — OVERVIEW + sub-folders (each T1/T2) |

Human says “quick / small / just X” → T0/T1. “build system / migrate / refactor” → T3 + split.

If tier or scope is unclear → **ask the human** (one question, options). Do not invent scope.

## Create / close

```bash
.agents/scripts/new-plan.sh T1|T2|T3 <name> [parent]
.agents/scripts/close-plan.sh plans/<name>
.agents/scripts/archive.sh plans/<name>
.agents/scripts/promote.sh plans/<name>   # T1 → T2
```

T3 layout: `plans/<epic>/OVERVIEW.md` + `01-…/` sub-folders. No nested OVERVIEW inside subs.

## Token rules

- Never add tasks.md/context.md “just in case” for T1
- Bullets only; plan file >80 lines → stop, implement or split
- No notes/exploration files under `plans/`
- Checkbox changes only via `task.sh`
