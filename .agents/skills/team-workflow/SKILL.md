---
name: team-workflow
description: >
  Session boot, Plan→Implement→Verify→Close, anti-loop, ask-when-unsure,
  mandatory task lifecycle for T1+. Any AGENTS.md-compatible agent.
compatibility: Any AGENTS.md-compatible agent
metadata:
  version: "1.0.0"
  focus: token-efficiency, ask-when-unsure, anti-loop, task-lifecycle
---

# Team Workflow

**Working verified code wins. Token waste fails. Guessing fails. Empty plans fail.**

## Boot

Prefer `resume.sh`. Else: context head → last SESSION_LOG → active plan → one-line resume → act.

**Windows:** `bash .agents/scripts/resume.sh` (Git Bash). Avoid bash operators inside PowerShell.

## Ask when unsure

Ambiguity → ask once with options. Never invent requirements.

## Phases (T1+)

1. **Plan structure** — lowest tier; `new-plan.sh`
2. **Fill plan** — Goal + Acceptance + Tasks **before code**
3. **Implement** — `task start` → code → verify → `task done` (one `[~]`)
4. **Close** — `close-plan.sh` + SESSION_LOG (+ optional archive)

T0: implement directly; optional log line.

## Anti-loop

1. No T2/T3 for T0/T1 work  
2. ≤10 new `plans/` files per session  
3. Structure exists → fill it, then implement (do not leave empty stubs)  
4. 3 doc-only turns → implement or ask/report blocker  
5. No re-plan without human request  

## Delegation

Solo default. Subagent if human asks or ≥2 independent units. Parallel T3: worktree isolation; exclusive files; one `[~]` per plan folder.
