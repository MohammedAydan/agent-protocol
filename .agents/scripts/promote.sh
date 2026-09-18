#!/usr/bin/env bash
# promote.sh — Promote a T1 plan (plan.md only) to T2 (plan + tasks + context).
# Moves the "## Tasks" section into tasks.md, creates a context.md stub,
# and rewrites plan.md to T2 shape. Reversible manually via git.
# Usage: promote.sh <plan-folder>

set -euo pipefail
DIR="${1:-}"
[[ -z "$DIR" || ! -f "${DIR}/plan.md" ]] && { echo "Usage: promote.sh <plan-folder with plan.md>"; exit 1; }
[[ -f "${DIR}/tasks.md" ]] && { echo "Already T2 (tasks.md exists)."; exit 0; }

PLAN="${DIR}/plan.md"
NAME=$(basename "$DIR")

awk '/^## Tasks/{f=1;next} /^## /{f=0} f && NF' "$PLAN" > /tmp/_promote_tasks_$$ || true
if [[ ! -s /tmp/_promote_tasks_$$ ]]; then
  rm -f /tmp/_promote_tasks_$$
  echo "No '## Tasks' section with items found in $PLAN — nothing to promote."
  exit 1
fi

{
  echo "# Tasks — ${NAME}"
  echo ""
  cat /tmp/_promote_tasks_$$
} > "${DIR}/tasks.md"

cat > "${DIR}/context.md" <<EOT
# Context — ${NAME}

## Files to touch
- (fill during implementation)

## New dependencies
- none

## Env / config
- none

## Open questions
- none
EOT

# Rewrite plan.md: drop Tasks section, bump tier
awk '/^## Tasks/{f=1;next} /^## /{f=0} !f' "$PLAN" | \
  sed 's/^\*\*Complexity\*\*: T1/**Complexity**: T2/' > /tmp/_promote_plan_$$
mv /tmp/_promote_plan_$$ "$PLAN"
rm -f /tmp/_promote_tasks_$$

echo "Promoted ${DIR}: T1 → T2"
echo "  created: ${DIR}/tasks.md, ${DIR}/context.md"
