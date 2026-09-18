#!/usr/bin/env bash
# close-plan.sh — Create review.md stub; warn on unresolved tasks.
# Usage: close-plan.sh <path-to-plan-folder>
#        close-plan.sh --force <path>   # allow close even with open tasks

set -euo pipefail

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
  shift
fi

TARGET="${1:-}"
[[ -z "$TARGET" || ! -d "$TARGET" ]] && { echo "Usage: close-plan.sh [--force] <plan-folder>"; exit 1; }

# Check unresolved tasks
unresolved=0
for f in "${TARGET}/tasks.md" "${TARGET}/plan.md"; do
  if [[ -f "$f" ]]; then
    if grep -qE '^\- \[ \]|^\- \[~\]|^\- \[!\]' "$f" 2>/dev/null; then
      unresolved=1
      echo "WARNING: unresolved [ ] / [~] / [!] tasks in $f"
      grep -nE '^\- \[ \]|^\- \[~\]|^\- \[!\]' "$f" || true
    fi
  fi
done

if [[ "$unresolved" -eq 1 && "$FORCE" -eq 0 ]]; then
  echo ""
  echo "Refusing to close with open tasks. Mark them [x]/[-] or re-run with --force."
  exit 1
fi

REVIEW="${TARGET}/review.md"
if [[ -f "$REVIEW" ]]; then
  echo "review.md already exists at ${REVIEW}"
else
  cat > "$REVIEW" <<EOT
# Review — $(basename "$TARGET")

## Built
- 

## Edge cases
- 

## Limitations
- 

## Follow-ups
- [ ] 
EOT
  echo "created ${REVIEW}"
fi

# Remove from Active Plans (closed but not yet archived still OK to drop from "active")
if [[ -f plans/context.md ]]; then
  name=$(basename "$TARGET")
  # Handle both "name" and "parent/name"
  rel="${TARGET#plans/}"
  ap=$(grep -E '^Active Plans:' plans/context.md | head -1 || true)
  if [[ -n "$ap" ]]; then
    # strip name or rel from comma list
    new_ap=$(echo "$ap" | sed "s|^Active Plans: *||" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -vx "$name" | grep -vx "$rel" | paste -sd ', ' -)
    if [[ -z "$new_ap" ]]; then
      sed -i.bak "s|^Active Plans:.*|Active Plans: none|" plans/context.md
    else
      sed -i.bak "s|^Active Plans:.*|Active Plans: ${new_ap}|" plans/context.md
    fi
    rm -f plans/context.md.bak
    echo "Active Plans updated (removed ${rel})"
  fi
fi

echo ""
echo "Finish manually (or let the agent):"
echo "  1. Ensure all tasks are [x] or [-]"
echo "  2. .agents/scripts/session-log.sh \"Closed $(basename "$TARGET")\" \"summary\""
echo "  3. Optional: .agents/scripts/archive.sh ${TARGET}"
