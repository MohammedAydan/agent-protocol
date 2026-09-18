#!/usr/bin/env bash
# status.sh — Overview of active plans and open tasks.
# Usage: status.sh [plans-root]
# Portable: no process substitution. Skips plans/_archive/.

set -euo pipefail
ROOT="${1:-plans}"

if [[ ! -d "$ROOT" ]]; then
  echo "No plans/ directory. Run bootstrap.sh first."
  exit 0
fi

count_marker() {
  local file="$1" pattern="$2"
  if [[ ! -f "$file" ]]; then
    printf '0'
    return
  fi
  local n
  n=$(grep -cE "$pattern" "$file" 2>/dev/null || true)
  printf '%s' "${n:-0}"
}

echo "=== context.md (head) ==="
if [[ -f "${ROOT}/context.md" ]]; then
  head -n 12 "${ROOT}/context.md"
else
  echo "(missing)"
fi
echo ""

echo "=== Plan folders (active; _archive skipped) ==="
any=0
tmp=$(mktemp)
find "$ROOT" -type d -not -path '*/_archive*' 2>/dev/null > "$tmp" || true
while IFS= read -r dir; do
  [[ -z "$dir" ]] && continue
  rel="${dir#${ROOT}/}"
  [[ -z "$rel" || "$rel" == "$dir" ]] && continue
  if [[ -f "${dir}/plan.md" || -f "${dir}/OVERVIEW.md" ]]; then
    any=1
    echo "- ${rel}"
    if [[ -f "${dir}/tasks.md" ]]; then
      o=$(count_marker "${dir}/tasks.md" '^\- \[ \]')
      p=$(count_marker "${dir}/tasks.md" '^\- \[~\]')
      d=$(count_marker "${dir}/tasks.md" '^\- \[x\]')
      b=$(count_marker "${dir}/tasks.md" '^\- \[!\]')
      echo "    tasks  open=${o}  [~]=${p}  done=${d}  blocked=${b}"
    elif [[ -f "${dir}/plan.md" ]]; then
      o=$(count_marker "${dir}/plan.md" '^\- \[ \]')
      p=$(count_marker "${dir}/plan.md" '^\- \[~\]')
      d=$(count_marker "${dir}/plan.md" '^\- \[x\]')
      b=$(count_marker "${dir}/plan.md" '^\- \[!\]')
      echo "    (T1) open=${o}  [~]=${p}  done=${d}  blocked=${b}"
    elif [[ -f "${dir}/OVERVIEW.md" ]]; then
      echo "    (T3 epic)"
    fi
  fi
done < "$tmp"
rm -f "$tmp"
[[ "$any" -eq 0 ]] && echo "(none yet)"

echo ""
echo "=== Last SESSION_LOG entry ==="
if [[ -f "${ROOT}/SESSION_LOG.md" ]]; then
  awk '/^## /{buf=$0; next} {if(buf) buf=buf"\n"$0} END{print buf}' "${ROOT}/SESSION_LOG.md" | tail -n 20
else
  echo "(no SESSION_LOG.md)"
fi
