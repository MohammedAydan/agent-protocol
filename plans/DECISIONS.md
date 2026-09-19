# DECISIONS.md

## ADR-001 — D1 task scoping: Option B (--section flag)

- **Date:** 2026-09-19
- **Status:** Accepted
- **Context:** T1 `task.sh <dir> <n>` counts every checkbox in `plan.md`
  (Acceptance + Tasks). RED proof in plans/_red/RED.md (D1).
- **Decision:** Option B. `task.sh` gains `--section tasks|acceptance`;
  default = prefer `tasks.md`, else scope to `## Tasks` in `plan.md`;
  `--acceptance` = alias for `--section acceptance`. Precedence:
  `--acceptance` > `--section` > default. Indices are section-relative.
- **Alternatives considered:** Option A (emit empty `tasks.md` for T1) —
  rejected: changes T1 on-disk contract, blurs T1/T2 tier distinction relied
  on by `doctor.sh`, `promote.sh`, and the adapter docs; riskier for v1.0.0
  consumers.
- **Consequences:** Additive only; v1.0.0 commands keep running, indices
  become stable and documented. D7 documents the semantics.

## ADR-002 — D8 dual update path: Option A (bash-first, warned fallback)

- **Date:** 2026-09-19
- **Status:** Accepted
- **Context:** `bin/agent-protocol.ps1` `Update-Project` duplicates
  `update-project.sh`; RED proof shows init divergence (missing `adapters/`,
  BOM plans). D drift will recur on every change.
- **Decision:** Option A. `Update-Project` shells out to
  `.agents/scripts/update-project.sh` via Git Bash when available; the
  PowerShell-native copy path remains ONLY as a fallback when Bash is
  absent, printing a divergence warning. Fallback writes normalized to
  UTF-8 no-BOM + LF.
- **Alternatives considered:** Option B (shared spec + parity test) —
  rejected: two implementations still drift between test runs; Option A
  makes divergence structurally impossible on Bash-capable machines
  (identical code path, `diff -r` clean by construction).
- **Consequences:** Git Bash becomes the preferred Windows runtime for
  `update` (already required for all `.sh` scripts); Bash-less machines get
  a working but warned fallback.

## ADR-003 — D10 plans/ policy: Option B (track minimal brain)

- **Date:** 2026-09-19
- **Status:** Accepted
- **Context:** Framework repo had untracked `plans/` bootstrap residue;
  `git add -A` would commit it. RED proof in plans/_red/RED.md (D10).
- **Decision:** Option B. Track `context.md`, `SESSION_LOG.md`, `ARCH.md`,
  `TECH_STACK.md`, `DECISIONS.md`, `PATTERNS.md`, `CERT_BENCHMARK.md`,
  `_red/`; ignore all other `plans/*` (volatile plan folders, `_archive/`).
  Pre-commit normalization: UTF-8 no-BOM, LF (done 2026-09-19, verified by
  `od` + `file`).
- **Alternatives considered:** Option A (ignore all of `plans/`) —
  rejected: Phase 5 deliverables 9–12 require tracked `plans/DECISIONS.md`,
  `plans/CERT_BENCHMARK.md`, and SESSION_LOG entries in the framework repo.
- **Consequences:** Dogfood plans live (ignored) under `plans/` during work
  and archive there; only brain files are committed. Installers already
  exclude `plans/` from consumer copies (verified, no change needed).

## ADR-004 — D11 output symbols: Option B (--ascii flag)

- **Date:** 2026-09-19
- **Status:** Accepted
- **Context:** `doctor.sh`/`status.sh` emit U+2713/U+26A0 (bytes e2 9c 93 /
  e2 9a a0); PowerShell 5.1 console renders mojibake. RED proof in
  plans/_red/RED.md (D11).
- **Decision:** Option B. Add opt-in `--ascii` to `doctor.sh` and
  `status.sh`; default output stays byte-identical to v1.0.0.
  `docs/WINDOWS.md` recommends `--ascii` on PowerShell 5.1.
- **Alternatives considered:** Option A (global ASCII replacement) —
  rejected: changes default stdout bytes for every v1.0.0 consumer and
  breaks the "default behavior preserved" directive.
- **Consequences:** Zero compat risk; Windows UX fixed via documented flag.
