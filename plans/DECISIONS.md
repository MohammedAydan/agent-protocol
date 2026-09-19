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

## ADR-006 — PowerShell Install-Init alignment with init.sh

- **Date:** 2026-09-19
- **Status:** Accepted (retroactive documentation)
- **Context:** c7432b9 was added during Phase 4 verification after
  verify-parity.sh exposed divergent stub content and BOM output
  between bash init.sh and PowerShell Install-Init. The commit was
  scoped as a parity fix but was NOT in the original D1–D13 backlog.
- **Decision:** Keep c7432b9 as an additive fix; document it here as
  formally extending D8's scope. It does not change any v1.0.0
  behavior — it aligns PowerShell output with bash output that
  v1.0.0 users already expected.
- **Alternatives considered:** Revert and re-issue as separate D14 — rejected
  because it ships the same fix that D8's parity gate requires.
- **Consequences:** D8 now covers both update path and init path.

## ADR-007 — Tier-cost table and T0.5 fast path (OPT-1, OPT-6)

- **Date:** 2026-09-19
- **Status:** Accepted
- **Context:** v1.1.0 A/B showed +162 s wall-clock on a T1 task; part of
  the cost is fixed planning ceremony (folder + 3 files + review stub +
  log entry) regardless of task size. Token counts are unavailable in
  most harnesses, so costs are stated as rough token proxies.
- **Decision:** Add tier T0.5 (`plans/_quick/<name>.md`, Task + Verify
  only, no folder/review/Active Plans/close ceremony) and publish a
  Typical-setup-cost table (T0 ~0 / T0.5 ~50 / T1 ~200 / T2 ~500 /
  T3 ~1500 tokens) in `AGENTS.md` and the plan-manager skill.
- **Alternatives considered:** Shrinking T1 only (done as OPT-2, kept) —
  insufficient alone: T1 still costs a folder + close + log. Making
  costs machine-enforced budgets — rejected: no reliable token meter in
  the harness; numbers are guidance, re-calibrated per benchmark.
- **Consequences:** Agents should pick T0.5 for ≤3-file single-decision
  work; benchmark target is T0.5 uptake ≥80% on CSV-class tasks.

## ADR-008 — Batch task operations via recursive single calls (OPT-4)

- **Date:** 2026-09-19
- **Status:** Accepted
- **Context:** v1.1.0 needs 2N `task.sh` invocations for N checkboxes
  (start + done each). Agent round-trips dominate the overhead.
- **Decision:** `task.sh --batch` reads `<n> <action>` pairs from stdin
  and re-invokes itself per pair (same flags forwarded), stopping on
  the first error. Recursion — not an in-process loop — so the one-`[~]`
  invariant and all error paths are byte-identical to sequential runs
  (proven by differential test).
- **Alternatives considered:** In-process loop over the state machine —
  rejected: duplicates transition logic, risks parity drift on every
  future `task.sh` change.
- **Consequences:** One agent round-trip per plan; N cheap local
  subprocess spawns internally (unmetered, sub-second).

## ADR-009 — Close enforcement with tier exemptions (OPT-5)

- **Date:** 2026-09-19
- **Status:** Accepted
- **Context:** v1.1.0 A/B arms shipped empty `review.md`, stale
  `plans/context.md`, and zero commits in 2/2 runs — the framework asked
  but never verified.
- **Decision:** Non-force `close-plan.sh` refuses (a) a pre-existing
  `review.md` with an empty `## Built` section on T2/T3 plans, and
  (b) any T1+ folder close while `plans/context.md` is still
  `Bootstrapped`. T0.5/T1 are exempt from the review gate (one plan.md
  line suffices). `--force` bypasses both. `doctor.sh` adds a
  best-effort git warning for uncommitted `review.md`.
- **Alternatives considered:** Enforcing review content on T1 — rejected:
  would erase the T0.5/T1 lightness the release is buying. Blocking
  `--force` entirely — rejected: recovery flows need an escape hatch.
- **Consequences:** First-close still creates an empty stub (agent must
  fill it per `AGENTS.md`); re-close and dirty-context closes are
  refused with fix instructions. Existing suites set context status
  before non-force closes.

## ADR-010 — v1.2.0 wall-clock variance (criterion 1 disposition)

- **Date:** 2026-09-19
- **Status:** Accepted (release owner signed 2026-09-19; tag v1.2.0 proceeds)
- **Context:** Phase 5 criterion 1 requires FW overhead (A−B) ≤27 s.
  Measured: +397 s (1743 vs 1346). But the no-framework arm alone
  measured 46 s, 169 s, and 1346 s across three identical-spec runs —
  run-to-run jitter (model/harness latency; both v1.2.0 arms exceeded
  the 20-min budget) exceeds any framework-attributable cost by 10×.
- **Decision (proposed):** Record criterion 1 as MISSED-on-seconds with
  documented jitter; ship-relevant signals are the overhead ratio
  (1.29×, best of three runs), artifact bytes (−52%), LOC overhead
  (+6.2%, within target), and 3/3 compliance fixes.
- **Alternatives considered:** (a) Re-run A/B until seconds pass —
  expensive, same jitter risk, single-trial statistics stay weak either
  way. (b) Hold v1.2.0 untagged — safe default if the owner wants a
  tighter timing claim.
- **Consequences:** Tag `v1.2.0` requires explicit owner sign-off on
  this ADR.
