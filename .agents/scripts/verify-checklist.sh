#!/usr/bin/env bash
# verify-checklist.sh — Print verification checklist before marking [x], or enforce strict CI checks.
# Usage:
#   verify-checklist.sh [note]
#   verify-checklist.sh --strict <plan-folder>
#
# In --strict mode: scans tasks.md, plan.md, and OVERVIEW.md for open tasks ([ ], [~], [!]).
# Prints each violation as <file>:<line>: <content> and exits 1 if any found.
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,8p' "$0"
  exit 0
fi

if [[ "${1:-}" == "--strict" ]]; then
  shift
  DIR="${1:-}"
  [[ -z "$DIR" || ! -d "$DIR" ]] && { echo "Usage: verify-checklist.sh --strict <plan-folder>"; exit 1; }
  found_open=0
  for f in "${DIR}/tasks.md" "${DIR}/plan.md" "${DIR}/OVERVIEW.md"; do
    if [[ -f "$f" ]]; then
      tmp_v=$(mktemp)
      grep -nE '^\- \[ \]|^\- \[~\]|^\- \[!\]' "$f" 2>/dev/null > "$tmp_v" || true
      if [[ -s "$tmp_v" ]]; then
        found_open=1
        while IFS= read -r line; do
          echo "${f}:${line}"
        done < "$tmp_v"
      fi
      rm -f "$tmp_v"
    fi
  done
  if [[ "$found_open" -ne 0 ]]; then
    exit 1
  fi
  exit 0
fi

NOTE="${1:-}"
cat <<EOF
=== Verification checklist (before [x]) ===
[ ] Goal/Acceptance in plan.md were filled (not empty stubs)
[ ] task.sh start was used (or marker [~] set) before coding
[ ] Linter / formatter pass (if project has them)
[ ] Checks implied by acceptance ran against real output
[ ] No silent failures / skipped tests counted as success
[ ] UI change → browser open or visual note (if relevant)
[ ] Living docs updated if needed (TECH_STACK / ARCH / DECISIONS)
[ ] Scope not expanded silently
[ ] No secrets or .env values written
${NOTE:+[ ] Note: $NOTE}
=== After all tasks done ===
[ ] close-plan.sh plans/<name>
[ ] SESSION_LOG entry appended
[ ] optional archive.sh
==========================================
EOF
