#!/usr/bin/env bash
# resume.sh — Minimal session boot (token-cheap).
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,3p' "$0"
  exit 0
fi

R="plans"
echo "=== SESSION RESUME ==="
if [[ -f "$R/context.md" ]]; then head -n 8 "$R/context.md"; else echo "(no context — bootstrap.sh)"; fi
echo ""
echo "--- last log ---"
if [[ -f "$R/SESSION_LOG.md" ]]; then
  awk '/^## /{buf=$0; next} {if(buf) buf=buf"\n"$0} END{print buf}' "$R/SESSION_LOG.md" | tail -n 6
else
  echo "(no log)"
fi
echo ""
echo "--- next (max 3) ---"
tmp=$(mktemp)
find "$R" -type d -not -path '*/_archive*' 2>/dev/null > "$tmp" || true
c=0
while IFS= read -r dir && [[ $c -lt 3 ]]; do
  [[ -z "$dir" || "$dir" == "$R" ]] && continue
  for f in "${dir}/tasks.md" "${dir}/plan.md"; do
    [[ -f "$f" ]] || continue
    line=$(grep -E '^\- \[ \]|^\- \[~\]' "$f" 2>/dev/null | head -1 || true)
    if [[ -n "$line" ]]; then
      echo "• ${dir#plans/}: $line"
      c=$((c+1))
      break
    fi
  done
done < "$tmp"
rm -f "$tmp"
if [[ -d "$R/_quick" ]]; then
  for qf in "$R"/_quick/*.md; do
    [[ -f "$qf" ]] || continue
    qline=$(grep -E '^\- \[ \]|^\- \[~\]' "$qf" 2>/dev/null | head -1 || true)
    if [[ -n "$qline" ]]; then
      echo "[quick] $(basename "$qf" .md): $qline"
    fi
  done
fi
if [[ $c -eq 0 ]]; then echo "(all clear)"; fi
exit 0
