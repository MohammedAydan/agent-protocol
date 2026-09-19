# Install & Update

**Repo:** https://github.com/MohammedAydan/agent-protocol

## Windows (PowerShell) — global CLI

```powershell
irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.ps1 | iex
```

Close the window, open a **new** PowerShell:

```powershell
agent-protocol version
cd D:\path\to\your-project
agent-protocol init --here --adapters none
agent-protocol update
agent-protocol upgrade
```

Requires [Git for Windows](https://git-scm.com/download/win) (bash).

### Project-only install (no global)

```powershell
irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex
```

---

## macOS / Linux / Git Bash — global CLI

```bash
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.sh | bash
export PATH="$HOME/.local/bin:$PATH"
agent-protocol version
```

## A) Global CLI (recommended)

```bash
# From GitHub
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.sh | bash

# Or from a local checkout of this package
bash install-global.sh
```

Ensure PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"   # add to ~/.bashrc or ~/.zshrc
```

### Commands

| Command | Meaning |
|---------|---------|
| `agent-protocol init --here` | Install protocol into current project |
| `agent-protocol update` | Refresh protocol **in this project** (keeps `plans/`) |
| `agent-protocol update --force` | Full refresh of protocol files in project |
| `agent-protocol upgrade` | Download latest package into **global** home |
| `agent-protocol self-update` | Same as `upgrade` |
| `agent-protocol doctor` | Audit current project |
| `agent-protocol test` | Smoke tests |
| `agent-protocol stress` | Hard edge-case tests |
| `agent-protocol version` | Versions |
| `agent-protocol help` | Help |

### Typical lifecycle

```bash
# once on your machine
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.sh | bash

# each project
cd my-app
agent-protocol init --here --adapters cursor,claude

# when protocol releases updates
agent-protocol upgrade          # update global package
cd my-app && agent-protocol update   # pull into project (plans safe)
```

## B) Windows PowerShell (project only)

```powershell
irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex
```

Interactive adapter menu. Global CLI on Windows: use **Git Bash** after `install-global.sh`.

## C) One-shot project install (no global)

```bash
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.sh \
  | bash -s -- --here --adapters none --non-interactive
```

## Safety

- Never overwrites app `README.md` / source / `.git`
- `update` never deletes `plans/`
- HTTPS-only downloads for remote install/upgrade
