#!/usr/bin/env bash
# repro-D1.sh — D1: task.sh plan.md section scoping bug
set -euo pipefail
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
cp -a .agents "$W/.agents"
cp AGENTS.md "$W/AGENTS.md"
cd "$W"
bash .agents/scripts/bootstrap.sh Repro D1 >/dev/null 2>&1
bash .agents/scripts/new-plan.sh T1 d1 >/dev/null 2>&1
cat > plans/d1/plan.md <<'EOF'
# d1
**Complexity**: T1

## Goal
test

## Acceptance
- [ ] a1
- [ ] a2
- [ ] a3

## Tasks
- [ ] t1
- [ ] t2
- [ ] t3
EOF

echo "Running: task.sh plans/d1 1 start"
bash .agents/scripts/task.sh plans/d1 1 start
echo "exit:$?"
echo "Result in plan.md:"
grep -E '^\- \[' plans/d1/plan.md
