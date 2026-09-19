# Agent Protocol v1.1.0 — Certification & Benchmark Report

## Release Metadata
- **Release Version**: `v1.1.0`
- **Release Date**: 2026-09-19
- **Certifier**: Principal Framework Engineer
- **Environment**: Microsoft Windows (NT 10.0), PowerShell 5.1 / PowerShell 7+, Git Bash (MSYS2 / bash 5.2)
- **Tag:** `v1.1.0` (annotated) — the tag points to the commit that contains this line. Verify with: `test "$(git rev-parse v1.1.0^{commit})" = "$(git rev-parse HEAD)"`

---

## Hardening Scope & Item Verification (D1–D13)

| ID | Subject | Implementation / Scope | Commit | Status |
|:---|:---|:---|:---|:---:|
| **D1** | `task.sh` section scoping | Added `--section tasks\|acceptance` (`--acceptance` alias); defaults to `## Tasks` for T1 | `5569b19` | **PASSED** |
| **D2** | Archive nesting | `archive.sh` preserves nested T3 epic hierarchy under `_archive/<epic>/<subplan>` | `55a02fd` | **PASSED** |
| **D3** | Windows documentation | Created `docs/WINDOWS.md`; updated installers, README, and INSTALL with Git Bash guidance | `781fbcb, ce44986` | **PASSED** |
| **D4** | CLI help flags | All 19 protocol shell scripts support `--help` and `-h` with exit 0 | `b7eefe3` | **PASSED** |
| **D5** | Strict verification mode | `verify-checklist.sh --strict` scans for open tasks and reports file:line before exit 1 | `527f83e` | **PASSED** |
| **D6** | Encoding linter | Added `lint-encoding.sh` checking for BOM, CRLF in `.sh`, and `.gitattributes` presence | `a3e7883` | **PASSED** |
| **D7** | T1 checkbox semantics | Documented tasks vs acceptance semantics in `AGENTS.md`, `T1-plan.md`, `new-plan.sh` | `1e57299` | **PASSED** |
| **D8** | Unified update path | `bin/agent-protocol.ps1` delegates to `update-project.sh` via Git Bash; clean fallback | `733773c` | **PASSED** |
| **D9** | Gitattributes guard | Hardened `.gitattributes` (`eol=lf` on `.sh`); verified via `lint-encoding.sh` | `a3e7883` | **PASSED** |
| **D10** | Plans policy | ADR-003 Option B: tracked brain files in framework repo, volatile plan folders ignored | `aad77e1` | **PASSED** |
| **D11** | ASCII-safe output | Added `--ascii` to `doctor.sh` and `status.sh` emitting `[OK]`/`[WARN]` for legacy consoles | `e7c16a5` | **PASSED** |
| **D12** | Scan OVERVIEW.md | `close-plan.sh` and `archive.sh` scan `OVERVIEW.md` for open tasks before close/archive | `bbcb862` | **PASSED** |
| **D13** | Promote regression guard | Stress test 22 guards T1 to T2 promotion, task count retention, and comment isolation | `f90aeef` | **PASSED** |

> **Sub-fix**: while implementing D12, `task.sh` state-equality checks were hardened against false-positive matches on user-supplied text containing `[x]` or `[~]`. The check now anchors at line start using `case "$CURRENT" in "- [x]"*) ...`. This is a regression fix absorbed into commit bbcb862; it does not alter observable behavior for well-formed plan files.

---

## Verification Gates & Benchmark Results

### 1. Framework Test Suites
- **Smoke Suite (`test-scripts.sh`)**: All smoke tests pass (run `bash .agents/scripts/test-scripts.sh` for the current count; exit code 0 required).
- **Stress Suite (`test-stress.sh`)**: All stress tests pass (run `bash .agents/scripts/test-stress.sh` for the current count; exit code 0 required).
- **Encoding & Line Ending Lint (`lint-encoding.sh`)**: **Clean** (Exit code 0, zero warnings, zero errors)

### 2. Scratch Consumer Verification (8 / 8 Gates Passed)
1. `agent-protocol init` in fresh consumer: **PASS** (Exit 0)
2. `doctor.sh` and `resume.sh`: **PASS** (Exit 0)
3. T1 plan with 3 tasks + 3 acceptance checkboxes: **PASS** (All 6 checkboxes cleanly toggled via `task.sh` without index cross-talk)
4. `verify-checklist.sh --strict`: **PASS** (Flags open tasks with file + line number; exits 0 on clean plans)
5. T3 nested epic archive: **PASS** (Preserved directory hierarchy under `plans/_archive/parent-epic/child-sub`)
6. Legacy flat archive compatibility: **PASS** (`doctor.sh` reads flat archives cleanly)
7. All 19 scripts respond to `--help` / `-h`: **PASS** (100% exit 0)
8. `doctor.sh --ascii`: **PASS** (Outputs `[OK]` with zero mojibake or UTF-8 mark bytes)

### 3. Cross-Platform CLI Parity
- **Init Parity (`init-bash` vs `init-ps`)**: **100% Parity** (Identical directory and file trees)
- **Update Parity (`update-bash` vs `update-ps`)**: **100% Parity** (`diff -r` clean, exit code 0)
- **Application Isolation**: Decoy application files (`README.md`, `plans/`) remain byte-untouched during update.

---

## Commit Accounting & History
- **Commit count:** from baseline `aad77e1` to the sealed commit — run `git rev-list --count aad77e1..HEAD` for the exact number.
- Includes parity alignment commit `c7432b9`: `chore(cli): align PowerShell Install-Init with bash init` (ADR-006).
- G1-G5 documentation fixups: ce44986, 9f3646a, 89abb40, 8e01d4e, 8a45dd0, a67947f.

---

## Certification Sign-off
Agent Protocol v1.1.0 satisfies all architectural requirements, dogfood lifecycles, and verification gates. The codebase is hardened for cross-platform Windows, Linux, and macOS usage with zero backwards-incompatible regressions.
