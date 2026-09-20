# Agent Protocol Benchmark — v1.2.1 (2026-09-20)

Release gateway: 8 deterministic criteria (ADR-011). LLM wall-clock is
observational telemetry ONLY, never a gate. `v1.2.0` is defective and
superseded (see `benchmarks/v1.2.0/REPORT.md` audit overwrite + ADR-010
REJECTED + ADR-011).

## Metadata
- Date (UTC): 2026-09-20 (arms 13:45:58Z–~13:49:33Z).
- Framework source: branch `perf/v1.2.1-governance` (`task.sh --quick`,
  EOL-tolerant matchers, AGENTS.md code-first, 95 smoke tests).
- OS / shell: Windows (PowerShell 5.1; Git Bash 5.2.37(1));
  git 2.52.0.windows.1; py 3.14.2; pytest 9.0.3.
- Harness: OpenCode + subagent tool (background=true parallel;
  software-engineer both arms, code-reviewer blind evaluator).
- Task: CSV→JSON converter, TASK_SPEC.md sha256
  EC4EA6B52476693276295327632C73624D394AC72486093FD26C86C2095A482B
  (identical to all prior runs).
- Identity map (revealed AFTER EVAL.md committed): DELIVERABLE_1 = arm-A
  (with framework v1.2.1), DELIVERABLE_2 = arm-B (control). Roll ROLL=0.
- Token counts unavailable; bytes-written used as token proxy (stated).

## Setup
- BENCH_ROOT = `C:\Users\moham\bench\agent-protocol-v1.2.1-20260920-1645\`
  (`_control`, `arm-A`, `arm-B`, `_evaluation`).
- Arm A init from remediated tree (`init.sh --here --adapters none`,
  fix presence verified: 7 `--quick` refs, code-first rules installed).
  `git init` + seed commit in BOTH arms.
- Prompts identical except framework directive (A: AGENTS.md lifecycle,
  T0.5 MUST, `task.sh --quick` only, code-first edge checklist incl.
  blank-line/trailing-newline policy; B: same correctness bar, no
  framework). T_START both arms 1789911958 (13:45:58Z).
- NOTE (method correction): the staged `accheck.py`/`edge_emptyrow.py`
  hardcode the 180800 root, so AC1–AC6 were re-probed directly per arm
  (each arm's own tool); empty-row/trailing-newline/ragged likewise.

## Deterministic microbenchmark (Git Bash, T0.5 lifecycle)
| Operation | Cost |
|---|---|
| new-plan T0.5 | 327 ms |
| task --quick 4 ops sequential | 1581 ms (~400 ms/op startup) |
| task --quick 4 ops --batch (in-memory) | 151 ms |
| measure-overhead | 620 ms |
| doctor -q (diagnostic, non-lifecycle) | 825 ms |
| status -q | 177 ms |
| **Prescribed T0.5 ceremony (new-plan + batch + measure)** | **~1098 ms ≈ 1.1 s ≤ 2.0 s PASS** |

## Raw Results
### Arm A (with framework v1.2.1)
- Telemetry: last activity 13:49:27Z (+269 s; telemetry only).
- Tier T0.5 (`plans/_quick/csv2json.md`, Task+Verify, all [x] filled).
  Method note: boxes correctly toggled; CLI-vs-hand-edit not forensically
  provable post-hoc (agent filed no SESSION_LOG entry — observation, not
  gate; capability proven by 11 smoke tests).
- Files: csv2json.py (106 lines, 3467 B), README.md (114 lines, 2255 B),
  tests (101 lines, 2946 B). Deliverable: 321 LOC / 8668 B.
- Tests: `py -m pytest -q` → 11 passed (exit 0).
- Acceptance (direct per-arm probes): AC1 file ✓, AC2 stdin ✓, AC3 --out
  file-match ✓, AC4 indent-2 ✓, AC5 quoted/empty ✓, AC6 malformed exit 1
  + `Error:` stderr + empty stdout ✓, empty file exit 1 + `Error:` ✓;
  empty-row `[{"a":"","b":""}]` ✓; trailing-newline stdin exactly
  2 records ✓ (no phantom — code-first calibration worked); ragged
  short-pad + `field_3` ✓; README 7 `py csv2json.py` hits (5 examples) ✓.
- plans/context.md LIVE; 1 commit post-seed (`feat(csv2json)`).
- Artifact: `[measure] plan=_quick bytes=193 files=1` (−91.8% vs 2347 B).
### Arm B (control, no framework)
- Telemetry: last activity 13:47:52Z (+114 s; telemetry only).
- Files: csv2json.py (143 lines, 4836 B), README.md (127 lines, 2454 B),
  tests (125 lines, 3904 B). Deliverable: 395 LOC / 11194 B.
- Tests: 12 passed. Acceptance: identical PASS profile on every probe
  above (empty-row ✓, trailing-newline 2 records ✓, ragged `field_3` ✓).
- 0 commits post-seed (by design); no plans/.agents (verified).

## Blind Evaluation (EVAL.md verbatim totals)
- DELIVERABLE_1 (FW): R1:10 R2:10 R3:9 R4:9 R5:9 R6:10 R7:10 R8:9 R9:10
  R10:9 = 95/100. Tests 11/11. AC 8/8 (+edge PASS, +trailing PASS).
- DELIVERABLE_2 (control): R1:10 R2:10 R3:9 R4:10 R5:9 R6:9 R7:10 R8:9
  R9:8 R10:9 = 93/100. Tests 12/12. AC 8/8 (+edge PASS, +trailing PASS).
- Winner: DELIVERABLE_1 | Reason: no material behavioral difference —
  all probes identical — so leaner wins (106 vs 143 LOC).
- Unblinded: FW 95 vs control 93. Criterion 6 PASS (≥90, no regression).

## Criteria Matrix (8-gateway)
| # | Criterion | Result |
|---|-----------|--------|
| 1 | Ceremony ≤ 2.0 s | PASS (~1.1 s) |
| 2 | --quick CLI, zero hand-edits required | PASS (11 smoke tests; arm boxes toggled) |
| 3 | Artifact ≤ 1100 B (≥50% cut) | PASS (193 B, −91.8%) |
| 4 | LOC ≤ +15% | PASS (321v395 = −18.7%) |
| 5 | AC/edges 100% | PASS (8/8 + empty + trailing + ragged) |
| 6 | Blind ≥ 90, no regression | PASS (95v93) |
| 7 | Suites ≥85/≥44 + lint 0 | PASS (95/44/exit 0) |
| 8 | Back-compat | PASS (legacy T1 lifecycle: task/acceptance/strict/close) |

## Verdict
**SHIPPED v1.2.1 — 8/8 PASS.** Annotated tag `v1.2.1` on the release
commit. `v1.2.0` remains documented defective/superseded (tag
undisturbed — owner-only deletion).

## Telemetry Notes (non-gating)
- LLM last-activity: FW +269 s / control +114 s. Environment at 13:54Z:
  RAM avail 9880/20332 MB; C: free 1654 MB; CPU idle % unverifiable in
  this harness (disclosed). FW agent filed no SESSION_LOG entry and its
  --quick CLI use is not forensically provable — follow-up: prompt the
  log-entry + tool-use evidence harder (framework already provides
  `session-log.sh --brief`).
- Single trial disclosed; no "best of N" (one A/B + blind, all runs
  reported across the v1.2.x record).

## Raw Evidence Index
- `_control/`: TASK_SPEC.md, spawn-info.txt, accheck.py, mkcsv.py,
  ac-test/, bad.csv.
- `arm-A/`: csv2json.py, README.md, tests/, plans/_quick/csv2json.md,
  plans/context.md, git log (seed + feat).
- `arm-B/`: csv2json.py, README.md, tests/ (no framework traces).
- `_evaluation/`: DELIVERABLE_1/2 (scrubbed 4-file), EVAL.md,
  MAP.sealed (`1=arm-A`).
