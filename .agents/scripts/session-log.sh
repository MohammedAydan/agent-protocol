#!/usr/bin/env bash
# session-log.sh — Append structured entry to plans/SESSION_LOG.md
# Usage: session-log.sh "<title>" "<done>" ["<decisions>"] ["<files>"] ["<resume>"]
#        session-log.sh --brief "<one-line note>"   # T0.5: single-line entry, no ceremony

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,5p' "$0"
  exit 0
fi

BRIEF=0
if [[ "${1:-}" == "--brief" ]]; then
  BRIEF=1
  shift
fi

TITLE="${1:-Untitled}"
DONE="${2:-}"
DECISIONS="${3:-}"
FILES="${4:-}"
RESUME="${5:-}"

mkdir -p plans
LOG="plans/SESSION_LOG.md"
[[ -f "$LOG" ]] || echo -e "# Session Log\n" > "$LOG"

TS=$(date -u +"%Y-%m-%d %H:%M UTC")
if [[ "$BRIEF" -eq 1 ]]; then
  echo "- ${TS} ${TITLE}" >> "$LOG"
  echo "Appended (brief) → ${LOG}: ${TITLE}"
  exit 0
fi
{
  echo "## ${TS} — ${TITLE}"
  echo "## ${TS} — ${TITLE}"
  echo "- Done: ${DONE}"
  [[ -n "$DECISIONS" ]] && echo "- Decisions: ${DECISIONS}"
  [[ -n "$FILES" ]] && echo "- Files: ${FILES}"
  [[ -n "$RESUME" ]] && echo "- Resume: ${RESUME}"
  echo ""
} >> "$LOG"

echo "Appended → ${LOG}"
