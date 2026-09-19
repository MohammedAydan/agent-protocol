# Changelog

## 1.0.0 — 2026-09-19

### Tooling patch (same 1.0.0)

- **Global CLI** `bin/agent-protocol` + `install-global.sh`
  - `agent-protocol init | update | upgrade | doctor | test | stress | version`
- **`update-project.sh`**: refresh protocol in a project from global package; **never deletes `plans/`**
- **`test-stress.sh`**: 33 edge-case tests (nested Active Plans, last-plan, markers, archive safety)
- Smoke: 29 passed · Stress: 33 passed
- Fixed self-copy bug when `update` ran without global home


### Hardening patch (same 1.0.0 — post benchmark)

- **close-plan / archive:** Active Plans removal safe under `pipefail` when removing the **last** plan (`Active Plans: none`, exit 0)
- **task.sh:** `--file plan.md|tasks.md` and `--acceptance` for T2 acceptance boxes
- **doctor:** warns on empty `review.md` stubs
- **test-scripts.sh:** isolated temp workdir + last-plan regression + acceptance flags
- **AGENTS.md:** Windows `bash -lc` calling convention + sequential task.sh note


**First production release.**

Stable, token-efficient protocol for AI coding agents across 30+ harnesses.

### Core
- Adaptive planning **T0–T3** (lowest viable tier; hard anti-loop)
- Cycle: Plan → Implement → Verify → Close → Archive
- Task markers with mechanical enforcement via `task.sh` (one `[~]` per plan folder)
- Living docs: context, SESSION_LOG, ARCH, TECH_STACK, DECISIONS, PATTERNS
- **Ask when unsure**: never invent requirements — ask the human (harness ask tool when available)

### Token efficiency
- Lean `AGENTS.md` (~4.3KB) as single source of truth
- Compressed skills, subagent prompt, and engineering standards
- Thin adapters only (no rule duplication)
- `resume.sh`: minimal context + last log + max 3 next tasks
- Short plan templates

### Scripts (plain bash)

### Install UX & safety
- **`init.sh` / `./init`**: Speckit-style; `--here`, `--force`, `--adapters all|none|list`, interactive harness picker
- **Never overwrites** user `README.md`, app source, or non-protocol files
- **`sync-adapters.sh --only`**: install only selected harness mirrors
- **`install-remote.sh`**: GitHub one-liner installer (HTTPS only, temp extract, pinned tag via `AGENT_PROTOCOL_REF`)
- Refuses install into system paths (`/`, `/usr`, …)

- **`init.sh` / `./init`** — Speckit-style add to any project: `--here`, `--force`, safe merge, no app code touched
- `protocol.sh` dispatcher
- `bootstrap` / `install` / `sync-adapters`
- `new-plan` (overwrite guard, parent epic check, Active Plans auto-update)
- `task` / `status` / `list` / `next` / `resume`
- `close` / `archive` / `promote` (guards on open/blocked tasks)
- `doctor` / `test-scripts` (18 smoke checks)
- `session-log` / `update-doc` / `verify-checklist`

### Compatibility
- Native `AGENTS.md` for Codex, Aider, Zed, Roo, OpenCode, and 25+ others
- Claude Code: `CLAUDE.md` + `.claude/skills|agents` mirrors
- Cursor, Copilot, Windsurf/Devin Desktop, Cline, Roo, Gemini/Antigravity thin adapters
- Parallel T3 guidance: git worktree isolation when supported

### Safety
- No secrets / `.env` / keys invented or written
- Destructive ops require explicit human confirmation
- Closed plans archived, never deleted

---

### Pre-production history (internal)

Internal iterations labeled 2.0–2.3 validated:
- pipefail-safe status counts, next-task without subshell bugs
- close/archive guards, overwrite protection
- Active Plans auto-update, `_archive/` isolation
- skills version alignment, smoke suite
- token compression and ask-when-unsure as hard rule

Those learnings are folded into **1.0.0**; this is the supported production line.

### Learnings patch (same 1.0.0 — post portfolio session)

From real agent runs (portfolio T1 on Windows):

- **Fill plan before code** — empty Goal/Acceptance/Tasks is a protocol violation
- **Task lifecycle mandatory** — `start` → implement → verify → `done` when scripts exist
- **Close required** — `close-plan` + SESSION_LOG before ending T1+ feature work
- **Windows shell** — use Git Bash for `.agents/scripts`; do not embed bash `||` / complex one-liners in PowerShell
- OpenCode / native AGENTS.md readers called out in adapter table

No breaking install API changes.

