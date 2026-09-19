#!/usr/bin/env bash
# repro-D2.sh — D2: archive.sh flattens nested T3 epic children
set -euo pipefail
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
cp -a .agents "$W/.agents"
cp AGENTS.md "$W/AGENTS.md"
cd "$W"
bash .agents/scripts/bootstrap.sh Repro D2 >/dev/null 2>&1
bash .agents/scripts/new-plan.sh T3 pilot >/dev/null 2>&1
bash .agents/scripts/new-plan.sh T1 01-sub pilot >/dev/null 2>&1
for i in $(seq 1 10); do
  bash .agents/scripts/task.sh plans/pilot/01-sub "$i" cancel x >/dev/null 2>&1 || true
done
bash .agents/scripts/close-plan.sh --force plans/pilot/01-sub >/dev/null 2>&1
printf '%s\n' '# Review' '## Built' '- done' > plans/pilot/01-sub/review.md
echo "Running: archive.sh plans/pilot/01-sub"
bash .agents/scripts/archive.sh plans/pilot/01-sub
echo "exit:$?"
echo "Archive directory contents:"
find plans/_archive -maxdepth 3
