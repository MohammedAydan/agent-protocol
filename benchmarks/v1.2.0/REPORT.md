# Agent Protocol Efficacy Benchmark — v1.2.0 (FORENSIC AUDIT OVERWRITE, 2026-09-20)

> This file OVERWRITES the prior v1.2.0 report. The prior report's
> "1.29x best ratio" framing was selection bias ("best of three") and its
> absolute-second MISS was waived via ADR-010 without evidenced owner
> consent. ADR-010 is REJECTED (see `plans/DECISIONS.md`). The `v1.2.0`
> tag stands as DEFECTIVE pending owner disposition. No new tag was
> created: the 9-criterion gateway FAILED (verdict BLOCKED).

## Metadata
- Audit date (UTC): 2026-09-19/20. Fresh trial: 21:04–21:14 UTC.
- Framework version tested (fresh trial): working dir with audit fixes —
  `task.sh` in-memory `--batch` (single write, zero forks/item) + AGENTS.md
  T0.5 MUST-default; installed into the FW arm via `init.sh --here
  --adapters none --non-interactive`. Historical runs used the code noted
  per row below.
- OS / shell: Windows (PowerShell 5.1 build 26100; Git Bash 5.2.37(1));
  git 2.52.0.windows.1; py 3.14.2; pytest 9.0.3.
- Harness: OpenCode + subagent tool (background=true parallel;
  software-engineer both arms, code-reviewer blind evaluator).
- Task: same CSV→JSON converter, all runs. TASK_SPEC.md sha256
  EC4EA6B52476693276295327632C73624D394AC72486093FD26C86C2095A482B
  (verified identical across all four runs, including the audit root
  `C:\Users\moham\bench\agent-protocol-audit-20260919-2100\`).
- Identity map, audit trial (revealed AFTER EVAL.md committed):
  DELIVERABLE_1 = trial1-arm-A (with framework, fixed),
  DELIVERABLE_2 = trial1-arm-B (without framework). Roll ROLL=0.
- Repeats: 4 runs total disclosed (3 historical + 1 fresh). NO
  cherry-picking: every run is reported, evaluation uses the MEDIAN.
  Trials 2–3 of the audit plan were NOT executed: criterion 2 is a
  monotonic zero-breach gate and Trial 1 already breached it twice, so
  the gateway outcome (BLOCKED) is determined; further LLM runs cannot
  un-fail it. This limitation is stated, not waived.
- Token counts unavailable in harness; bytes-written used as token proxy
  (stated, not measured tokens).

## Setup (audit trial)
- BENCH_ROOT = `C:\Users\moham\bench\agent-protocol-audit-20260919-2100\`.
  `_control` (TASK_SPEC.md, spawn-info.txt, arm-A/B.log, accheck.py,
  edge_emptyrow.py, ac-test/, arm-A/B-final.tgz), `trial1-arm-A/`,
  `trial1-arm-B/`, `_evaluation/` (DELIVERABLE_1/2 scrubbed, EVAL.md,
  MAP.sealed).
- Arm A init from the FIXED source (`init.sh --here --adapters none
  --non-interactive`, exit 0; fix presence verified:
  `task.sh` contains in-memory batch, AGENTS.md contains T0.5 MUST).
  `git init` + seed commit in BOTH arms (commits testable).
- Prompts identical except framework directive + working directory
  (A: follow AGENTS.md lifecycle, lowest viable tier with T0.5 MUST,
  --quiet/--batch, live context, commit after close; B: no framework,
  solve directly). T_START both arms 1789851871 (21:04:31Z).
- Idle-state check: CPU <10% NOT verifiable in this environment
  (earlier reading 38%; CIM query returned empty at launch); RAM free
  ~9.9GB (>2GB OK); C: free 1.6GB (thin but above floor), D: free
  ~60GB. Non-idle CPU is disclosed as a validity threat, not hidden.
- Sanity ceiling 180s enforced post-hoc (subagents cannot be polled or
  mid-run killed — harness limitation, disclosed).

## Forensic RCA (why the previous benchmark drifted and stalled)
| # | Finding | Evidence |
|---|---------|----------|
| 1 | 1346s No-FW outlier was a model/harness stall, not framework cost | No-FW arm contains ZERO framework files; both 194059 arms blew the 20-min budget 19:41–20:10 UTC; arm logs are 4-line summaries with no per-command timeline (`grep -iE "error\|retry\|timeout\|backoff\|exception"` has nothing to bite on — missing instrumentation is itself a harness failure) |
| 2 | +397s "overhead" is LLM variance, not framework work | Attributable script cost microbenchmarked at ~1–2s total (new-plan T0.5 212ms; batch 4 ops 158ms single-write vs ~1000ms recursive before; measure 364ms; doctor -q ~750ms; status -q 177ms). 397s is ~200–400x the entire framework ceremony |
| 3 | 1.29x ratio was denominator corruption | Both arms stall-inflated (1743/1346) so the ratio shrinks toward 1 while absolute ΔT explodes; ratios are informational only |
| 4 | True script bottleneck found and fixed | `task.sh --batch` re-invoked `bash "$0"` per item (N Windows fork/execs); rewritten in-memory: resolve-once, array transitions, single write, zero forks/item (function-local resolution, no command substitution); differential parity proven by suite ("batch equals sequential") |
| 5 | Trial 1 corroborates: No-FW arm breached 180s ALONE (197s) | Zero framework code in that arm — the ceiling as applied to LLM authoring time measures harness latency, not framework cost, and is unpassable by engineering |
| 6 | Blind-score distortion in v1.2.0 report | +10 margin came from control 86→83 (-3) with FW 94→93 (-1); victory partly from control-arm drop, disclosed |

## Raw Results — audit Trial 1 (fixed code)
### Arm A (with framework, fixed)
- Duration: 614 s (T_END 1789852485). Self-report: 8 passed, T0.5, 2 commits. CEILING: 614 > 180 CONTAMINATED.
- Tier: T0.5 (`plans/_quick/csv2json.md`, all boxes [x], Task+Verify only).
  NOTE: agent hand-edited T0.5 checkboxes — `task.sh` supports only
  folder plans, not `_quick` single files. Framework gap filed as tech
  debt (no `--quick` mode); the agent correctly avoided multi-script
  chains per the T0.5 MUST-default.
- Files: csv2json.py (86 lines, 2730 B), README.md (111 lines, 1792 B),
  tests/test_csv2json.py (92 lines, 2900 B). Deliverable: 289 LOC / 7422 B.
- Tests: `py -m pytest -q` -> 8 passed (exit 0, re-verified by orchestrator).
- Acceptance: AC1–AC6 all PASS (re-run); empty-row edge PASS
  (`[{"a":"","b":""}]`); README covers all AC7 examples + field_N choice.
- plans/context.md LIVE, SESSION_LOG entry present, Active Plans none.
- Commits post-seed: 2 (`feat(csv2json)`, `chore(tests): untrack pycache`).
  Frozen: `_control/arm-A-final.tgz` (38515 B).
- Framework artifact: `[measure] plan=_quick bytes=568 files=1`
  (-75.8% vs v1.1.0 2347 B baseline).
### Arm B (without framework)
- Duration: 197 s (T_END 1789852068). Self-report: 8 passed.
  CEILING: 197 > 180 CONTAMINATED.
- Files: csv2json.py (101 lines, 3320 B), README.md (73 lines, 2248 B),
  tests (88 lines, 2829 B). Deliverable: 262 LOC / 8397 B.
- Tests: 8 passed (re-verified). Acceptance: AC1–AC6 PASS; empty-row edge
  PASS (`[{"a":"","b":""}]` — no correctness delta this trial).
- Commits post-seed: 0. No plans/, no .agents/ (verified clean).
  Frozen: `_control/arm-B-final.tgz` (4102 B).

## Blind Evaluation — audit Trial 1 (EVAL.md verbatim totals)
- DELIVERABLE_1 (FW, fixed): R1:9 R2:8 R3:8 R4:9 R5:9 R6:10 R7:9 R8:8 R9:9 R10:9 = 88/100. Tests 8/8. Acceptance 8/8 (+edge PASS).
- DELIVERABLE_2 (NoFW): R1:10 R2:10 R3:9 R4:9 R5:9 R6:10 R7:10 R8:9 R9:8 R10:9 = 93/100. Tests 8/8. Acceptance 8/8 (+edge PASS).
- Winner: DELIVERABLE_2 (control) | Reason: D2 skips blank/trailing-newline
  lines so piped stdin `a,b\n1,2\n3,4\n\n` yields 2 records while D1 emits
  a phantom third `{"a":"","b":""}` record.
- Differential: the control arm won outright on a genuine behavioral edge
  (trailing-newline stdin handling). The FW arm carries that defect. The
  outcome was driven by CONTROL-arm capability, not framework capability.
  Criterion 6 FAILS (FW 88 < 92 and not strictly higher).

## Multi-Run Variance Table (ALL runs, no cherry-picking)
| Run | Code | T_FW (s) | T_NoFW (s) | ΔT = FW-NoFW (s) | Ratio (info) | LOC FWvNoFW | Blind FWvNoFW |
|---|---|---|---|---|---|---|---|
| 180800 (v1.0.0) | pre-OPT | 208 | 46 | +162 | 4.52x | 239v172 (+39%) | 94v86 (+8) |
| 185455 (v1.1.0 fresh) | pre-OPT | 224 | 169 | +55 | 1.33x | 264v394 (-33%) | n/a |
| 194059 (v1.2.0) | OPT-1..7 | 1743 | 1346 | +397 | 1.29x | 359v338 (+6.2%) | 93v83 (+10) |
| audit-T1 (fixed) | audit fix | 614 | 197 | +417 | 3.12x | 289v262 (+10.3%) | 88v93 (-5) |
| MEDIAN (all 4) | — | 419.0 | 183.0 | +279.5 | — | +8.25% | — |

- Valid runs under the 180s ceiling (BOTH arms ≤180s): NONE (FW arms:
  208, 224, 1743, 614 — all breach; NoFW arms pass only in 180800/185455
  but the pair is invalid). Median of valid runs is UNDEFINED.
- FW blind scores trend DOWN across runs (94 → 93 → 88); the latest FW
  arm lost outright. No framework-driven quality victory is sustained.

## Script microbenchmark (deterministic, attributable — Git Bash)
| Operation | Cost |
|---|---|
| new-plan T0.5 | 212 ms |
| task --batch 4 ops (fixed, single write) | 158 ms (was ~1000 ms recursive) |
| measure-overhead | 364 ms |
| doctor -q | ~750 ms |
| status -q | 177 ms |
| Total ceremony T0.5 / T1 | ~0.2–1 s / ~1.5 s |

True framework script overhead is ~1–2 s. Every measured LLM-time ΔT
(+55 to +417 s) is 30–250x larger. Wall-clock LLM time cannot be moved
by script optimization; the ≤80 s LLM-overhead target is a category
error as a framework engineering criterion.

## Criteria Matrix (9-gateway)
| # | Criterion | Result |
|---|-----------|--------|
| 1 | Median absolute overhead ≤ 80 s | FAIL (median +279.5 s; zero valid runs) |
| 2 | Zero runs > 180 s ceiling | FAIL (audit T1: 614 + 197; history: 208, 224, 1743) |
| 3 | Artifact bytes ≥ 40% below v1.1.0 baseline | PASS (-75.8%: 568 vs 2347 B) |
| 4 | LOC overhead ≤ +15% | PASS (+10.3% this trial; 4-run median +8.25%) |
| 5 | AC 100% base + empty-row edge | PASS (both arms 8/8 + edge PASS) |
| 6 | Blind FW ≥ 92 and strictly > control | FAIL (88 vs 93 — control won) |
| 7 | Compliance (no empty review, context live, clean commits) | PASS w/ noted gap (T0.5 hand-edit forced by missing task.sh --quick support; T0.5 exempt from review; context live; 2 conventional commits) |
| 8 | Suites: ≥84 smoke, ≥44 stress, lint-encoding 0 | PASS (84 / 44 / exit 0) |
| 9 | Backward compat (v1.1.0 plans + CLI unmodified) | PASS (legacy-format T1 full lifecycle verified: task/acceptance/strict/close clean) |

## Verdict
**BLOCKED — 6/9 PASS, 3/9 FAIL (criteria 1, 2, 6). DO NOT TAG.**
No `v1.2.1` (or any) tag was created. The defective `v1.2.0` tag is left
untouched pending owner disposition (deleting published tags rewrites
shared history — owner decision only).

## Follow-ups (tech debt, not waivers)
- `task.sh --quick` support for `plans/_quick/*.md` (eliminate T0.5 hand-edits).
- FW csv2json trailing-newline defect class (phantom `{"a":"","b":""}` on
  blank stdin lines) — the benchmark product, not the framework, but the
  pattern (blank-line policy) belongs in engineering-standards examples.
- Benchmark methodology: LLM authoring time is not a framework metric;
  future benchmarks should gate on deterministic script ceremony cost
  (~seconds, currently ~1.5 s) plus quality blind scores, with LLM-time
  reported as variance context only.
- Trials 2–3 not executed (determined BLOCKED); any future release attempt
  needs 3 fresh valid (≤180 s) trials + FW blind win before tagging.

## Raw Evidence Index (audit root)
- `_control/`: TASK_SPEC.md (sha EC4EA6B5…), spawn-info.txt (T_START/END,
  ceiling checks), arm-A/B.log, accheck.py, edge_emptyrow.py (NOTE: the
  staged edge script hardcodes the 180800 root — Trial 1 edge was
  re-probed directly per arm, both PASS), mkcsv.py, ac-test/,
  arm-A/B-final.tgz.
- `trial1-arm-A/`: csv2json.py, README.md, tests/, plans/_quick/csv2json.md,
  plans/context.md, plans/SESSION_LOG.md, git log (seed + 2).
- `trial1-arm-B/`: csv2json.py, README.md, tests/ (no plans/.agents).
- `_evaluation/`: DELIVERABLE_1/2 (scrubbed 4-file), EVAL.md (verbatim +
  unblinded crosswalk), MAP.sealed (`1=with-framework`).
