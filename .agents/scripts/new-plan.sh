#!/usr/bin/env bash
# new-plan.sh — Create tier-correct plan folder + minimal templates.
# Usage:
#   new-plan.sh T0 <name>
#   new-plan.sh T0.5 <name>             # fast path: single file plans/_quick/<name>.md
#   new-plan.sh T1 <name>
#   new-plan.sh T2 <name>
#   new-plan.sh T3 <name>
#   new-plan.sh T1|T2 <sub-name> <parent-epic>
#   new-plan.sh --force T0.5|T1|T2 <name>  # overwrite existing
#   If task fits T0.5 (<=3 files, one decision, <=30 min), prefer it over T1.

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,12p' "$0"
  echo "T1 rule: task.sh defaults to '## Tasks'. Use --acceptance for '## Acceptance'. See AGENTS.md."
  exit 0
fi

[[ ! -f plans/context.md ]] && echo "NOTE: plans/ not bootstrapped — run bootstrap.sh first (continuing anyway)."

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
  shift
fi

TIER="${1:-}"
NAME="${2:-}"
PARENT="${3:-}"

usage() { echo "Usage: new-plan.sh [--force] <T0|T0.5|T1|T2|T3> <name> [parent-epic]"; exit 1; }
[[ -z "$TIER" || -z "$NAME" ]] && usage
TIER=$(echo "$TIER" | tr '[:lower:]' '[:upper:]')

# T0.5 fast path: single file, no folder, no Active Plans ceremony.
if [[ "$TIER" == "T0.5" ]]; then
  [[ -n "$PARENT" ]] && { echo "ERROR: T0.5 takes no parent epic."; exit 1; }
  case "$NAME" in
    *[/\\]*) echo "ERROR: T0.5 name must be a single file stem (no slashes)."; exit 1 ;;
  esac
  mkdir -p plans/_quick
  QFILE="plans/_quick/${NAME}.md"
  if [[ -f "$QFILE" && "$FORCE" -eq 0 ]]; then
    echo "ERROR: quick plan already exists at ${QFILE}"
    echo "  Refusing to overwrite. Use --force if you really mean it."
    exit 1
  fi
  cat > "$QFILE" <<EOT
# ${NAME}
## Task
- [ ]
## Verify
- [ ]
EOT
  echo "Created T0.5 → ${QFILE}"
  echo "On completion: delete the file or move it to plans/_archive/."
  exit 0
fi

ROOT="plans"
[[ -n "$PARENT" ]] && ROOT="plans/${PARENT}"
if [[ -n "$PARENT" && ! -f "plans/${PARENT}/OVERVIEW.md" ]]; then
  echo "ERROR: parent epic 'plans/${PARENT}/OVERVIEW.md' not found."
  echo "  Create it first: new-plan.sh T3 ${PARENT}"
  exit 1
fi
TARGET="${ROOT}/${NAME}"

# Overwrite protection
if [[ -d "$TARGET" && "$FORCE" -eq 0 ]]; then
  if [[ -f "${TARGET}/plan.md" || -f "${TARGET}/OVERVIEW.md" || -f "${TARGET}/tasks.md" ]]; then
    echo "ERROR: plan already exists at ${TARGET}"
    echo "  Refusing to overwrite. Use --force if you really mean it."
    exit 1
  fi
fi

case "$TIER" in
  T0)
    echo "T0 — no plan files. Implement directly."
    echo "Optional: .agents/scripts/session-log.sh \"T0 ${NAME}\" \"what you did\""
    exit 0
    ;;
  T1)
    mkdir -p "$TARGET"
    cat > "${TARGET}/plan.md" <<EOT
<!-- T1: task.sh defaults to '## Tasks'. Use --acceptance for '## Acceptance'. See AGENTS.md. -->
# ${NAME}
## Goal
## Acceptance
- [ ] 
## Tasks
- [ ] 
- [ ] 
EOT
    echo "Created T1 → ${TARGET}/plan.md"
    ;;
  T2)
    mkdir -p "$TARGET"
    cat > "${TARGET}/plan.md" <<EOT
# ${NAME}

**Complexity**: T2

## Goal


## Acceptance
- [ ] 

## Approach


## Scope
- In:
- Out:
EOT
    cat > "${TARGET}/tasks.md" <<EOT
# Tasks — ${NAME}

- [ ] 
- [ ] 
- [ ] 
EOT
    cat > "${TARGET}/context.md" <<EOT
# Context — ${NAME}

## Files
- 

## Dependencies
- 

## Open questions
- 
EOT
    echo "Created T2 → ${TARGET}/{plan,tasks,context}.md"
    ;;
  T3)
    mkdir -p "$TARGET"
    cat > "${TARGET}/OVERVIEW.md" <<EOT
# Epic: ${NAME}

**Complexity**: T3

## Goal


## Success
- [ ] 

## Sub-plans
1. \`01-...\` — 
2. \`02-...\` — 

## Order / deps


## Out of scope

EOT
    echo "Created T3 → ${TARGET}/OVERVIEW.md"
    echo "Next: new-plan.sh T1|T2 <sub-name> ${NAME}"
    ;;
  *)
    echo "Unknown tier: $TIER"; usage
    ;;
esac

# Auto-update Active Plans in context.md
if [[ -f plans/context.md && "$TIER" != "T0" ]]; then
  # Relative path from plans/ for display (parent/sub or name)
  if [[ -n "$PARENT" ]]; then
    display="${PARENT}/${NAME}"
  else
    display="${NAME}"
  fi
  ap=$(grep -E '^Active Plans:' plans/context.md | head -1 || true)
  if [[ -z "$ap" ]]; then
    echo "Active Plans: ${display}" >> plans/context.md
  elif echo "$ap" | grep -qE 'none|TBD|^Active Plans:\s*$'; then
    sed -i.bak "s|^Active Plans:.*|Active Plans: ${display}|" plans/context.md
    rm -f plans/context.md.bak
  elif ! echo "$ap" | grep -qw "$display"; then
    sed -i.bak "s|^Active Plans: \(.*\)|Active Plans: \1, ${display}|" plans/context.md
    rm -f plans/context.md.bak
  fi
  echo "Active Plans updated → ${display}"
fi
