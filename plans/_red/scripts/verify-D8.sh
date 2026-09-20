#!/usr/bin/env bash
set -euo pipefail
pkg="D:/Downloads/agent-protocol/agent-protocol-1.0.0"
ROOT="/tmp/ap-d8-verify"
rm -rf "$ROOT"
mkdir -p "$ROOT/seed"
cd "$ROOT/seed"
bash "$pkg/bin/agent-protocol" init --adapters none >/dev/null 2>&1
echo "MY CUSTOM README" > README.md
echo "MY CUSTOM PLAN FILE" > plans/my-plan.txt
cp -a "$ROOT/seed" "$ROOT/consumer-bash"
cp -a "$ROOT/seed" "$ROOT/consumer-ps"

(cd "$ROOT/consumer-bash" && bash "$pkg/bin/agent-protocol" update >/dev/null)
(cd "$ROOT/consumer-ps" && powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$pkg\\bin\\agent-protocol.ps1" update >/dev/null)

echo "--- diff -r output ---"
diff -r "$ROOT/consumer-bash" "$ROOT/consumer-ps" && echo "CLEAN PARITY (exit 0)"

echo "--- decoy README check ---"
grep "MY CUSTOM README" "$ROOT/consumer-bash/README.md"
grep "MY CUSTOM README" "$ROOT/consumer-ps/README.md"

echo "--- plans/ untouched check ---"
grep "MY CUSTOM PLAN FILE" "$ROOT/consumer-bash/plans/my-plan.txt"
grep "MY CUSTOM PLAN FILE" "$ROOT/consumer-ps/plans/my-plan.txt"

echo "--- doctor check ---"
(cd "$ROOT/consumer-bash" && bash .agents/scripts/doctor.sh)
(cd "$ROOT/consumer-ps" && bash .agents/scripts/doctor.sh)
echo "ALL CHECKS PASSED"
