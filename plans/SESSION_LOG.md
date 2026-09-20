# Session Log

## 2026-09-19 04:58 UTC - Bootstrap
- Done: init via agent-protocol (Windows)
- Resume: classify first work T0-T3

## 2026-09-19 14:24 UTC - Phase 0.5.D Chicken-and-Egg Resolution
- Decided: Option A for D1 execution (manually reorder D1 plan.md Tasks before Acceptance for v1.0.0 task.sh compatibility until D1 lands).
- Resume: Execute D1 lifecycle
## 2026-09-19 14:31 UTC — Closed fix-D1-task-scoping
- Done: D1: task.sh --section scoping (30 passed -> 31 passed)

## 2026-09-19 14:36 UTC — Closed fix-D2-archive-nesting
- Done: D2: preserve T3 epic nesting in archive (33 passed -> 35 passed)

## 2026-09-19 14:39 UTC — Closed fix-D3-windows-portability
- Done: D3: docs/WINDOWS.md and Git Bash warnings in installers

## 2026-09-19 14:47 UTC — Closed fix-D4-help-flags
- Done: D4: add --help to all protocol scripts (31 passed -> 32 passed)

## 2026-09-19 14:51 UTC — Closed fix-D5-verify-strict
- Done: D5: add --strict mode to verify-checklist.sh (34 passed -> 35 passed)

## 2026-09-19 14:56 UTC — Closed fix-D6-encoding-lint
- Done: D6/D9: add lint-encoding.sh + .gitattributes guard (35 passed -> 39 passed)

## 2026-09-19 15:02 UTC — Closed fix-D7-t1-semantics
- Done: D7: clarify T1 checkbox semantics (40 passed -> 42 passed)

## 2026-09-19 15:08 UTC — Closed fix-D8-unified-update
- Done: D8: unify update path across bash + PowerShell (diff -r clean parity)

## 2026-09-19 15:10 UTC — Closed fix-D9-gitattributes-guard
- Done: D9: guard .gitattributes via lint-encoding.sh

## 2026-09-19 15:11 UTC — Closed fix-D10-plans-policy
- Done: D10: define plans/ policy (Option B, verified installer exclusions)

## 2026-09-19 15:14 UTC — Closed fix-D11-ascii-output
- Done: D11: ASCII-safe symbols in script output (42 passed -> 44 passed)

## 2026-09-19 15:19 UTC — Closed fix-D12-close-overview
- Done: D12: scan OVERVIEW.md for open tasks in close-plan.sh + archive.sh (35 passed -> 39 passed in stress)

## 2026-09-19 15:21 UTC — Closed fix-D13-promote-regression
- Done: D13: guard T1->T2 regression (39 passed -> 42 passed in stress)


## 2026-09-20 � Shipped v1.2.1 (governance release)
- Done: task.sh --quick T0.5 parity + EOL matchers (smoke 84->95); AGENTS.md code-first + edge checklist; ADR-011 metric separation; v1.2.0 superseded as defective; 8/8 gateway PASS; tag v1.2.1.
- Resume: owner disposition of defective v1.2.0 tag; prompt SESSION_LOG/--quick-use evidence harder (v1.2.1 FW arm filed no log entry).

