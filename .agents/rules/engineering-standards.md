---
trigger: always_on
---
# Engineering Standards (v1.0.0)

Referenced by AGENTS.md. Apply to every language.

## Status markers

```
[ ] pending   [~] in-progress (max 1 per plan folder)
[x] done (after real verification)
[!] blocked: reason   [-] cancelled: reason
```

Use `task.sh` — never hand-edit markers.

## plans/ layout

```
plans/
├── context.md · SESSION_LOG.md · ARCH.md · TECH_STACK.md · DECISIONS.md · PATTERNS.md
├── _archive/                 # closed plans (archive.sh)
├── <feature>/                # T1 or T2
│   ├── plan.md               # ≤ 80 lines
│   ├── tasks.md · context.md # T2+
│   └── review.md             # after Close
└── <epic>/                   # T3
    ├── OVERVIEW.md           # ≤ 80 lines
    └── <sub>/                # each T1 or T2
```

Limits: T0=0 · T1=1 · T2=3 files · ≤10 new plans/ files per session · no exploration docs · closed → `_archive/` (never delete).

## Anti-loop

Lowest tier · required files exist → plan ends · >80 lines → implement · 3 doc-only turns → implement or ask · prefer code over docs.

## Code quality

- Strict typing; no `any`; no unchecked casts
- Validate every boundary input
- Explicit errors; no silent catch
- Small functions; composition over inheritance
- Comments = *why* only
- Config/env for secrets, URLs, magic numbers

## Stack gates (adjust via TECH_STACK.md)

- **TypeScript**: strict; discriminated unions; exhaustive `never` switch
- **Next.js**: server components default; audit every `'use client'`; no secret leakage
- **NestJS / .NET**: controller → service → repository; DI; validate + auth on protected routes
- **Firebase**: rules per collection; never trust client IDs; batch multi-doc writes
- **Flutter**: existing state-management only; minimize rebuilds
- **SQL**: parameterized only; transactions for multi-row; index new patterns

## Testing / Git / Security

- Real runs required for `[x]`; co-locate tests
- `type(scope): what` — feat fix refactor chore docs test perf; no secrets in commits
- Never write `.env` / keystores / `.ssh`; escalate; confirm destructive ops with human
- Unsure about a choice → ask the human (do not invent)
