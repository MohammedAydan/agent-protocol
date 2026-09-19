# CLAUDE.md — Claude Code adapter

@AGENTS.md

> Imports canonical rules (v1.1.0). AGENTS.md wins on conflict.

- Prefer `.agents/scripts/` (`resume`, `new-plan`, `task`, `close-plan`).
- T1+: **fill** Goal/Acceptance/Tasks → `task start` → code → verify → `task done` → `close` + SESSION_LOG.
- Unsure → ask the human. Never invent requirements.
- Subagents: exact plan folder; one `[~]`; no `tools: []`.
- Windows hosts: run scripts under Git Bash.
- Native mirrors: `.claude/skills/`, `.claude/agents/` via sync.
