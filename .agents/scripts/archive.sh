#!/usr/bin/env bash
# archive.sh — Move a CLOSED plan folder to plans/_archive/ (keeps history, cleans boot reads).
# Usage: archive.sh <plan-folder>   |   archive.sh --all   (archive every closable plan)
# Safety: refuses if open [ ]/[~] tasks exist or review.md is missing.

set -euo pipefail

archive_one() {
  local target="$1"
  [[ -d "$target" ]] || { echo "ERROR: not a folder: $target"; return 1; }
  case "$target" in plans/_archive*) echo "ERROR: already archived"; return 1;; esac

  for f in "${target}/tasks.md" "${target}/plan.md"; do
    if [[ -f "$f" ]] && grep -qE '^\- \[ \]|^\- \[~\]|^\- \[!\]' "$f"; then
      echo "REFUSED: open/blocked tasks in $f — resolve them first (task.sh done|cancel)"; return 1
    fi
  done
  [[ -f "${target}/review.md" ]] || { echo "REFUSED: no review.md — run close-plan.sh first"; return 1; }

  mkdir -p plans/_archive
  local dest="plans/_archive/$(basename "$target")"
  if [[ -e "$dest" ]]; then dest="${dest}-$(date -u +%Y%m%d)"; fi
  mv "$target" "$dest"
  # Ensure removed from Active Plans
  if [[ -f plans/context.md ]]; then
    name=$(basename "$target")
    rel="${target#plans/}"
    ap=$(grep -E '^Active Plans:' plans/context.md | head -1 || true)
    if [[ -n "$ap" ]]; then
      new_ap=$(echo "$ap" | sed "s|^Active Plans: *||" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -vx "$name" | grep -vx "$rel" | paste -sd ', ' -)
      if [[ -z "$new_ap" ]]; then
        sed -i.bak "s|^Active Plans:.*|Active Plans: none|" plans/context.md
      else
        sed -i.bak "s|^Active Plans:.*|Active Plans: ${new_ap}|" plans/context.md
      fi
      rm -f plans/context.md.bak
    fi
  fi
  echo "archived: $target → $dest"
  echo "(optional) session-log.sh \"Archived $(basename "$target")\" \"moved to _archive\""
}

if [[ "${1:-}" == "--all" ]]; then
  tmp=$(mktemp); rc=0
  find plans -type d -not -path 'plans/_archive*' 2>/dev/null > "$tmp" || true
  while IFS= read -r dir; do
    [[ -z "$dir" || "$dir" == "plans" ]] && continue
    [[ -f "${dir}/plan.md" || -f "${dir}/OVERVIEW.md" ]] || continue
    if ! archive_one "$dir"; then rc=1; fi
  done < "$tmp"; rm -f "$tmp"
  exit $rc
fi

[[ -z "${1:-}" ]] && { sed -n '2,5p' "$0"; exit 1; }
archive_one "$1"
