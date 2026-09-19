#!/usr/bin/env bash
# task.sh — Reliable task state transitions. Never hand-edit checkboxes.
# Usage:
#   task.sh <plan-folder> <n|text> start|done|cancel|block|reopen [reason]
#   task.sh --file plan.md <plan-folder> <n|text> <action> [reason]
#   task.sh --file tasks.md <plan-folder> ...
#   task.sh --acceptance <plan-folder> <n|text> done   # force plan.md (T2 acceptance)
#
# Rules:
#   start → max ONE [~] per *file* being edited (and warn if other file has [~])
#   Sequential calls only per plan folder (avoid parallel sed races)
# Windows: bash -lc "bash .agents/scripts/task.sh plans/x 1 start"

set -euo pipefail

FILE_OVERRIDE=""
FORCE_ACCEPTANCE=0
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --file) FILE_OVERRIDE="$2"; shift 2 ;;
    --acceptance) FORCE_ACCEPTANCE=1; shift ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

DIR="${1:-}"; SPEC="${2:-}"; ACTION="${3:-}"; REASON="${4:-}"
[[ -z "$DIR" || -z "$SPEC" || -z "$ACTION" ]] && {
  sed -n '2,14p' "$0"; exit 1; }

FILE=""
if [[ "$FORCE_ACCEPTANCE" -eq 1 ]]; then
  FILE="${DIR}/plan.md"
elif [[ -n "$FILE_OVERRIDE" ]]; then
  case "$FILE_OVERRIDE" in
    plan.md|tasks.md) FILE="${DIR}/${FILE_OVERRIDE}" ;;
    *) FILE="$FILE_OVERRIDE" ;;
  esac
else
  for cand in "${DIR}/tasks.md" "${DIR}/plan.md"; do
    [[ -f "$cand" ]] && { FILE="$cand"; break; }
  done
fi
[[ -n "$FILE" && -f "$FILE" ]] || { echo "ERROR: no tasks.md/plan.md in ${DIR}"; exit 1; }

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
  sed -i.bak "${LINE_NO}s/^- \\[.\\] /- [${new}] /" "$FILE"
  rm -f "${FILE}.bak"
}

active_tilde() {
  local f="$1"
  awk '/^- \[~\] /{c++} END{print c+0}' "$f"
}

case "$ACTION" in
  start)
    if [[ "$CURRENT" == *"[~]"* ]]; then echo "Already [~]"; exit 0; fi
    n=$(active_tilde "$FILE")
    if [[ "$n" -ge 1 ]]; then
      other=$(grep -nE '^\- \[~\]' "$FILE" | head -1)
      echo "ERROR: another task is already in progress: ${other}"
      echo "Finish or block it first (one [~] per file)."
      exit 1
    fi
    # Soft warn if the other file in the plan has [~]
    for otherf in "${DIR}/tasks.md" "${DIR}/plan.md"; do
      [[ -f "$otherf" && "$otherf" != "$FILE" ]] || continue
      if [[ $(active_tilde "$otherf") -ge 1 ]]; then
        echo "WARNING: ${otherf} also has [~] — finish it before parallel work in same plan"
      fi
    done
    set_marker '~'
    echo "STARTED  $(sed -n "${LINE_NO}p" "$FILE")  ($FILE)"
    ;;
  done)
    [[ "$CURRENT" == *"[x]"* ]] && { echo "Already done"; exit 0; }
    if [[ "$CURRENT" != *"[ ]"* && "$CURRENT" != *"[~]"* && "$CURRENT" != *"[!]"* ]]; then
      echo "ERROR: cannot mark done from current state: $CURRENT"
      exit 1
    fi
    set_marker 'x'
    echo "DONE     $(sed -n "${LINE_NO}p" "$FILE")  ($FILE)"
    ;;
  cancel)
    set_marker '-'
    if [[ -n "$REASON" ]]; then
      sed -i.bak "${LINE_NO}s/\$/ — ${REASON}/" "$FILE"
      rm -f "${FILE}.bak"
    fi
    echo "CANCEL   $(sed -n "${LINE_NO}p" "$FILE")  ($FILE)"
    ;;
  block)
    set_marker '!'
    if [[ -n "$REASON" ]]; then
      sed -i.bak "${LINE_NO}s/\$/ — ${REASON}/" "$FILE"
      rm -f "${FILE}.bak"
    fi
    echo "BLOCKED  $(sed -n "${LINE_NO}p" "$FILE")  ($FILE)"
    ;;
  reopen)
    set_marker ' '
    echo "REOPENED $(sed -n "${LINE_NO}p" "$FILE")  ($FILE)"
    ;;
  *)
    echo "Unknown action: $ACTION (use start|done|cancel|block|reopen)"
    exit 1
    ;;
esac
