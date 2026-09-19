#!/usr/bin/env bash
# session-log.sh — Append structured entry to plans/SESSION_LOG.md
# Usage: session-log.sh "<title>" "<done>" ["<decisions>"] ["<files>"] ["<resume>"]

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,4p' "$0"
  exit 0
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
{
  echo "## ${TS} — ${TITLE}"
  echo "- Done: ${DONE}"
  [[ -n "$DECISIONS" ]] && echo "- Decisions: ${DECISIONS}"
  [[ -n "$FILES" ]] && echo "- Files: ${FILES}"
  [[ -n "$RESUME" ]] && echo "- Resume: ${RESUME}"
  echo ""
} >> "$LOG"

echo "Appended → ${LOG}"
