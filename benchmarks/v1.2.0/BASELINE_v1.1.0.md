# Baseline v1.1.0 — Fresh A/B (Phase 1)

- Date (UTC): 2026-09-19, T_START both arms 1789844111 (18:55:11Z)
- Framework source: repo `D:/Downloads/agent-protocol/agent-protocol-1.0.0`, branch `perf/v1.2.0-efficiency` (code = v1.1.0, zero OPT changes)
- TASK_SPEC sha256: EC4EA6B52476693276295327632C73624D394AC72486093FD26C86C2095A482B (identical to v1.1.0 benchmark)
- Harness: OpenCode subagents, software-engineer both arms, parallel background
- Token count unavailable in harness; using bytes-written as token proxy (stated, not invented)

## Results

| Metric | Arm A (with FW v1.1.0) | Arm B (no FW) | Delta (A−B) |
|---|---|---|---|
| Wall-clock | 224 s (T_END 1789844335) | 169 s (T_END 1789844280) | +55 s (1.33×) |
| Deliverable LOC | 264 (91+85+88) | 394 (133+160+101) | −130 (B longer this trial) |
| Deliverable bytes (token proxy) | 7270 | 10486 | −3216 |
| Tests written / passing | 9 / 9 (`9 passed in 1.07s`) | 8 / 8 (`8 passed in 1.00s`) | +1 |
| Acceptance (AC1–AC6 + empty-row edge) | PASS all incl `[{"a":"","b":""}]` | PASS all incl `[{"a":"","b":""}]` | 0 |
| AC7 README examples | 6 mentions, 5 examples present | 12 mentions, 5 examples present | 0 |
| Framework artifact bytes | 2347 (plan 1163 + tasks 294 + context 796 + review 94) + SESSION_LOG 385 | 0 | +2732 |
| review.md filled | NO (94 B all-blank stub) | n/a | partial-compliance |
| plans/context.md | STALE (TBD/Bootstrapped) | n/a | partial-compliance |
| Commits | 0 (no git repo) | 0 | 0 |

## Notes

- Single trial (n=1); do not over-generalize. Both arms slower than the 180800 run (224 vs 208; 169 vs 46) — model-speed jitter dominates.
- LOC overhead INVERTED vs v1.1.0 run (+39% then, −33% now): variance, not a framework effect. The stable, repeatable overhead is wall-clock (+55 s) and artifact bytes (+2732 B), plus the 3 recurring partial-compliance items (empty review, stale context, 0 commits) — reproduced 2/2 runs.
- Both arms preserved the empty-row edge this time (B agent kept `[{"a":"","b":""}]`); correctness delta = 0 this trial.
- Comparison targets for v1.2.0 (Phase 5): overhead (A−B) +55 s → target ≤27 s; artifact bytes 2732 → target ≤1640 (−40%); review filled; ≥1 commit; context not stale.

## Raw evidence

- `_control/spawn-info.txt`, `_control/arm-A.log`, `_control/arm-B.log`
- `_control/arm-A-final.tgz` (39259 B), `_control/arm-B-final.tgz` (4589 B)
- `_control/accheck.py` (exit 0, all PASS), `_control/edge_emptyrow.py` (both preserve)
- `arm-*/csv2json.py`, `arm-*/README.md`, `arm-*/tests/test_csv2json.py`
