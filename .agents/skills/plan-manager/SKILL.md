---
name: plan-manager
description: >
  Tier selection (T0–T3), plan split, lifecycle. Use before any new plan folder.
  After create, fill Goal/Acceptance/Tasks before coding.
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

Unclear tier/scope → **ask**. Do not invent scope.

## Create then fill

```bash
.agents/scripts/new-plan.sh T1|T2|T3 <name> [parent]
```

**Immediately** write real Goal, Acceptance checkboxes, and concrete Tasks.  
Empty templates are not a finished plan.

```bash
.agents/scripts/task.sh plans/<name> 1 start   # before code
.agents/scripts/task.sh plans/<name> 1 done    # after verify
.agents/scripts/close-plan.sh plans/<name>
.agents/scripts/archive.sh plans/<name>
```

## Token rules

- Never add tasks.md/context.md “just in case” for T1  
- Bullets only; plan file >80 lines → stop, implement or split  
- No notes/exploration files under `plans/`  
- Checkbox changes via `task.sh` when available  
