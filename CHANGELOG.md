# Changelog

## 1.1.0 — 2026-09-19

### Hardening Release (D1–D13)

- **D1 (`task.sh` section scoping):** Added `--section tasks|acceptance` flag; `task.sh` defaults to scoping numeric indices to `## Tasks` in `plan.md` for T1 plans, preventing index corruption from acceptance checkboxes (`5569b19`).
- **D2 (Archive nesting):** `archive.sh` preserves nested T3 epic hierarchy under `plans/_archive/<epic>/<child>` instead of flattening into root `_archive/` (`55a02fd`).
- **D3 (Windows documentation):** Added comprehensive `docs/WINDOWS.md` guide covering PowerShell 5.1, PowerShell 7+, and Git Bash environments; updated installer warnings and usage docs (`781fbcb`).
- **D4 (CLI help flags):** Added `--help` / `-h` with exit 0 to all 19 protocol shell scripts (`b7eefe3`).
- **D5 (Strict verification mode):** Added `--strict` mode to `verify-checklist.sh` that scans `tasks.md`, `plan.md`, and `OVERVIEW.md` and exits non-zero with file and line numbers for any open `[ ]`, `[~]`, or `[!]` tasks (`527f83e`).
- **D6 & D9 (Encoding lint & gitattributes guard):** Added `.agents/scripts/lint-encoding.sh` checking for UTF-8 BOM, CRLF terminators in `.sh` files, and `.gitattributes` presence; wired into `protocol.sh lint` (`a3e7883`).
- **D7 (T1 checkbox semantics):** Clarified T1 checkbox semantics in `AGENTS.md`, updated `T1-plan.md` template, and documented rules in `new-plan.sh --help` (`1e57299`).
- **D8 (Unified update path):** Unified PowerShell `Update-Project` to delegate to `update-project.sh` via Git Bash when present; normalized fallback writes to UTF-8 no-BOM with LF line terminators; achieved clean `diff -r` parity (`733773c`).
- **D10 (Plans policy):** Defined repo `plans/` policy under ADR-003 Option B: minimal brain files tracked, volatile plan folders ignored, installers verify clean isolation (`aad77e1`).
- **D11 (ASCII-safe symbols):** Added `--ascii` flag to `doctor.sh` and `status.sh` providing `[OK]` and `[WARN]` indicators for raster consoles while preserving byte-identical UTF-8 defaults (`e7c16a5`).
- **D12 (OVERVIEW.md scan):** `close-plan.sh` and `archive.sh` scan `OVERVIEW.md` for unresolved tasks before closing or archiving T3 epics (`bbcb862`).
- **D13 (Promote regression guard):** Added stress test suite guard ensuring T1 to T2 promotion preserves all tasks and prevents HTML comments leaking into `tasks.md` (`f90aeef`).

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

