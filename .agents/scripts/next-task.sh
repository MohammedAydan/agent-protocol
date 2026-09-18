#!/usr/bin/env bash
# next-task.sh — First pending [ ] task from a plan folder (or all active plans).
# Portable: no process substitution. Skips plans/_archive/.

set -euo pipefail

print_first_pending() {
  local f="$1"
  local label="$2"
  if [[ -f "$f" ]]; then
    local line
    line=$(grep -nE '^\- \[ \]' "$f" 2>/dev/null | head -n 1 || true)
    if [[ -n "${line}" ]]; then
      echo "[${label}] ${line#*:}"
      return 0
    fi
  fi
  return 1
}

if [[ -n "${1:-}" ]]; then
  dir="$1"
  if print_first_pending "${dir}/tasks.md" "$(basename "$dir")" || \
     print_first_pending "${dir}/plan.md" "$(basename "$dir")"; then
    exit 0
  fi
  echo "No pending tasks in ${dir}"
  exit 0
fi

if [[ ! -d plans ]]; then
  echo "No plans/ directory."
  exit 0
fi

found=0
tmp=$(mktemp)
find plans -type d -not -path '*/_archive*' 2>/dev/null > "$tmp" || true
while IFS= read -r dir; do
  [[ -z "$dir" ]] && continue
  rel="${dir#plans/}"
  [[ -z "$rel" || "$rel" == "$dir" ]] && continue
  if print_first_pending "${dir}/tasks.md" "$rel" || \
     print_first_pending "${dir}/plan.md" "$rel"; then
    found=1
  fi
done < "$tmp"
rm -f "$tmp"

if [[ "$found" -eq 0 ]]; then
  echo "No pending tasks found under plans/"
fi
