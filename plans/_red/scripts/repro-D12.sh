#!/usr/bin/env bash
# repro-D12.sh — D12: close-plan ignores OVERVIEW.md open boxes in T3
set -euo pipefail
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
cp -a .agents "$W/.agents"
cp AGENTS.md "$W/AGENTS.md"
cd "$W"
bash .agents/scripts/bootstrap.sh Repro D12 >/dev/null 2>&1
bash .agents/scripts/new-plan.sh T3 epicx >/dev/null 2>&1
echo "Running close-plan on epicx with open OVERVIEW.md tasks:"
bash .agents/scripts/close-plan.sh plans/epicx
echo "exit:$? (BUG: exits 0 without scanning OVERVIEW.md)"
