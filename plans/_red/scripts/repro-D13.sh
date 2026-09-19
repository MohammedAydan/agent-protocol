#!/usr/bin/env bash
# repro-D13.sh — D13: promote.sh regression guard for T1 -> T2
set -euo pipefail
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
cp -a .agents "$W/.agents"
cp AGENTS.md "$W/AGENTS.md"
cd "$W"
bash .agents/scripts/bootstrap.sh Repro D13 >/dev/null 2>&1
bash .agents/scripts/new-plan.sh T1 promo-baseline >/dev/null 2>&1
cat > plans/promo-baseline/plan.md <<'EOF'
# promo-baseline
**Complexity**: T1

## Goal
g

## Acceptance
- [ ] acc1

## Tasks
- [ ] task alpha
- [ ] task beta
- [ ] task gamma
EOF
bash .agents/scripts/promote.sh plans/promo-baseline
echo "promote exit:$?"
echo '--- tasks.md after promote ---'
cat plans/promo-baseline/tasks.md
