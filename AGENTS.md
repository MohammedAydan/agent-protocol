# AGENTS.md — Universal Rules for AI Coding Agents

> Canonical source of truth (Linux Foundation Agentic AI Foundation). Adapters stay thin and point here.

Version: **1.0.0**

---

## Mandate

Ship working, verified code. Planning is a means, not a goal. **Token waste is failure.** Guessing is failure.

---

## When unsure — ASK (never invent)

**Hard rule:** if anything is ambiguous, incomplete, or has ≥2 plausible interpretations → **stop and ask the human** using the harness ask/question tool when available, otherwise a short message.

Ask when:
- requirements, acceptance, or scope are unclear
- design/API/library/naming choice is non-obvious
- a small change still has 2+ reasonable paths
- secrets, env values, prod config, or irreversible ops are involved
- the plan or task text is incomplete

How to ask:
- one focused question
- 2–4 concrete options when possible
- state what you will do if they pick each option
- do **not** explore for many turns, invent “reasonable defaults”, or code past the ambiguity

Clear and low-risk (T0 typo/config) → implement. Unclear → ask once, then implement.

---

## Session boot (every session)

Prefer `.agents/scripts/resume.sh` (cheapest). Otherwise:

1. `plans/context.md` (if exists) — head only
2. **Last entry only** of `plans/SESSION_LOG.md`
3. Active plan folder if resuming
4. One short Session Resume line: active · last done · next · blockers
5. Act. Never assume prior-turn memory.

Missing `plans/` → `.agents/scripts/bootstrap.sh`.

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
- after required files exist → planning ends
- ≤ 10 new files under `plans/` per session
- 3 doc-only turns → implement or ask/report blocker
- no exploration/notes/options files under `plans/`
- prefer scripts: `new-plan.sh`, `task.sh`, `close-plan.sh`, `archive.sh`

Markers: `[ ]` pending · `[~]` in-progress (**one** per plan folder) · `[x]` after real verify · `[!]` blocked · `[-]` cancelled. Use `task.sh` — never hand-edit.

Cycle: **Plan → Implement → Verify → Close → Archive**.

Living docs same turn: dependency → `TECH_STACK` · structure → `ARCH` · decision → `DECISIONS` · pattern → `PATTERNS`. Append `SESSION_LOG` at end of session.

---

## Code quality

- Strict typing; validate boundary inputs; explicit errors; small functions; why-comments only
- No hardcoded secrets/URLs/magic numbers
- Prefer project’s existing package manager, linter, formatter, tests
- `[x]` only after: lint/format pass + real tests from acceptance + UI evidence if supported

---

## Git & safety

- Conventional commits: `type(scope): what`
- Never invent secrets / `.env` / keys / `.ssh` — escalate
- Destructive ops need **explicit human confirmation**

---

## Delegation

Default solo. Subagent only if human asks or ≥2 independent units. Parallel T3: prefer git worktree isolation; one `[~]` per plan folder; exclusive file ownership.

---

## Scripts (prefer over hand-writing)

`protocol.sh <cmd>` dispatches all. Core: `bootstrap` · `resume` · `new` · `task` · `status` · `next` · `close` · `archive` · `promote` · `doctor` · `log` · `doc` · `verify` · `test` · `sync`.

---

## Anti-patterns

T2/T3 for trivial work · giant single plan · `[x]` before verify · silent scope expansion · guessing instead of asking · endless planning · `tools: []` on subagents · writing secrets

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

Details: `adapters/README.md` · install: `sync-adapters.sh`.

Long architecture and dependency lists live in `plans/`, not here.
