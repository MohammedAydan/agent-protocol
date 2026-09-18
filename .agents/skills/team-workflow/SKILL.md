---
name: team-workflow
description: >
  Session boot, Plan→Implement→Verify→Close, anti-loop, ask-when-unsure,
  solo vs subagent. Works with any AGENTS.md-compatible agent.
compatibility: Any AGENTS.md-compatible agent
metadata:
  version: "1.0.0"
  focus: token-efficiency, ask-when-unsure, anti-loop, execution-bias
---

# Team Workflow

**Working verified code wins. Token waste fails. Guessing fails.**

## Boot

Prefer `.agents/scripts/resume.sh`. Else: context.md head → last SESSION_LOG entry → active plan → one-line resume → act.

## Ask when unsure

Any ambiguity (scope, design, naming, acceptance, irreversible ops) → **ask the human once** with options. Never invent requirements or “reasonable defaults” for non-obvious choices. Clear T0 → implement without ceremony.

## Phases

- **Plan**: lowest tier only; scripts preferred; freeze after required files
- **Implement**: one `[~]` via `task.sh`; stay in scope; related work = new `[ ]`
- **Verify**: lint + real tests; then `[x]`
- **Close**: `close-plan.sh` → update context → SESSION_LOG → optional `archive.sh`

## Anti-loop

1. No T2/T3 for T0/T1 work  
2. ≤10 new `plans/` files per session  
3. Required files exist → plan phase over  
4. 3 doc-only turns → implement or ask/report blocker  
5. No re-plan without human request  

## Delegation

Solo default. Subagent if human asks or ≥2 independent units. Parallel T3: worktree isolation when available; exclusive files; one `[~]` per plan folder.
