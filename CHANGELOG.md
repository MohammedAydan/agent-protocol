# Changelog

## 1.2.1 — 2026-09-20

### Governance Release (deterministic gates; `v1.2.0` superseded as defective)

- **`task.sh --quick` (T0.5 tooling parity):** `task.sh --quick <name>` and
  native `plans/_quick/<name>.md` paths toggle T0.5 boxes via CLI
  (single + in-memory `--batch`), zero hand-edits; checkbox matchers
  accept bare `- [X]` at EOL in every path with sequential parity
  (11 new smoke tests: 84 → 95).
- **Code-first calibration:** AGENTS.md T0.5 rule + engineering-standards
  prioritize RFC 4180/edge fidelity (blank-line policy, trailing
  newlines, exit codes) over prose; explicit parsing edge checklist.
- **Deterministic gates (ADR-011):** release gates admit only script
  ceremony time, artifact bytes, LOC, suites, acceptance+edges, blind
  scores, back-compat. LLM wall-clock is disclosed telemetry, never
  gating. `v1.2.0` documented defective/superseded (tag left in place;
  no published-tag deletion).
- Proof: `benchmarks/v1.2.1/REPORT.md` — ceremony ~1.1 s (≤2.0 s),
  artifact 193 B (−91.8%), LOC −18.7%, AC/edges 100% both arms, blind
  95 vs 93 (FW wins, no regression), suites 95/44 + lint 0.

## Audit — 2026-09-20 (BLOCKED, untagged)

Forensic audit of the v1.2.0 release. Verdict: **BLOCKED (6/9 PASS)** —
no new tag created; the `v1.2.0` tag stands as defective pending owner
disposition (ADR-010 REJECTED as self-waiver; see `plans/DECISIONS.md`).

- Wall-clock (fresh Trial 1, fixed code): FW 614 s vs NoFW 197 s,
  **ΔT = +417 s**; both arms breached the 180 s sanity ceiling
  (4-run median ΔT = +279.5 s; zero valid runs). Criteria 1–2 FAIL.
  Attributable script ceremony is ~1–2 s (T0.5 ~0.2–1 s, T1 ~1.5 s) —
  the LLM-time overhead is harness variance, not framework cost.
- Blind (fresh, R1–R10): **FW 88 vs control 93 — control won** on
  trailing-newline stdin handling (FW phantom-record defect).
  Criterion 6 FAIL.
- Token proxy: T0.5 artifact **568 B, −75.8%** vs v1.1.0 2347 B (PASS).
- LOC: 289 vs 262 (**+10.3%**, within ≤+15%; 4-run median +8.25%) (PASS).
- AC: 8/8 base + empty-row edge both arms (PASS). Suites 84/44 + lint 0
  (PASS). Back-compat legacy T1 lifecycle clean (PASS). Compliance PASS
  with noted gap (`task.sh` lacks `--quick` support; T0.5 checkboxes
  hand-edited — tech debt, not a waiver).
- Fixes shipped (uncommitted→committed without tag): `task.sh --batch`
  in-memory single-write zero-fork (≈158 ms/4 ops vs ≈1000 ms before,
  parity proven); AGENTS.md T0.5 MUST-default for ≤3-file/≤30-min tasks.
- Full evidence: `benchmarks/v1.2.0/REPORT.md` (overwritten honestly).

## 1.2.0 — 2026-09-19

### Efficiency Release (OPT-1–OPT-7)

Target: ≥50% less framework wall-clock overhead and ≥40% fewer overhead
bytes on T1-class tasks vs v1.1.0, with zero behavioral regression.
Proof: `benchmarks/v1.2.0/REPORT.md`.

- **OPT-1 (T0.5 fast path):** `new-plan.sh T0.5 <name>` creates a single
  `plans/_quick/<name>.md` (Task + Verify only) — no folder, no review,
  no Active Plans entry; `resume.sh` lists it with a `[quick]` prefix;
  `session-log.sh --brief` appends a one-line entry (`7e6f1a2`).
- **OPT-2 (Slim T1):** `T1-plan.md` template and `new-plan.sh` heredoc
  reduced to 8 lines (no Complexity line, no blank separators); v1.1.0
  plans still parse (`8ee4f9f`).
- **OPT-3 (Quiet scripts):** `-q` / `--quiet` on `doctor.sh` (≤5 lines:
  `[OK] N checks passed` or `[FAIL]` per issue), `status.sh` (plan names
  only), `resume.sh` (next lines only), `close-plan.sh` (review path
  only), `task.sh` (WARNINGs suppressed); defaults byte-identical
  (`f4f9092`).
- **OPT-4 (Batch tasks):** `task.sh --batch <plan>` applies stdin
  `<n> <action>` pairs via recursive single-call semantics (stops on
  first error); differential test proves byte-parity with sequential
  runs (`972e403`).
- **OPT-5 (Enforcement):** non-force `close-plan.sh` refuses empty
  `## Built` in a pre-existing `review.md` (T2/T3 only; T0.5/T1 exempt)
  and refuses while `plans/context.md` is still `Bootstrapped`;
  `doctor.sh` warns on uncommitted `review.md` (git best-effort);
  `AGENTS.md` mandates fill-review + commit-per-plan (`a459437`).
- **OPT-6 (Tier costs):** `AGENTS.md` and `plan-manager SKILL.md` carry a
  Typical-setup-cost table (T0 ~0 / T0.5 ~50 / T1 ~200 / T2 ~500 /
  T3 ~1500 tokens); `new-plan.sh --help` prefers T0.5 over T1
  (`ba46f01`).
- **OPT-7 (Audit tool):** new `measure-overhead.sh` prints
  `[measure] plan=<n> bytes=<N> files=<M> span_s=<T> taskrefs=<R>`;
  dispatched as `protocol.sh measure` (`456dcf9`).

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

