#!/usr/bin/env bash
# verify-checklist.sh — Print verification checklist before marking [x].
set -euo pipefail
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
