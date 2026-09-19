# AGENTS.md — Universal Rules for AI Coding Agents

> Canonical source of truth (Linux Foundation Agentic AI Foundation). Adapters stay thin and point here.

Version: **1.1.0**

---

## Mandate

Ship working, verified code. Planning is a means, not a goal. **Token waste is failure.** Guessing is failure. Skipping the task lifecycle is failure.

---

## When unsure — ASK (never invent)

**Hard rule:** if anything is ambiguous, incomplete, or has ≥2 plausible interpretations → **stop and ask the human** using the harness ask/question tool when available, otherwise a short message.

Ask when: requirements/scope unclear · design/API/naming non-obvious · small change has 2+ paths · secrets/env/prod/irreversible ops · plan or task text incomplete.

How: one focused question · 2–4 options when possible · state what you will do for each · do **not** invent defaults or code past the ambiguity.

Clear low-risk T0 → implement. Unclear → ask once, then implement.

---

## Session boot (every session)

Prefer `.agents/scripts/resume.sh` (cheapest). Otherwise:

1. `plans/context.md` (head only)
2. **Last entry only** of `plans/SESSION_LOG.md`
3. Active plan folder if resuming
4. One short Session Resume: active · last done · next · blockers
5. Act. Never assume prior-turn memory.

Missing `plans/` → `.agents/scripts/bootstrap.sh`.

**Windows (Git Bash required for scripts):**
```text
bash .agents/scripts/resume.sh
bash -lc "bash .agents/scripts/task.sh plans/my-plan 1 start"
```
Prefer **numeric** task specs (avoids quoting). Run scripts **sequentially** per plan folder (no parallel `task.sh` on the same folder). Do not paste bash `||` / `&&` / heredocs into PowerShell.
Windows-specific recipes: `docs/WINDOWS.md`.

---

## Adaptive planning (T0–T3)

**Lowest viable tier.**

| Tier | When | Create |
|------|------|--------|
| **T0** | typo / 1-liner / pure config | nothing — implement |
| **T1** | ≤~3 files, clear acceptance | `plans/<name>/plan.md` only |
| **T2** | multi-file / new module | `plan.md` + `tasks.md` + `context.md` |
| **T3** | multi-milestone / migration | `OVERVIEW.md` + sub-folders (each T1/T2) |

Hard limits:
- after required files exist → planning structure ends; **then fill them** (see lifecycle)
- ≤ 10 new files under `plans/` per session
- 3 doc-only turns → implement or ask/report blocker
- no exploration/notes/options files under `plans/`
- prefer scripts: `new-plan.sh`, `task.sh`, `close-plan.sh`, `archive.sh`

---

## Feature lifecycle (mandatory for T1+)

**Plan → Implement → Verify → Close → (Archive)**

### 1) Plan (must complete before code)

1. Choose tier → `new-plan.sh` (or equivalent files).
2. **Immediately fill** Goal, Acceptance, and Tasks (not empty checkboxes).
3. If any acceptance criterion is still unclear → **ask**, do not invent.

Empty `plan.md` / empty Tasks while writing production code = protocol violation.

### 2) Implement

- Markers: `[ ]` pending · `[~]` in-progress (**max one** per plan folder) · `[x]` after real verify · `[!]` blocked · `[-]` cancelled.
- **Prefer** `.agents/scripts/task.sh` (or `protocol.sh task`) — never hand-edit markers when scripts are available.
- Order: `task … start` → code → verify → `task … done`.
- Stay in scope. Related work → new `[ ]` item.

#### T1 checkbox semantics
- `task.sh <dir> <n>` on T1 counts `## Tasks` section by default.
- `task.sh --acceptance <dir> <n>` counts `## Acceptance`.
- `task.sh --section tasks|acceptance` for explicit selection.
- `--file plan.md` still counts ALL checkboxes (v1.0.0 behavior).

### 3) Verify (required before `[x]`)

- Lint/format pass when the project has them.
- Tests/checks implied by acceptance against **real** output.
- `verify-checklist.sh --strict plans/<name>` is the CI gate (exits non-zero if unresolved tasks remain).
- UI: open in browser or describe visual check when harness allows.
- JS/TS: syntax check (`node --check` / project test runner) when applicable.

### 4) Close (required before ending the feature)

When all tasks are `[x]` or `[-]`:

1. `close-plan.sh plans/<name>` (creates `review.md`; scans `tasks.md`, `plan.md`, and `OVERVIEW.md` for open tasks)
2. Append `SESSION_LOG.md` (what shipped, decisions, resume note)
3. Optional: `archive.sh plans/<name>`
4. Fill `review.md` `## Built` (T2/T3 required — close-plan refuses an empty one; T0.5/T1: one line in plan.md suffices)
5. Commit after every closed plan: `git add -A && git commit -m "<type>(<scope>): <desc>"`

Ending a T1+ feature with open tasks or no SESSION_LOG entry = incomplete.

Living docs same turn when relevant: dependency → `TECH_STACK` · structure → `ARCH` · decision → `DECISIONS` · pattern → `PATTERNS`.

---

## Code quality

- Strict typing where the language supports it; validate boundary inputs; explicit errors; small functions; why-comments only
- No hardcoded secrets/URLs/magic numbers
- Prefer project’s existing package manager, linter, formatter, tests

---

## Git & safety

- Conventional commits: `type(scope): what`
- Never invent secrets / `.env` / keys / `.ssh` — escalate
- Destructive ops need **explicit human confirmation**

---

## Delegation

Default solo. Subagent only if human asks or ≥2 independent units. Parallel T3: prefer git worktree isolation; one `[~]` per plan folder; exclusive file ownership.

---

## Scripts

`protocol.sh <cmd>` dispatches all. Core: `bootstrap` · `resume` · `new` · `task` · `status` · `next` · `close` · `archive` · `promote` · `doctor` · `log` · `doc` · `verify` · `test` · `sync` · `init`.

---

## Anti-patterns (never)

- T2/T3 for trivial work · giant single plan
- Coding with empty Goal/Acceptance/Tasks on T1+
- Hand-waving past `task start/done` when scripts exist
- `[x]` before real verification
- Ending feature work without close + SESSION_LOG
- Silent scope expansion · guessing instead of asking
- Bash-only one-liners in PowerShell
- `tools: []` on subagents · writing secrets

---

## Adapters

| Tool | Path |
|------|------|
| Universal | **AGENTS.md** (this file) |
| Claude Code | `CLAUDE.md` + `.claude/skills|agents` |
| Codex | AGENTS.md + `.codex/skills` |
| Gemini / Antigravity | `GEMINI.md` |
| Cursor | `.cursor/rules/*.mdc` |
| Copilot | `.github/copilot-instructions.md` |
| Windsurf / Devin | `.windsurfrules` + `.windsurf/rules` + `.devin/rules` |
| Cline / Roo | `.clinerules` / `.roorules` |
| OpenCode / Aider / Zed | AGENTS.md native |

Details: `adapters/README.md` · install: `sync-adapters.sh` / `init`.

Long architecture and dependency lists live in `plans/`, not here.
