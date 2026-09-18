# Agent Protocol 1.0.0

**First production release.** Universal software-engineering protocol for AI coding agents.

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

## Install (new or existing project)

Works like Speckit: one command, does **not** rewrite your app code.

### Existing project (most common)

```bash
# From inside your repo
bash /path/to/agent-protocol-1.0.0/init --here

# Or with force refresh of protocol files
bash /path/to/agent-protocol-1.0.0/init --here --force --name "My App" --purpose "…"
```

### New empty folder

```bash
mkdir my-app && cd my-app
bash /path/to/agent-protocol-1.0.0/init --here --name "My App" --purpose "API service"
```

### From protocol package root

```bash
./init /path/to/your-repo --name "My App" --purpose "…"
./init /path/to/your-repo --force          # refresh protocol files only
```

### What gets added

| Path | Role |
|------|------|
| `AGENTS.md` | Rules every AI agent reads |
| `.agents/` | Scripts, skills, standards |
| `adapters/` + tool mirrors | Claude / Cursor / Copilot / … |
| `plans/` | Project brain (created if missing) |

Your source code is never modified. Safe to review in a PR.

### After install

```bash
bash .agents/scripts/resume.sh
bash .agents/scripts/protocol.sh new T1 first-feature
bash .agents/scripts/protocol.sh test    # optional smoke check
```

---

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
