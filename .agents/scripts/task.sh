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
#   task.sh --quick <name> <n|text> <action> [reason]  # T0.5 single file (no hand-edits)
#   task.sh plans/_quick/<name>.md <n|text> <action> [reason]  # same, native path
#   printf '1 start\n1 done\n' | task.sh --quick <name> --batch  # batch on T0.5
#
# Rules:
#   start → max ONE [~] per *file* being edited (and warn if other file has [~])
#   Sequential calls only per plan folder (avoid parallel sed races)
#   T0.5 files count ALL checkboxes in file order (## Task then ## Verify)
# Windows: bash -lc "bash .agents/scripts/task.sh plans/x 1 start"

set -euo pipefail

FILE_OVERRIDE=""
FORCE_ACCEPTANCE=0
SECTION_ARG=""
QUIET=0
BATCH=0
QUICK=""
while [[ "${1:-}" =~ ^- ]]; do
  case "$1" in
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    -q|--quiet) QUIET=1; shift ;;
    --batch) BATCH=1; shift ;;
    --quick) QUICK="${2:-}"; shift 2 ;;
    --file) FILE_OVERRIDE="$2"; shift 2 ;;
    --acceptance) FORCE_ACCEPTANCE=1; shift ;;
    --section) SECTION_ARG="$2"; shift 2 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

# v1.2.1: resolve --quick <name> to its single-file plan. Native file paths
# (plans/_quick/<name>.md) are also accepted directly as the target.
QUICKFILE=0
if [[ -n "$QUICK" ]]; then
  case "$QUICK" in
    *[/\\]*) echo "ERROR: quick name must be a single file stem (no slashes)."; exit 1 ;;
  esac
  if [[ "$BATCH" -eq 1 ]]; then
    set -- "plans/_quick/${QUICK}.md" "$@"
  else
    # Rebuild positional args: <file> <spec> <action> [reason...]
    _qrest=("$@")
    set -- "plans/_quick/${QUICK}.md" "${_qrest[@]}"
  fi
  QUICKFILE=1
fi

if [[ "$BATCH" -eq 1 ]]; then
  BDIR="${1:-}"
  [[ -z "$BDIR" ]] && { echo "Usage: task.sh [--file F] [--section S] [--acceptance] [-q] --batch <plan-folder> | --quick <name> --batch | <quick-file> --batch < stdin(list of '<n> <action> [reason]')"; exit 1; }
  # OPT-4 REVISION (audit): in-memory batch — resolve target file ONCE,
  # load into array, apply all transitions in-process, single file write,
  # zero sub-process forks per task item (no bash re-invocation, no
  # grep/sed/awk per item). Parity with sequential calls verified by
  # test-scripts.sh "batch equals sequential".
  # v1.2.1: direct-file targets (plans/_quick/<name>.md via --quick or
  # native path) skip folder/section resolution; ALL checkboxes count in
  # file order (## Task then ## Verify).
  _B_FILE=""
  _B_TARGET_SECTION=""
  if [[ -f "$BDIR" ]]; then
    _B_FILE="$BDIR"
  else
  _B_RESOLVED_SECTION=""
  if [[ "$FORCE_ACCEPTANCE" -eq 1 ]]; then
    _B_RESOLVED_SECTION="acceptance"
  elif [[ -n "$SECTION_ARG" ]]; then
    case "$SECTION_ARG" in
      acceptance) _B_RESOLVED_SECTION="acceptance" ;;
      tasks) _B_RESOLVED_SECTION="tasks" ;;
      *) echo "ERROR: invalid section: $SECTION_ARG (expected tasks|acceptance)"; exit 1 ;;
    esac
  fi
  if [[ "$_B_RESOLVED_SECTION" == "acceptance" ]]; then
    _B_FILE="${BDIR}/plan.md"
    _B_TARGET_SECTION="Acceptance"
  elif [[ -n "$FILE_OVERRIDE" ]]; then
    case "$FILE_OVERRIDE" in
      plan.md|tasks.md) _B_FILE="${BDIR}/${FILE_OVERRIDE}" ;;
      *) _B_FILE="$FILE_OVERRIDE" ;;
    esac
    if [[ "$_B_RESOLVED_SECTION" == "tasks" && "$_B_FILE" == *"plan.md" ]]; then
      _B_TARGET_SECTION="Tasks"
    fi
  else
    for cand in "${BDIR}/tasks.md" "${BDIR}/plan.md"; do
      if [[ -f "$cand" ]]; then
        _B_FILE="$cand"
        break
      fi
    done
    if [[ -n "$_B_FILE" && "$_B_FILE" == *"plan.md" ]]; then
      # Single grep (one fork total, not per item) to detect Tasks section.
      if grep -qi '^##[[:space:]]*tasks' "$_B_FILE"; then
        _B_TARGET_SECTION="Tasks"
      fi
    fi
  fi
  fi
  [[ -n "$_B_FILE" && -f "$_B_FILE" ]] || { echo "ERROR: no tasks.md/plan.md in ${BDIR}"; exit 1; }
  # Load file once.
  _B_LINES=()
  while IFS= read -r _bl || [[ -n "$_bl" ]]; do
    _B_LINES+=("$_bl")
  done < "$_B_FILE"
  # Build ordered checkbox index (0-based array positions) within scope.
  _B_BOX_POS=()
  _b_in_sec=0
  _b_has_scope=0
  [[ -n "$_B_TARGET_SECTION" ]] && _b_has_scope=1
  # For acceptance scope, section header matches Acceptance; for Tasks, Tasks.
  for _bi in "${!_B_LINES[@]}"; do
    _bline="${_B_LINES[$_bi]}"
    if [[ "$_b_has_scope" -eq 1 ]]; then
      if [[ "$_B_TARGET_SECTION" == "Acceptance" ]]; then
        if [[ "$_bline" =~ ^##[[:space:]]+[Aa]cceptance ]]; then _b_in_sec=1; continue; fi
      else
        if [[ "$_bline" =~ ^##[[:space:]]+[Tt]asks ]]; then _b_in_sec=1; continue; fi
      fi
      if [[ "$_b_in_sec" -eq 1 && "$_bline" =~ ^##[[:space:]]+ ]]; then _b_in_sec=0; fi
      [[ "$_b_in_sec" -eq 0 ]] && continue
    fi
    # Match "- [X] " prefix or bare "- [X]" at end of line (fresh T0.5 boxes).
    case "$_bline" in
      "- ["?"] "*|"- ["?"]") _B_BOX_POS+=("$_bi") ;;
    esac
  done
  # In-memory tilde count (no awk per item).
  _b_tildes=0
  for _bp in "${_B_BOX_POS[@]}"; do
    case "${_B_LINES[$_bp]}" in
      "- [~]"*) _b_tildes=$((_b_tildes+1)) ;;
    esac
  done
  # Soft warn once if the OTHER file in the plan has [~] (parity with single path).
  if [[ "$QUIET" -eq 0 ]]; then
    for _otherf in "${BDIR}/tasks.md" "${BDIR}/plan.md"; do
      [[ -f "$_otherf" && "$_otherf" != "$_B_FILE" ]] || continue
      _ow=0
      while IFS= read -r _ol || [[ -n "$_ol" ]]; do
        case "$_ol" in "- [~]"*) _ow=1; break ;; esac
      done < "$_otherf"
      if [[ "$_ow" -eq 1 ]]; then
        echo "WARNING: ${_otherf} also has [~] — finish it before parallel work in same plan"
        break
      fi
    done
  fi
  _b_write_and_exit() {
    printf '%s\n' "${_B_LINES[@]}" > "$_B_FILE"
    exit "$1"
  }
  _b_resolve_pos() {
    # $1 = spec; sets global _BPOS to 0-based position index into _B_LINES,
    # or "" if not found. No command substitution (zero forks per item).
    local spec="$1" _k _p
    _BPOS=""
    if [[ "$spec" =~ ^[0-9]+$ ]]; then
      _k=$((spec-1))
      if [[ "$_k" -ge 0 && "$_k" -lt "${#_B_BOX_POS[@]}" ]]; then
        _BPOS="${_B_BOX_POS[$_k]}"
      fi
      return 0
    fi
    for _p in "${_B_BOX_POS[@]}"; do
      if [[ "${_B_LINES[$_p]}" == *"$spec"* ]]; then
        _BPOS="$_p"
        return 0
      fi
    done
    return 0
  }
  brc=0
  while IFS= read -r bline || [[ -n "$bline" ]]; do
    [[ -z "$bline" ]] && continue
    # shellcheck disable=SC2086
    set -- $bline
    bspec="${1:-}"; baction="${2:-}"; shift 2 || true
    breason="${1:-}"
    if [[ -z "$bspec" || -z "$baction" ]]; then
      echo "ERROR: bad batch line (want '<n> <action> [reason]'): $bline"
      _b_write_and_exit 1
    fi
    _b_resolve_pos "$bspec"
    _bpos="$_BPOS"
    if [[ -z "$_bpos" ]]; then
      if [[ -n "$_B_TARGET_SECTION" ]]; then
        echo "ERROR: checkbox #$bspec not found in ## $_B_TARGET_SECTION of $_B_FILE"
      else
        echo "ERROR: checkbox #$bspec not found in $_B_FILE"
      fi
      echo "BATCH stopped at: $bline"
      _b_write_and_exit 1
    fi
    _cur="${_B_LINES[$_bpos]}"
    case "$baction" in
      start)
        case "$_cur" in
          "- [~]"*) echo "Already [~]"; continue ;;
        esac
        if [[ "$_b_tildes" -ge 1 ]]; then
          _oi=0; _otext=""
          for _p in "${_B_BOX_POS[@]}"; do
            case "${_B_LINES[$_p]}" in "- [~]"*) _oi=$((_p+1)); _otext="${_B_LINES[$_p]}"; break ;; esac
          done
          echo "ERROR: another task is already in progress: ${_oi}:${_otext}"
          echo "Finish or block it first (one [~] per file)."
          echo "BATCH stopped at: $bline"
          _b_write_and_exit 1
        fi
        _B_LINES[$_bpos]="- [~] ${_cur:6}"
        _b_tildes=$((_b_tildes+1))
        echo "STARTED  ${_B_LINES[$_bpos]}  ($_B_FILE)"
        ;;
      done)
        case "$_cur" in
          "- [x]"*) echo "Already done"; continue ;;
          "- [ ]"*|"- [~]"*|"- [!]"*) ;;
          *)
            echo "ERROR: cannot mark done from current state: $_cur"
            echo "BATCH stopped at: $bline"
            _b_write_and_exit 1
            ;;
        esac
        case "$_cur" in "- [~]"*) _b_tildes=$((_b_tildes-1)) ;; esac
        _B_LINES[$_bpos]="- [x] ${_cur:6}"
        echo "DONE     ${_B_LINES[$_bpos]}  ($_B_FILE)"
        ;;
      cancel)
        case "$_cur" in "- [~]"*) _b_tildes=$((_b_tildes-1)) ;; esac
        _B_LINES[$_bpos]="- [-] ${_cur:6}"
        if [[ -n "$breason" ]]; then _B_LINES[$_bpos]="${_B_LINES[$_bpos]} — ${breason}"; fi
        echo "CANCEL   ${_B_LINES[$_bpos]}  ($_B_FILE)"
        ;;
      block)
        case "$_cur" in "- [~]"*) _b_tildes=$((_b_tildes-1)) ;; esac
        _B_LINES[$_bpos]="- [!] ${_cur:6}"
        if [[ -n "$breason" ]]; then _B_LINES[$_bpos]="${_B_LINES[$_bpos]} — ${breason}"; fi
        echo "BLOCKED  ${_B_LINES[$_bpos]}  ($_B_FILE)"
        ;;
      reopen)
        case "$_cur" in "- [~]"*) _b_tildes=$((_b_tildes-1)) ;; esac
        _B_LINES[$_bpos]="- [ ] ${_cur:6}"
        echo "REOPENED ${_B_LINES[$_bpos]}  ($_B_FILE)"
        ;;
      *)
        echo "Unknown action: $baction (use start|done|cancel|block|reopen)"
        echo "BATCH stopped at: $bline"
        _b_write_and_exit 1
        ;;
    esac
  done
  _b_write_and_exit 0
fi

DIR="${1:-}"; SPEC="${2:-}"; ACTION="${3:-}"; REASON="${4:-}"
[[ -z "$DIR" || -z "$SPEC" || -z "$ACTION" ]] && {
  sed -n '2,18p' "$0"; exit 1; }

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
if [[ -f "$DIR" ]]; then
  # v1.2.1: direct-file target (T0.5 quick plan via --quick or native path).
  # Section flags are ignored: ALL checkboxes count in file order.
  FILE="$DIR"
elif [[ "$RESOLVED_SECTION" == "acceptance" ]]; then
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
      in_sec && /^- \[.\]( |$)/ {
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
      in_sec && /^- \[.\]( |$)/ && index($0, pattern) {
        print NR; exit
      }
    ' "$FILE")
    [[ -z "$LINE_NO" ]] && { echo "ERROR: no checkbox matching '$SPEC' in ## $TARGET_SECTION of $FILE"; exit 1; }
  fi
else
  if [[ "$SPEC" =~ ^[0-9]+$ ]]; then
    LINE_NO=$(awk -v n="$SPEC" '/^- \[.\]( |$)/{c++; if(c==n){print NR; exit}}' "$FILE")
    [[ -z "$LINE_NO" ]] && { echo "ERROR: checkbox #$SPEC not found in $FILE"; exit 1; }
  else
    LINE_NO=$(grep -nE '^\- \[.\] .*'"$(echo "$SPEC" | sed 's/[][\.*^$/]/\\&/g')" "$FILE" | head -1 | cut -d: -f1 || true)
    [[ -z "$LINE_NO" ]] && { echo "ERROR: no checkbox matching '$SPEC' in $FILE"; exit 1; }
  fi
fi

CURRENT=$(sed -n "${LINE_NO}p" "$FILE")

set_marker() {
  local new="$1"
  sed -i.bak "${LINE_NO}s/^- \\[.\\]\\( \\|$\\)/- [${new}] /" "$FILE"
  rm -f "${FILE}.bak"
}

active_tilde() {
  local f="$1"
  awk '/^- \[~\]( |$)/{c++} END{print c+0}' "$f"
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
