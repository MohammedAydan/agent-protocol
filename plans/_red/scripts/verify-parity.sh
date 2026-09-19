#!/usr/bin/env bash
set -euo pipefail

PKG="D:/Downloads/agent-protocol/agent-protocol-1.0.0"
PARITY_DIR="/tmp/ap-parity-gate"
rm -rf "$PARITY_DIR"
mkdir -p "$PARITY_DIR"

echo "=== 1. Init Parity (bash vs PS) ==="
mkdir -p "$PARITY_DIR/init-bash" "$PARITY_DIR/init-ps"

(cd "$PARITY_DIR/init-bash" && bash "$PKG/bin/agent-protocol" init --adapters none >/dev/null 2>&1)
(cd "$PARITY_DIR/init-ps" && powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PKG\\bin\\agent-protocol.ps1" init --adapters none >/dev/null 2>&1)

# Compare files excluding timestamps or session-log timestamp if any
# Note: SESSION_LOG.md has timestamps; let's check diff excluding SESSION_LOG.md or comparing files
echo "Comparing init file structures..."
diff -r -x SESSION_LOG.md "$PARITY_DIR/init-bash" "$PARITY_DIR/init-ps"
echo "PASS: Init parity clean (excluding SESSION_LOG.md timestamp)"

echo "=== 2. Update Parity (bash vs PS) ==="
mkdir -p "$PARITY_DIR/seed"
(cd "$PARITY_DIR/seed" && bash "$PKG/bin/agent-protocol" init --adapters none >/dev/null 2>&1)
echo "CUSTOM CONTENT" > "$PARITY_DIR/seed/README.md"
echo "CUSTOM PLAN" > "$PARITY_DIR/seed/plans/custom.txt"

cp -a "$PARITY_DIR/seed" "$PARITY_DIR/update-bash"
cp -a "$PARITY_DIR/seed" "$PARITY_DIR/update-ps"

(cd "$PARITY_DIR/update-bash" && bash "$PKG/bin/agent-protocol" update >/dev/null 2>&1)
(cd "$PARITY_DIR/update-ps" && powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PKG\\bin\\agent-protocol.ps1" update >/dev/null 2>&1)

echo "Comparing update file structures..."
diff -r "$PARITY_DIR/update-bash" "$PARITY_DIR/update-ps"
echo "PASS: Update parity 100% clean (exit 0)"

echo "=== ALL PARITY GATES PASSED ==="
