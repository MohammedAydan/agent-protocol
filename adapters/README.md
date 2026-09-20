# Adapter & Compatibility Matrix

**Canonical rules: `AGENTS.md` (repo root, v1.1.0). Every adapter below is a thin pointer — never duplicate rules.

| Harness | Mechanism | Adapter path |
|---|---|---|
| Codex CLI, Aider, Zed, Roo Code, OpenCode, Junie, Amp, Qodo, and 25+ others | Read `AGENTS.md` natively (Linux Foundation Agentic AI Foundation convention) | none needed |
| Claude Code | `CLAUDE.md` + `.claude/skills/` `.claude/agents/` mirrors | `adapters/claude/` + `sync-adapters.sh` |
| Gemini CLI / Antigravity | `GEMINI.md` thin index | `GEMINI.md` |
| Cursor | `.cursor/rules/*.mdc` | `adapters/cursor/` |
| GitHub Copilot | `.github/copilot-instructions.md` | `adapters/copilot/` |
| Windsurf / Devin Desktop | `.windsurfrules`, `.windsurf/rules/`, `.devin/rules/` | `adapters/windsurf/` |
| Cline | `.clinerules` | `adapters/cline/` |
| Roo Code (rules variant) | `.roorules` | `adapters/roo/` |

Install all: `.agents/scripts/sync-adapters.sh` (idempotent; `--force` to overwrite).

**New harness?** If it reads AGENTS.md → zero work. If it uses a rules file → add a 5-line adapter and one `copy` line in `sync-adapters.sh`.
