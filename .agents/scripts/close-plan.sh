#!/usr/bin/env bash
# close-plan.sh — Create review.md stub; warn on unresolved tasks.
# Usage: close-plan.sh <path-to-plan-folder>
#        close-plan.sh --force <path>   # allow close even with open tasks
#        close-plan.sh [-q|--quiet] <path>  # quiet: print only the review.md path

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,6p' "$0"
  exit 0
fi

FORCE=0
QUIET=0
while [[ "${1:-}" == "--force" || "${1:-}" == "-q" || "${1:-}" == "--quiet" ]]; do
  case "$1" in
    --force) FORCE=1 ;;
    -q|--quiet) QUIET=1 ;;
  esac
  shift
done

TARGET="${1:-}"
[[ -z "$TARGET" || ! -d "$TARGET" ]] && { echo "Usage: close-plan.sh [--force] <plan-folder>"; exit 1; }

# Check unresolved tasks
unresolved=0
for f in "${TARGET}/tasks.md" "${TARGET}/plan.md" "${TARGET}/OVERVIEW.md"; do
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

# OPT-5 enforcement (skipped with --force):
#  - T2/T3 only: pre-existing review.md with an empty '## Built' section.
#    (T0.5/T1 exempt: a single line in plan.md is sufficient.)
#  - Any T1+ folder close while plans/context.md is still Bootstrapped.
if [[ "$FORCE" -eq 0 ]]; then
  if [[ -f "${TARGET}/tasks.md" || -f "${TARGET}/OVERVIEW.md" || -f "${TARGET}/context.md" ]]; then
    if [[ -f "${TARGET}/review.md" ]]; then
      built_body=$(awk '/^## Built/{f=1;next} /^## /{f=0} f' "${TARGET}/review.md" | sed '/^$/d' | sed 's/^[- ]*//' | grep -v '^$' || true)
      if [[ -z "$built_body" ]]; then
        echo "REFUSED: ${TARGET}/review.md has an empty '## Built' section (T2/T3 require a filled review)."
        echo "  Fix: fill in what was built, then re-run close-plan.sh ${TARGET}"
        echo "  Or: close-plan.sh --force ${TARGET} (not recommended)"
        exit 1
      fi
    fi
  fi
  if [[ -f plans/context.md ]] && grep -q '^Current Status: Bootstrapped' plans/context.md; then
    echo "REFUSED: plans/context.md still has 'Current Status: Bootstrapped'."
    echo "  Fix: update Current Status (e.g. 'Current Status: Active: <plan> — <what>'), then re-run close-plan.sh ${TARGET}"
    echo "  Or: close-plan.sh --force ${TARGET} (not recommended)"
    exit 1
  fi
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

# Remove from Active Plans — safe under pipefail (last plan → "none")
_remove_active_plan() {
  local target="$1"
  [[ -f plans/context.md ]] || return 0
  local name rel ap list item keep new_ap
  name=$(basename "$target")
  rel="${target#plans/}"
  ap=$(grep -E '^Active Plans:' plans/context.md | head -1 || true)
  [[ -z "$ap" ]] && return 0
  list="${ap#Active Plans:}"
  list="${list#"${list%%[![:space:]]*}"}"  # trim leading space
  new_ap=""
  # shellcheck disable=SC2086
  IFS=',' read -ra parts <<< "$list"
  for item in "${parts[@]}"; do
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"
    [[ -z "$item" ]] && continue
    [[ "$item" == "$name" || "$item" == "$rel" ]] && continue
    if [[ -z "$new_ap" ]]; then
      new_ap="$item"
    else
      new_ap="${new_ap}, ${item}"
    fi
  done
  if [[ -z "$new_ap" ]]; then
    sed -i.bak "s|^Active Plans:.*|Active Plans: none|" plans/context.md
  else
    sed -i.bak "s|^Active Plans:.*|Active Plans: ${new_ap}|" plans/context.md
  fi
  rm -f plans/context.md.bak
  [[ "${QUIET:-0}" -eq 0 ]] && echo "Active Plans updated (removed ${rel})"
}
_remove_active_plan "$TARGET"

if [[ "$QUIET" -eq 1 ]]; then exit 0; fi
echo ""
echo "Finish manually (or let the agent):"
echo "  1. Ensure all tasks are [x] or [-]"
echo "  2. .agents/scripts/session-log.sh \"Closed $(basename "$TARGET")\" \"summary\""
echo "  3. Optional: .agents/scripts/archive.sh ${TARGET}"
