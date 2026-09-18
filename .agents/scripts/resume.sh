#!/usr/bin/env bash
# resume.sh — Minimal session boot (token-cheap).
set -euo pipefail
R="plans"
echo "=== SESSION RESUME ==="
[[ -f "$R/context.md" ]] && head -n 8 "$R/context.md" || echo "(no context — bootstrap.sh)"
echo ""
echo "--- last log ---"
[[ -f "$R/SESSION_LOG.md" ]] && awk '/^## /{buf=$0; next} {if(buf) buf=buf"\n"$0} END{print buf}' "$R/SESSION_LOG.md" | tail -n 6 || echo "(no log)"
echo ""
echo "--- next (max 3) ---"
tmp=$(mktemp); find "$R" -type d -not -path '*/_archive*' 2>/dev/null > "$tmp" || true
c=0
while IFS= read -r dir && [[ $c -lt 3 ]]; do
  [[ -z "$dir" || "$dir" == "$R" ]] && continue
  for f in "${dir}/tasks.md" "${dir}/plan.md"; do
    [[ -f "$f" ]] || continue
    line=$(grep -E '^\- \[ \]|^\- \[~\]' "$f" 2>/dev/null | head -1 || true)
    [[ -n "$line" ]] && { echo "• ${dir#plans/}: $line"; c=$((c+1)); break; }
  done
done < "$tmp"; rm -f "$tmp"
[[ $c -eq 0 ]] && echo "(all clear)"
