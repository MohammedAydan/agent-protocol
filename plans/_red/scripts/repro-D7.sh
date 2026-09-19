#!/usr/bin/env bash
# repro-D7.sh — D7: T1 checkbox semantics undocumented in AGENTS.md and templates
echo "--- AGENTS.md T1 checkbox mention ---"
grep -n 'T1 checkbox' AGENTS.md || echo "exit:$? (not found)"
echo "--- new-plan.sh --help T1 mention ---"
bash .agents/scripts/new-plan.sh --help 2>&1 || true
echo "--- .agents/templates/T1-plan.md header ---"
head -n 5 .agents/templates/T1-plan.md
