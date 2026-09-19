#!/usr/bin/env bash
# task.sh — Reliable task state transitions. Never hand-edit checkboxes.
# Usage:
#   task.sh <plan-folder> <n|text> start|done|cancel|block|reopen [reason]
#   task.sh --file plan.md <plan-folder> <n|text> <action> [reason]
#   task.sh --file tasks.md <plan-folder> ...
#   task.sh --acceptance <plan-folder> <n|text> done   # force plan.md (T2 acceptance)
#   task.sh --section tasks|acceptance <plan-folder> <n|text> <action> [reason]
#   task.sh [-q|--quiet] ...           # same output minus WARNING lines
#   printf '1 start\n1 done\n' | task.sh [--file ...] [--section ...] --batch <plan-folder>
#
# Rules:
#   start → max ONE [~] per *file* being edited (and warn if other file has [~])
#   Sequential calls only per plan folder (avoid parallel sed races)
# Windows: bash -lc "bash .agents/scripts/task.sh plans/x 1 start"

set -euo pipefail

FILE_OVERRIDE=""
FORCE_ACCEPTANCE=0
SECTION_ARG=""
QUIET=0
BATCH=0
while [[ "${1:-}" =~ ^- ]]; do
  case "$1" in
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    -q|--quiet) QUIET=1; shift ;;
    --batch) BATCH=1; shift ;;
    --file) FILE_OVERRIDE="$2"; shift 2 ;;
    --acceptance) FORCE_ACCEPTANCE=1; shift ;;
    --section) SECTION_ARG="$2"; shift 2 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

if [[ "$BATCH" -eq 1 ]]; then
  BDIR="${1:-}"
  [[ -z "$BDIR" ]] && { echo "Usage: task.sh [--file F] [--section S] [--acceptance] [-q] --batch <plan-folder> < stdin(list of '<n> <action> [reason]')"; exit 1; }
  EXTRA=()
  [[ -n "$FILE_OVERRIDE" ]] && EXTRA+=(--file "$FILE_OVERRIDE")
  [[ "$FORCE_ACCEPTANCE" -eq 1 ]] && EXTRA+=(--acceptance)
  [[ -n "$SECTION_ARG" ]] && EXTRA+=(--section "$SECTION_ARG")
  [[ "$QUIET" -eq 1 ]] && EXTRA+=(-q)
  brc=0
  while IFS= read -r bline || [[ -n "$bline" ]]; do
    [[ -z "$bline" ]] && continue
    # shellcheck disable=SC2086
    set -- $bline
    bspec="${1:-}"; baction="${2:-}"; shift 2 || true
    if [[ -z "$bspec" || -z "$baction" ]]; then
      echo "ERROR: bad batch line (want '<n> <action> [reason]'): $bline"
      brc=1
      break
    fi
    if ! bash "$0" "${EXTRA[@]}" "$BDIR" "$bspec" "$baction" "$@"; then
      echo "BATCH stopped at: $bline"
      brc=1
      break
    fi
  done
  exit "$brc"
fi

DIR="${1:-}"; SPEC="${2:-}"; ACTION="${3:-}"; REASON="${4:-}"
[[ -z "$DIR" || -z "$SPEC" || -z "$ACTION" ]] && {
  sed -n '2,16p' "$0"; exit 1; }

RESOLVED_SECTION=""
if [[ "$FORCE_ACCEPTANCE" -eq 1 ]]; then
  RESOLVED_SECTION="acceptance"
elif [[ -n "$SECTION_ARG" ]]; then
  case "$SECTION_ARG" in
    acceptance) RESOLVED_SECTION="acceptance" ;;
    tasks) RESOLVED_SECTION="tasks" ;;
    *) echo "ERROR: invalid section: $SECTION_ARG (expected tasks|acceptance)"; exit 1 ;;
  esac
fi

FILE=""
TARGET_SECTION=""
if [[ "$RESOLVED_SECTION" == "acceptance" ]]; then
  FILE="${DIR}/plan.md"
  TARGET_SECTION="Acceptance"
elif [[ -n "$FILE_OVERRIDE" ]]; then
  case "$FILE_OVERRIDE" in
    plan.md|tasks.md) FILE="${DIR}/${FILE_OVERRIDE}" ;;
    *) FILE="$FILE_OVERRIDE" ;;
  esac
  if [[ "$RESOLVED_SECTION" == "tasks" && "$FILE" == *"plan.md" ]]; then
    TARGET_SECTION="Tasks"
  fi
else
  for cand in "${DIR}/tasks.md" "${DIR}/plan.md"; do
    if [[ -f "$cand" ]]; then
      FILE="$cand"
      break
    fi
  done
  if [[ -n "$FILE" && "$FILE" == *"plan.md" ]]; then
    if grep -qi '^##[[:space:]]*tasks' "$FILE"; then
      TARGET_SECTION="Tasks"
    fi
  fi
fi

[[ -n "$FILE" && -f "$FILE" ]] || { echo "ERROR: no tasks.md/plan.md in ${DIR}"; exit 1; }

LINE_NO=""
if [[ -n "$TARGET_SECTION" ]]; then
  if [[ "$SPEC" =~ ^[0-9]+$ ]]; then
    LINE_NO=$(awk -v sec="$TARGET_SECTION" -v n="$SPEC" '
      BEGIN {
        in_sec = 0; c = 0
        if (tolower(sec) == "acceptance") {
          re = "^##[[:space:]]+[Aa]cceptance"
        } else {
          re = "^##[[:space:]]+[Tt]asks"
        }
      }
      $0 ~ re { in_sec = 1; next }
      in_sec && /^##[[:space:]]+/ { in_sec = 0 }
      in_sec && /^- \[.\] / {
        c++
        if (c == n) { print NR; exit }
      }
    ' "$FILE")
    [[ -z "$LINE_NO" ]] && { echo "ERROR: checkbox #$SPEC not found in ## $TARGET_SECTION of $FILE"; exit 1; }
  else
    LINE_NO=$(awk -v sec="$TARGET_SECTION" -v pattern="$SPEC" '
      BEGIN {
        in_sec = 0
        if (tolower(sec) == "acceptance") {
          re = "^##[[:space:]]+[Aa]cceptance"
        } else {
          re = "^##[[:space:]]+[Tt]asks"
        }
      }
      $0 ~ re { in_sec = 1; next }
      in_sec && /^##[[:space:]]+/ { in_sec = 0 }
      in_sec && /^- \[.\] / && index($0, pattern) {
        print NR; exit
      }
    ' "$FILE")
    [[ -z "$LINE_NO" ]] && { echo "ERROR: no checkbox matching '$SPEC' in ## $TARGET_SECTION of $FILE"; exit 1; }
  fi
else
  if [[ "$SPEC" =~ ^[0-9]+$ ]]; then
    LINE_NO=$(awk -v n="$SPEC" '/^- \[.\] /{c++; if(c==n){print NR; exit}}' "$FILE")
    [[ -z "$LINE_NO" ]] && { echo "ERROR: checkbox #$SPEC not found in $FILE"; exit 1; }
  else
    LINE_NO=$(grep -nE '^\- \[.\] .*'"$(echo "$SPEC" | sed 's/[][\.*^$/]/\\&/g')" "$FILE" | head -1 | cut -d: -f1 || true)
    [[ -z "$LINE_NO" ]] && { echo "ERROR: no checkbox matching '$SPEC' in $FILE"; exit 1; }
  fi
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
    case "$CURRENT" in
      "- [~]"*) echo "Already [~]"; exit 0 ;;
    esac
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
        [[ "$QUIET" -eq 0 ]] && echo "WARNING: ${otherf} also has [~] — finish it before parallel work in same plan"
      fi
    done
    set_marker '~'
    echo "STARTED  $(sed -n "${LINE_NO}p" "$FILE")  ($FILE)"
    ;;
  done)
    case "$CURRENT" in
      "- [x]"*) echo "Already done"; exit 0 ;;
      "- [ ]"*|"- [~]"*|"- [!]"*) ;;
      *)
        echo "ERROR: cannot mark done from current state: $CURRENT"
        exit 1
        ;;
    esac
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
