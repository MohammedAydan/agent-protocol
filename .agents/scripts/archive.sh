#!/usr/bin/env bash
# archive.sh — Move a CLOSED plan folder to plans/_archive/.
# Usage: archive.sh <plan-folder>  |  archive.sh --all

set -euo pipefail

_remove_active_plan() {
  # Args: name (basename) and optional rel path under plans/
  local name="$1"
  local rel="${2:-$1}"
  [[ -f plans/context.md ]] || return 0
  local ap list item new_ap
  ap=$(grep -E '^Active Plans:' plans/context.md | head -1 || true)
  [[ -z "$ap" ]] && return 0
  list="${ap#Active Plans:}"
  list="${list#"${list%%[![:space:]]*}"}"
  new_ap=""
  IFS=',' read -ra parts <<< "$list"
  for item in "${parts[@]}"; do
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"
    [[ -z "$item" ]] && continue
    [[ "$item" == "$name" || "$item" == "$rel" ]] && continue
    if [[ -z "$new_ap" ]]; then new_ap="$item"; else new_ap="${new_ap}, ${item}"; fi
  done
  if [[ -z "$new_ap" ]]; then
    sed -i.bak "s|^Active Plans:.*|Active Plans: none|" plans/context.md
  else
    sed -i.bak "s|^Active Plans:.*|Active Plans: ${new_ap}|" plans/context.md
  fi
  rm -f plans/context.md.bak
}

archive_one() {
  local target="$1"
  [[ -d "$target" ]] || { echo "ERROR: not a folder: $target"; return 1; }
  case "$target" in plans/_archive*) echo "ERROR: already archived"; return 1;; esac

  for f in "${target}/tasks.md" "${target}/plan.md"; do
    if [[ -f "$f" ]] && grep -qE '^\- \[ \]|^\- \[~\]|^\- \[!\]' "$f" 2>/dev/null; then
      echo "REFUSED: open/blocked tasks in $f — resolve first"; return 1
    fi
  done
  [[ -f "${target}/review.md" ]] || { echo "REFUSED: no review.md — run close-plan.sh first"; return 1; }

  mkdir -p plans/_archive
  local name rel dest
  target="${target%/}"
  name=$(basename "$target")
  rel="${target#plans/}"
  if [[ "$rel" == *"/"* ]]; then
    dest="plans/_archive/${rel}"
    mkdir -p "$(dirname "$dest")"
  else
    dest="plans/_archive/${name}"
  fi
  if [[ -e "$dest" ]]; then dest="${dest}-$(date -u +%Y%m%d%H%M%S)"; fi
  mv "$target" "$dest"
  _remove_active_plan "$name" "$rel"
  echo "archived: $target → $dest"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,4p' "$0"
  exit 0
fi

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

[[ -z "${1:-}" ]] && { sed -n '2,4p' "$0"; exit 1; }
archive_one "$1"
