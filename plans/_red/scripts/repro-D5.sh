#!/usr/bin/env bash
# repro-D5.sh — D5: verify-checklist.sh cannot gate CI (exits 0 with open tasks)
set -euo pipefail
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
cp -a .agents "$W/.agents"
cp AGENTS.md "$W/AGENTS.md"
cd "$W"
bash .agents/scripts/bootstrap.sh Repro D5 >/dev/null 2>&1
bash .agents/scripts/new-plan.sh T1 open-plan >/dev/null 2>&1
echo "Running: verify-checklist.sh plans/open-plan"
bash .agents/scripts/verify-checklist.sh plans/open-plan
echo "exit:$? (BUG: exits 0 despite open tasks)"
