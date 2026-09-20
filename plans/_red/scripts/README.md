# Repro Scripts — Pre-Fix Defect Evidence

This directory contains standalone reproduction scripts for each defect (D1–D13) documented in `plans/_red/RED.md`.

## Environment Assumptions
- **Git Bash** (e.g. Git Bash 5.2+ on Windows, `/bin/bash`)
- **PowerShell 5.1** (`powershell.exe` accessible on PATH)
- **curl.exe** (Windows built-in or Git curl.exe)
- Standard tools available on PATH: `git`, `file`, `od` or `xxd`, `diff`

## Execution
Run any script from the repository root:
```bash
bash plans/_red/scripts/repro-D<n>.sh
```

## Inventory of Scripts

| Script | Defect | Summary of What It Reproduces |
|--------|--------|-------------------------------|
| `repro-D1.sh` | D1 | `task.sh` counts checkboxes from top of `plan.md`, toggling Acceptance instead of Tasks. |
| `repro-D2.sh` | D2 | `archive.sh` flattens nested T3 epic children directly into `plans/_archive/<child>` instead of preserving epic hierarchy. |
| `repro-D3.sh` | D3 | POSIX-isms (`curl`, `head`, `which`, `&&`) failing under Windows PowerShell 5.1. |
| `repro-D4.sh` | D4 | Protocol scripts lack `--help` handling and exit non-zero on unknown flag `--help`. |
| `repro-D5.sh` | D5 | `verify-checklist.sh` lacks strict CI gating mode and exits 0 even when unresolved tasks remain. |
| `repro-D6.sh` | D6 | Absence of `lint-encoding.sh` for UTF-8 BOM, CRLF, and `.gitattributes` enforcement. |
| `repro-D7.sh` | D7 | Missing T1 checkbox scoping documentation in `AGENTS.md`, `new-plan.sh --help`, and `T1-plan.md`. |
| `repro-D8.sh` | D8 | Dual update path drift between bash CLI (`update-project.sh`) and PowerShell CLI (`agent-protocol.ps1 update`), causing BOM and formatting divergence. |
| `repro-D9.sh` | D9 | Without `.gitattributes`, a Windows `core.autocrlf=true` checkout corrupts `.sh` files with CRLF. |
| `repro-D10.sh` | D10 | Verification of `.gitignore` policy allowing tracked minimal brain files while ignoring volatile plans. |
| `repro-D11.sh` | D11 | UTF-8 symbols (`✓`, `⚠`) hardcoded in `doctor.sh` without an `--ascii` fallback flag for non-UTF-8 terminals. |
| `repro-D12.sh` | D12 | `close-plan.sh` and `archive.sh` only scan `tasks.md` and `plan.md`, failing to detect open tasks in T3 `OVERVIEW.md`. |
| `repro-D13.sh` | D13 | Regression guard verifying that `promote.sh` preserves all tasks from T1 into `tasks.md`. |
