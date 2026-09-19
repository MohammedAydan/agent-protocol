# Agent Protocol 1.0.0

**First production release.** Universal software-engineering protocol for AI coding agents.

**Repo:** https://github.com/MohammedAydan/agent-protocol

Works with 30+ tools that read `AGENTS.md` (Linux Foundation Agentic AI Foundation convention), plus thin adapters for Claude Code, Cursor, Copilot, Windsurf/Devin Desktop, Cline, Roo, and Gemini/Antigravity.

---

## Design principles

1. Working verified code > documentation  
2. Plan cost ∝ risk & size  
3. **Ask when unsure — never guess**  
4. One `[~]` per plan folder  
5. Never invent secrets; confirm irreversible ops  
6. Token efficiency is first-class  
7. Scripts over hand-written structure  

---

## Adaptive planning (T0–T3)

| Tier | When | Files |
|------|------|-------|
| **T0** | Typo / 1-liner / pure config | none — implement |
| **T1** | ≤~3 files, clear acceptance | `plan.md` only |
| **T2** | Multi-file / new module | plan + tasks + context |
| **T3** | Multi-milestone / migration | OVERVIEW + sub-folders |

Always choose the **lowest viable tier**. Unsure → ask the human.

---

## Install

### Global CLI (best)

```bash
# macOS / Linux / Git Bash (on Windows use curl.exe; see docs/WINDOWS.md):
curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.sh | bash
export PATH="$HOME/.local/bin:$PATH"

agent-protocol init --here --adapters cursor,claude
agent-protocol update          # refresh this project (keeps plans/)
agent-protocol upgrade         # upgrade global package from GitHub
```

### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex
```

Full guide: [INSTALL.md](INSTALL.md) | Windows guide: [docs/WINDOWS.md](docs/WINDOWS.md)


## Layout

```
AGENTS.md                 ← canonical rules (all agents)
CLAUDE.md / GEMINI.md     ← thin adapters
.agents/
├── agents/software-engineer.md
├── rules/engineering-standards.md
├── skills/               ← plan-manager, team-workflow
├── scripts/              ← protocol helpers
└── templates/
adapters/                 ← Cursor, Copilot, Windsurf, Cline, Roo, Claude
plans/                    ← created by bootstrap
```

After `sync-adapters.sh`: `.claude/`, `.codex/`, `.cursor/`, `.github/`, `.windsurf/`, `.devin/`, `.clinerules`, `.roorules` as applicable.

---

## Scripts

| Command | Purpose |
|---------|---------|
| `protocol.sh` | Single dispatcher for all commands |
| `resume.sh` | Token-cheap session boot |
| `new-plan.sh` | Tier-correct plan (`--force` overwrite) |
| `task.sh` | Checkbox state machine (one `[~]`) |
| `status` / `list` / `next` | Overview |
| `close` / `archive` / `promote` | Lifecycle |
| `doctor` / `test` | Audit + smoke suite |
| `bootstrap` / `install` / `sync` | Setup |

All plain bash. No external dependencies.

---

## Version

**1.0.0** — first production release.  
Matured from internal 2.x iterations: adaptive T0–T3, task state machine, archive, Active Plans auto-update, token-optimized rules, hard ask-when-unsure, cross-tool adapters, unified smoke tests.
