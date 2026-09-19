# Windows Portability Guide

This guide covers running and developing with Agent Protocol on Microsoft Windows.

---

## Prerequisites

- **Windows 10 / 11** or Windows Server 2019+
- **Git for Windows** (includes **Git Bash**): [https://git-scm.com/download/win](https://git-scm.com/download/win)
  > [!IMPORTANT]
  > Git Bash is required for core lifecycle scripts (`doctor.sh`, `status.sh`, `task.sh`, `test-scripts.sh`, `test-stress.sh`).
- **PowerShell**: Built-in Windows PowerShell 5.1 or modern PowerShell 7+ (Core).
- **curl.exe**: The native executable `curl.exe` (built-in on Windows 10 build 17063+).

---

## PowerShell 5.1

Windows PowerShell 5.1 comes pre-installed on Windows. Core CLI functions (`init`, `update`, `version`, `home`, `help`) work natively via `agent-protocol.ps1`.

To install globally in PowerShell 5.1:
```powershell
irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.ps1 | iex
```

To initialize a project without adapters:
```powershell
agent-protocol init --adapters none
```

---

## PowerShell 7+ (Core)

Modern PowerShell 7 (`pwsh`) supports operators like `&&` and `||`. The PowerShell CLI `agent-protocol.ps1` runs equivalently in PowerShell 7+. When Git Bash is detected on `PATH` or standard installation locations, `agent-protocol.ps1` transparently delegates advanced commands (`doctor`, `task`, `status`, etc.) to Git Bash.

---

## Git Bash

Git Bash (`/bin/bash` or `C:\Program Files\Git\bin\bash.exe`) is the primary runtime for Agent Protocol lifecycle scripts.

Run protocol commands directly:
```bash
bash .agents/scripts/doctor.sh
bash .agents/scripts/status.sh
bash .agents/scripts/task.sh plans/<plan-dir> 1 start
```

Or invoke via PowerShell with `bash`:
```powershell
bash .agents/scripts/doctor.sh
```

---

## Common Pitfalls

### 1. `curl` Alias in PowerShell 5.1
In PowerShell 5.1, `curl` is an alias for `Invoke-WebRequest`, which does not accept curl flags like `-fsSL`.
- **Bad:** `curl -fsSL https://...`
- **Good:** Use `curl.exe -fsSL https://...` or `Invoke-RestMethod` (`irm`).

### 2. No `&&` Operator in PowerShell 5.1
In PowerShell 5.1, `&&` is not a statement separator and causes a parser error.
- **Bad:** `command1 && command2`
- **Good:** Use semicolons or sequential statements: `command1; if ($?) { command2 }`

### 3. POSIX Utilities (`head`, `which`) Missing in PowerShell
Commands like `head` and `which` are not available in PowerShell 5.1.
- Instead of `which <cmd>`, use `Get-Command <cmd>`
- Instead of `head -n 10 <file>`, use `Get-Content <file> -Head 10`

### 4. Non-UTF-8 Console Output
Standard Windows console hosts may display UTF-8 status icons (`✓`, `⚠`) as mojibake.
- Use `--ascii` flag with scripts: `bash .agents/scripts/doctor.sh --ascii`
- Or use Windows Terminal with UTF-8 fonts enabled.

---

## Recommended Workflow

1. Install **Git for Windows** to obtain Git Bash.
2. Install Agent Protocol globally via PowerShell:
   ```powershell
   irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.ps1 | iex
   ```
3. Initialize in your project:
   ```powershell
   agent-protocol init --adapters none
   ```
4. Verify your environment with doctor:
   ```powershell
   bash .agents/scripts/doctor.sh
   ```
5. Use `bash .agents/scripts/...` or `agent-protocol <cmd>` for protocol automation.
