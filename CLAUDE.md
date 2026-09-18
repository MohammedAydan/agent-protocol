# CLAUDE.md — Claude Code adapter

@AGENTS.md

> Imports canonical rules (v1.0.0). Keep this file thin. AGENTS.md wins on conflict.

- Prefer `.agents/scripts/` (especially `resume.sh`, `task.sh`, `new-plan.sh`).
- Unsure → ask the human (AskUserQuestion / message). Never invent requirements.
- Subagents: exact plan folder; one `[~]` per folder; no `tools: []`.
- Parallel T3: git worktree isolation when available.
- Native mirrors: `.claude/skills/`, `.claude/agents/` via `sync-adapters.sh`.
