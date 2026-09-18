#!/usr/bin/env bash
# verify-checklist.sh — Print a short verification checklist for agents before marking [x].
# Usage: verify-checklist.sh [optional-note]

set -euo pipefail
NOTE="${1:-}"

cat <<EOF
=== Verification checklist (before [x]) ===
[ ] Linter / formatter pass
[ ] Tests implied by acceptance criteria ran against real output
[ ] No silent failures / skipped tests counted as success
[ ] UI change → screenshot or visual evidence (if harness supports)
[ ] Living docs updated if needed (TECH_STACK / ARCH / DECISIONS)
[ ] Scope not expanded silently
[ ] No secrets or .env values written
${NOTE:+[ ] Note: $NOTE}
==========================================
EOF
