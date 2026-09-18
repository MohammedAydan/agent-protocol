#!/usr/bin/env bash
# task.sh — Reliable task state transitions. Never hand-edit checkboxes.
# Usage:
#   task.sh <plan-folder> <n|text> start|done|cancel|block|reopen [reason]
#     n     = the Nth checkbox line in the file (1-based, top to bottom)
#     text  = first checkbox line containing this substring
# Examples:
#   task.sh plans/auth-login 2 start
#   task.sh plans/auth-login "validate token" done
#   task.sh plans/auth-login 3 block "waiting for API key"
#   task.sh plans/auth-login 1 cancel "out of scope"
# Rules enforced:
#   start  → max ONE [~] per plan folder (fails if another is active)
#   done   → allowed only from [ ] or [~]
#   block/cancel → appends " — reason" to the task text
#   reopen → returns [~]/[x]/[!]/[-] to [ ]

set -euo pipefail

DIR="${1:-}"; SPEC="${2:-}"; ACTION="${3:-}"; REASON="${4:-}"
[[ -z "$DIR" || -z "$SPEC" || -z "$ACTION" ]] && {
  sed -n '2,16p' "$0"; exit 1; }

# Resolve task file: prefer tasks.md, fall back to plan.md
FILE=""
for cand in "${DIR}/tasks.md" "${DIR}/plan.md"; do
  [[ -f "$cand" ]] && { FILE="$cand"; break; }
done
[[ -n "$FILE" ]] || { echo "ERROR: no tasks.md/plan.md in ${DIR}"; exit 1; }

# Locate target line number of the Nth checkbox (or first matching substring)
LINE_NO=""
if [[ "$SPEC" =~ ^[0-9]+$ ]]; then
  LINE_NO=$(awk -v n="$SPEC" '/^- \[.\] /{c++; if(c==n){print NR; exit}}' "$FILE")
  [[ -z "$LINE_NO" ]] && { echo "ERROR: checkbox #$SPEC not found in $FILE"; exit 1; }
else
  LINE_NO=$(grep -nE '^\- \[.\] .*'"$(echo "$SPEC" | sed 's/[][\.*^$/]/\\&/g')" "$FILE" | head -1 | cut -d: -f1 || true)
  [[ -z "$LINE_NO" ]] && { echo "ERROR: no checkbox matching '$SPEC' in $FILE"; exit 1; }
fi

CURRENT=$(sed -n "${LINE_NO}p" "$FILE")

set_marker() {
  local new="$1"
  # Replace only the leading marker "- [x]"
  sed -i.bak "${LINE_NO}s/^- \\[.\\] /- [${new}] /" "$FILE"
  rm -f "${FILE}.bak"
}

active_tilde() {
  awk '/^- \[~\] /{c++} END{print c+0}' "$FILE"
}

case "$ACTION" in
  start)
    if [[ "$CURRENT" == *"[~]"* ]]; then echo "Already [~]"; exit 0; fi
    n=$(active_tilde)
    if [[ "$n" -ge 1 && "$CURRENT" != *"[x]"* && "$CURRENT" != *"[-]"* ]]; then
      other=$(grep -nE '^\- \[~\]' "$FILE" | head -1)
      echo "ERROR: another task is already in progress: ${other}"
      echo "Finish or block it first (one [~] per plan folder)."
      exit 1
    fi
    set_marker '~'
    echo "STARTED  $(sed -n "${LINE_NO}p" "$FILE")"
    ;;
  done)
    [[ "$CURRENT" == *"[x]"* ]] && { echo "Already done"; exit 0; }
    set_marker 'x'
    echo "DONE     $(sed -n "${LINE_NO}p" "$FILE")"
    ;;
  block)
    [[ -z "$REASON" ]] && { echo "ERROR: block needs a reason"; exit 1; }
    set_marker '!'
    sed -i.bak "${LINE_NO}s/$/ — ${REASON}/" "$FILE"; rm -f "${FILE}.bak"
    echo "BLOCKED  $(sed -n "${LINE_NO}p" "$FILE")"
    ;;
  cancel)
    set_marker '-'
    [[ -n "$REASON" ]] && { sed -i.bak "${LINE_NO}s/$/ — ${REASON}/" "$FILE"; rm -f "${FILE}.bak"; }
    echo "CANCELLED $(sed -n "${LINE_NO}p" "$FILE")"
    ;;
  reopen)
    # strip any appended reason on reopen
    sed -i.bak "${LINE_NO}s/ — .*$//" "$FILE"; rm -f "${FILE}.bak"
    set_marker ' '
    echo "REOPENED $(sed -n "${LINE_NO}p" "$FILE")"
    ;;
  *)
    echo "Unknown action: $ACTION (start|done|cancel|block|reopen)"; exit 1
    ;;
esac
