#!/usr/bin/env bash
# lint-encoding.sh — Enforce UTF-8 no-BOM, LF endings on scripts, and .gitattributes policy.
# Usage:
#   lint-encoding.sh
# Exit:
#   0 = clean, 1 = violations found
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,6p' "$0"
  exit 0
fi

violations=0

# 1. Verify .gitattributes exists and has *.sh text eol=lf
if [[ ! -f .gitattributes ]]; then
  echo ".gitattributes: missing file"
  violations=$((violations + 1))
elif ! grep -qE '^\*\.sh\s+text\s+eol=lf$' .gitattributes; then
  echo ".gitattributes: missing required line '*.sh text eol=lf'"
  violations=$((violations + 1))
fi

# 2. Check all tracked files for UTF-8 BOM (EF BB BF at position 0)
# and tracked .sh files for CRLF (\r\n)
tmp_tracked=$(mktemp)
git ls-files > "$tmp_tracked"

while IFS= read -r f; do
  [[ -z "$f" || ! -f "$f" ]] && continue

  # Check for UTF-8 BOM: first 3 bytes EF BB BF
  if head -c 3 "$f" 2>/dev/null | od -An -tx1 | grep -q 'ef bb bf'; then
    echo "${f}: UTF-8 BOM detected"
    violations=$((violations + 1))
  fi

  # Check .sh files for CRLF
  if [[ "$f" == *.sh ]]; then
    if file "$f" 2>/dev/null | grep -q "CRLF" || grep -Uq $'\r' "$f" 2>/dev/null; then
      echo "${f}: CRLF line endings detected in shell script"
      violations=$((violations + 1))
    fi
  fi
done < "$tmp_tracked"
rm -f "$tmp_tracked"

if [[ "$violations" -ne 0 ]]; then
  exit 1
fi
exit 0
