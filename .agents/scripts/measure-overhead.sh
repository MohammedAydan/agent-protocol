#!/usr/bin/env bash
# measure-overhead.sh — Token-proxy audit for one plan folder.
# Usage: measure-overhead.sh <plan-folder>
# Prints one line: [measure] plan=<name> bytes=<N> files=<M> span_s=<T> taskrefs=<R>
#   bytes    = total bytes of all files under the folder (token proxy)
#   files    = file count under the folder
#   span_s   = wall-clock seconds from oldest to newest mtime in the folder
#   taskrefs = task.sh mentions in plans/SESSION_LOG.md (0 when unlogged)

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,7p' "$0"
  exit 0
fi

DIR="${1:-}"
[[ -z "$DIR" || ! -d "$DIR" ]] && { echo "Usage: measure-overhead.sh <plan-folder>"; exit 1; }

bytes=$(find "$DIR" -type f -exec wc -c {} + 2>/dev/null | awk '{s+=$1} END{print s+0}')
files=$(find "$DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
span=$(find "$DIR" -type f -printf '%T@\n' 2>/dev/null | awk 'NR==1{min=max=$1} {if($1<min)min=$1; if($1>max)max=$1} END{printf "%d", (NR ? max-min : 0)}')
refs=0
if [[ -f plans/SESSION_LOG.md ]]; then
  refs=$(grep -c -E 'task\.sh|task start|task done' plans/SESSION_LOG.md 2>/dev/null || true)
  refs=${refs:-0}
fi

echo "[measure] plan=$(basename "$DIR") bytes=${bytes} files=${files} span_s=${span} taskrefs=${refs}"
