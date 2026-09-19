#!/usr/bin/env bash
# repro-D8.sh — D8: dual update path drift (bash vs PowerShell)
set -euo pipefail
pkg="$(cd "$(dirname "$0")/../../.." && pwd)"
ROOT="/tmp/ap-red-d8-repro"
rm -rf "$ROOT"
mkdir -p "$ROOT/seed"
cd "$ROOT/seed"
bash "$pkg/bin/agent-protocol" init --adapters none >/dev/null 2>&1
cp -a "$ROOT/seed" "$ROOT/consumer-u-bash"
cp -a "$ROOT/seed" "$ROOT/consumer-u-ps"

(cd "$ROOT/consumer-u-bash" && bash "$pkg/bin/agent-protocol" update >/dev/null)
(cd "$ROOT/consumer-u-ps" && powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$pkg\bin\agent-protocol.ps1" update >/dev/null)

echo "--- diff between consumers ---"
diff -r "$ROOT/consumer-u-bash" "$ROOT/consumer-u-ps" || echo "exit:$?"
echo "--- file encoding ---"
file "$ROOT/consumer-u-bash/.agents/PROTOCOL_VERSION" "$ROOT/consumer-u-ps/.agents/PROTOCOL_VERSION"
