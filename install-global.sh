#!/usr/bin/env bash
# install-global.sh — Install Agent Protocol CLI globally for the current user.
#
#   curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.sh | bash
#
# Installs to: ~/.local/share/agent-protocol
# Symlink:      ~/.local/bin/agent-protocol
#
set -euo pipefail

OWNER="${AGENT_PROTOCOL_OWNER:-MohammedAydan}"
REPO="${AGENT_PROTOCOL_REPO:-agent-protocol}"
REF="${AGENT_PROTOCOL_REF:-main}"
DEST="${AGENT_PROTOCOL_HOME:-$HOME/.local/share/agent-protocol}"
BIN="${HOME}/.local/bin"

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: need $1"; exit 1; }; }
need curl
need tar
need bash

# If running from a local package checkout, copy it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/AGENTS.md" && -d "$SCRIPT_DIR/.agents/scripts" ]]; then
  echo "=== Local package install ==="
  echo "  from: $SCRIPT_DIR"
  echo "  to  : $DEST"
  mkdir -p "$DEST"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete --exclude '.git' --exclude 'plans' "$SCRIPT_DIR"/ "$DEST"/
  else
    rm -rf "$DEST"
    mkdir -p "$DEST"
    cp -a "$SCRIPT_DIR"/. "$DEST"/
    rm -rf "$DEST/.git" "$DEST/plans" 2>/dev/null || true
  fi
else
  echo "=== Remote install ==="
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  if [[ "$REF" == "main" || "$REF" == "master" ]]; then
    url="https://github.com/${OWNER}/${REPO}/archive/refs/heads/${REF}.tar.gz"
  else
    url="https://github.com/${OWNER}/${REPO}/archive/refs/tags/${REF}.tar.gz"
  fi
  echo "  url: $url"
  curl -fsSL --proto '=https' --tlsv1.2 "$url" -o "$tmp/p.tgz"
  tar -xzf "$tmp/p.tgz" -C "$tmp"
  extracted="$(find "$tmp" -maxdepth 1 -type d -name "${REPO}-*" | head -1)"
  [[ -f "$extracted/AGENTS.md" ]] || { echo "ERROR: invalid archive"; exit 1; }
  mkdir -p "$DEST"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete --exclude '.git' "$extracted"/ "$DEST"/
  else
    rm -rf "${DEST:?}/"*
    cp -a "$extracted"/. "$DEST"/
  fi
fi

mkdir -p "$BIN" "$DEST/bin"
# ensure CLI exists
if [[ ! -f "$DEST/bin/agent-protocol" ]]; then
  echo "ERROR: bin/agent-protocol missing in package"
  exit 1
fi
chmod +x "$DEST/bin/agent-protocol" 2>/dev/null || true
chmod +x "$DEST/.agents/scripts/"*.sh 2>/dev/null || true
ln -sfn "$DEST/bin/agent-protocol" "$BIN/agent-protocol"
echo "1.0.0" > "$DEST/VERSION"

echo ""
echo "=== Installed ==="
echo "  Package: $DEST"
echo "  CLI    : $BIN/agent-protocol"
echo ""
echo "  Add to PATH if needed:"
echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
echo "  Try:"
echo "    agent-protocol version"
echo "    agent-protocol init --here --adapters none"
echo "    agent-protocol update"
echo "    agent-protocol upgrade"
