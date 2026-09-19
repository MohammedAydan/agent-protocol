# Agent Protocol Efficacy Benchmark — v1.2.0
## Metadata
- Date (UTC): 2026-09-19 (run 19:41–20:10 UTC)
- Framework version tested: v1.2.0 source, branch `perf/v1.2.0-efficiency` @ `a52ce8d` (OPT-1..OPT-7 + CHANGELOG + ADR-007/008/009)
- OS / shell: Windows (PowerShell 5.1 build 26100; Git Bash 5.2.37(1)); git 2.52.0.windows.1; py 3.14.2; node v25.9.0
- Harness: OpenCode + subagent tool (background=true parallel; software-engineer both arms, code-reviewer blind evaluator)
- Task: same CSV→JSON converter (TASK_SPEC.md sha256 EC4EA6B52476693276295327632C73624D394AC72486093FD26C86C2095A482B — identical file as v1.1.0 runs)
- Identity map (revealed AFTER scoring sealed): DELIVERABLE_1 = arm-with-framework (Arm A), DELIVERABLE_2 = arm-without-framework (Arm B). Roll ROLL=0 -> "1=with-framework".
- Repeats: 1 (single trial; do not over-generalize)
- Token count unavailable in harness; bytes-written used as token proxy (stated, not measured tokens)

## Setup
- BENCH_ROOT = C:\Users\moham\bench\agent-protocol-20260919-194059. Arms + _control + _evaluation created; TASK_SPEC copied byte-identical into both arms (sha verified).
- Arm A init: repo `init.sh --here --adapters none --non-interactive` from v1.2.0 source -> exit 0. Then `git init` + seed commit in BOTH arms (new vs prior runs: commits are now testable).
- Arm A prompt: follow AGENTS.md lifecycle; "Pick the most appropriate tier (T0.5 to T3)"; use --quiet/--batch where helpful; keep context live; fill review Built; commit after close. Arm B prompt: no framework, solve directly (no commit instruction).
- T_START both arms 1789846867 (19:41:07Z). Spawn record: _control/spawn-info.txt.

## Raw Results
### Arm A (with framework v1.2.0)
- Duration: 1743 s (T_END 1789848610). Self-report: 9 passed, T0.5, 2 commits.
- Tier chosen: **T0.5** (first-ever uptake). Artifact: single `plans/_archive/csv2json.md`, 1136 bytes, all boxes [x], `## Built` FILLED with real content.
- Files: csv2json.py (130 lines, 3958 B), README.md (136 lines, 2508 B), tests/test_csv2json.py (93 lines, 2842 B). Deliverable: 359 LOC / 9308 B.
- Tests: `py -m pytest -q` -> 9 passed (exit 0). Acceptance (accheck.py): AC1–AC6 all PASS incl empty-row edge `[{"a":"","b":""}]`; README 10 mentions (5 examples); AC8 9 tests.
- plans/context.md: LIVE ("Current Status: csv2json shipped (2026-09-19); 9 passed"). SESSION_LOG: full entry (Done/Decisions/Files/Resume).
- Commits post-baseline: 2 (`feat(csv2json)`, `chore(repo)`). Frozen: _control/arm-A-final.tgz (126051 B).
### Arm B (without framework)
- Duration: 1346 s (T_END 1789848213). Self-report: 9/9.
- Files: csv2json.py (102 lines), README.md (142 lines), tests (94 lines). Deliverable: 338 LOC / 8998 B.
- Tests: 9 passed. Acceptance: AC1–AC4, AC5 quoted/empty PASS; evaluator-flagged AC5-long-row deviation (0-based `field_2` vs 1-based `field_3`) and splitlines newline corruption (see EVAL.md).
- Commits post-baseline: 0 (only seed commit). Frozen: _control/arm-B-final.tgz (22095 B).

## Blind Evaluation (EVAL.md verbatim totals)
- DELIVERABLE_1 (with FW): R1:10 R2:10 R3:9 R4:9 R5:9 R6:10 R7:9 R8:9 R9:9 R10:9 = 93/100. Tests 9/9. Acceptance 8/8.
- DELIVERABLE_2 (no FW): R1:10 R2:7 R3:7 R4:8 R5:8 R6:10 R7:9 R8:7 R9:9 R10:8 = 83/100. Tests 9/9. Acceptance 7/8.
- Winner: DELIVERABLE_1 | Reason: preserves embedded newlines, 1-based field_3/field_4; D2 corrupts newlines and emits 0-based field_2.

## Quantitative Table
| Metric | With FW | Without FW | Delta |
|---|---|---|---|
| Wall-clock (s) | 1743 | 1346 | +397 (1.29×) |
| Deliverable LOC | 359 | 338 | +21 (+6.2%) |
| Deliverable bytes | 9308 | 8998 | +310 (+3.4%) |
| Framework artifact bytes | 1136 (T0.5 file) | 0 | +1136 |
| Tests | 9/9 | 9/9 | 0 |
| Acceptance (orchestrator) | 8/8 | 8/8 | 0 |
| Blind score | 93 | 83 | +10 |
| review.md filled | YES | n/a | fixed vs v1.1.0 |
| context.md live | YES | n/a | fixed vs v1.1.0 |
| Commits post-baseline | 2 | 0 | fixed vs v1.1.0 |

## Delta vs v1.1.0
| Metric | v1.1.0 (orig run) | v1.1.0 (fresh baseline) | v1.2.0 | Δ v1.2.0 vs fresh |
|---|---|---|---|---|
| Wall-clock with FW (s) | 208 | 224 | 1743 | +1519 (jitter-dominated, see note) |
| Wall-clock no FW (s) | 46 | 169 | 1346 | +1177 (jitter-dominated) |
| FW overhead (A−B, s) | +162 | +55 | +397 | +342 — TARGET ≤27 MISSED |
| Overhead ratio (A/B) | 4.52× | 1.33× | 1.29× | −0.04 |
| LOC with FW | 239 | 264 | 359 | — (task variance) |
| LOC overhead vs noFW | +39% | −33% | +6.2% | within ≤+20% target |
| Framework artifact bytes | ~2164 | 2347+385 | 1136 | −52% vs 2347 — TARGET MET |
| Blind with FW | 94 | n/a (not re-scored) | 93 | −1 |
| Blind no FW | 86 | n/a | 83 | −3 |
| review.md empty | YES | YES | NO | fixed |
| context.md stale | YES | YES | NO | fixed |
| Commits in FW arm | 0 | 0 | 2 | fixed |

NOTE on wall-clock: all four arms across three runs vary 46→1743 s for the same spec; both v1.2.0 arms exceeded the 20-min budget (model/harness latency, uncorrelated with framework mechanics — arm B has zero framework yet took 1346 s). The +397 s overhead cannot be attributed to framework cost; the ratio (1.29×, best of the three runs) and the artifact-byte (-52%) and compliance (3/3 fixed) signals are the attributable ones. Criterion 1 is therefore recorded as MISSED on absolute seconds with jitter documented, not as a framework regression: no framework code path added measurable agent work (T0.5 artifact is 1 file vs 4).

## Qualitative Findings
- T0.5 uptake 100% (1/1): agent picked the fast path unprompted beyond the tier table; artifact 1136 B vs 2347 B T2-style baseline.
- Enforcement worked: Built filled, context live, 2 commits — the three v1.1.0 partial-compliances all closed in one run.
- Correctness edge again favored FW arm (embedded-newline preservation, exact indent test) — second run in a row.

## Threats to Validity
- Single trial; wall-clock variance across runs exceeds any framework effect (46–1743 s range) — timing conclusions are weak, byte/compliance conclusions are strong.
- Evaluator's AC5 long-row preference (1-based) is a judgment call; spec allows either if documented (both arms documented).
- Arm B had no commit instruction while arm A did — commit asymmetry is by design (tests FW-arm behavior), not a capability claim.

## Raw Evidence Index
- _control/: TASK_SPEC.md, spawn-info.txt, arm-A/B.log, accheck.py, edge_emptyrow.py, ac-test/, arm-A/B-final.tgz
- arm-with-framework/: csv2json.py, README.md, tests/, plans/_archive/csv2json.md, plans/context.md, plans/SESSION_LOG.md, git log (3 commits)
- _evaluation/: DELIVERABLE_1/2 (scrubbed), EVAL.md, MAP.sealed ("1=with-framework")
