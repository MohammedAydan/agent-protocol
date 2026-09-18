#!/usr/bin/env bash
# list-plans.sh — Flat list of active plan folders with tier hint.
# Usage: list-plans.sh [--all]   # --all includes _archive/
# Skips plans/_archive/ by default.

set -euo pipefail
[[ -d plans ]] || { echo "No plans/"; exit 0; }

INCLUDE_ARCHIVE=0
[[ "${1:-}" == "--all" ]] && INCLUDE_ARCHIVE=1

tmp=$(mktemp)
if [[ "$INCLUDE_ARCHIVE" -eq 1 ]]; then
  find plans -type d 2>/dev/null > "$tmp" || true
else
  find plans -type d -not -path '*/_archive*' 2>/dev/null > "$tmp" || true
fi
while IFS= read -r dir; do
  [[ -z "$dir" ]] && continue
  rel="${dir#plans/}"
  [[ -z "$rel" || "$rel" == "$dir" || "$rel" == "plans" ]] && continue
  if [[ -f "${dir}/OVERVIEW.md" ]]; then
    echo "T3  ${rel}"
  elif [[ -f "${dir}/tasks.md" ]]; then
    echo "T2  ${rel}"
  elif [[ -f "${dir}/plan.md" ]]; then
    echo "T1  ${rel}"
  fi
done < "$tmp"
rm -f "$tmp"
