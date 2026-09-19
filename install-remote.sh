#!/usr/bin/env bash
# install-remote.sh — Bootstrap Agent Protocol from GitHub into a project.
#
# One-liner (this repo):
#   curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/v1.0.0/install-remote.sh \
#     | bash -s -- --here --adapters all --non-interactive
#
# Or latest main:
#   curl -fsSL https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.sh \
#     | bash -s -- --here --adapters all --non-interactive
#
# Safest (review first):
#   git clone --depth 1 --branch v1.0.0 https://github.com/MohammedAydan/agent-protocol.git /tmp/agent-protocol
#   bash /tmp/agent-protocol/init --here --adapters all
#
# Security: HTTPS only; temp extract; never overwrites README or app source.

set -euo pipefail

OWNER="${AGENT_PROTOCOL_OWNER:-MohammedAydan}"
REPO="${AGENT_PROTOCOL_REPO:-agent-protocol}"
REF="${AGENT_PROTOCOL_REF:-main}"
ARCHIVE_URL="${AGENT_PROTOCOL_URL:-}"

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --repo)  REPO="$2"; shift 2 ;;
    --ref)   REF="$2"; shift 2 ;;
    --url)   ARCHIVE_URL="$2"; shift 2 ;;
    *)       ARGS+=("$1"); shift ;;
  esac
done

if [[ -z "$ARCHIVE_URL" ]]; then
  if [[ "$REF" == "main" || "$REF" == "master" ]]; then
    ARCHIVE_URL="https://github.com/${OWNER}/${REPO}/archive/refs/heads/${REF}.tar.gz"
  else
    ARCHIVE_URL="https://github.com/${OWNER}/${REPO}/archive/refs/tags/${REF}.tar.gz"
  fi
fi

case "$ARCHIVE_URL" in
  https://github.com/*|https://codeload.github.com/*) ;;
  *)
    echo "ERROR: only https://github.com/… archives allowed by default."
    exit 1
    ;;
esac

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing: $1"; exit 1; }; }
need_cmd curl
need_cmd tar
need_cmd bash

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "=== Agent Protocol remote install ==="
echo "  repo: ${OWNER}/${REPO}@${REF}"
echo "  url : $ARCHIVE_URL"
echo "  args: ${ARGS[*]:---here}"

ARCHIVE="$TMP/protocol.tgz"
download() {
  curl -fsSL --proto '=https' --tlsv1.2 "$1" -o "$ARCHIVE"
}

if ! download "$ARCHIVE_URL"; then
  # Tag missing → try main
  ARCHIVE_URL="https://github.com/${OWNER}/${REPO}/archive/refs/heads/main.tar.gz"
  echo "  tag not found; trying main: $ARCHIVE_URL"
  download "$ARCHIVE_URL"
fi

[[ -s "$ARCHIVE" ]] || { echo "ERROR: empty download"; exit 1; }

tar -xzf "$ARCHIVE" -C "$TMP"
PKG="$(find "$TMP" -maxdepth 1 -type d -name "${REPO}-*" 2>/dev/null | head -1)"
[[ -d "$PKG" ]] || PKG="$(find "$TMP" -maxdepth 1 -type d ! -path "$TMP" | head -1)"
[[ -f "$PKG/AGENTS.md" && -f "$PKG/.agents/scripts/init.sh" ]] || {
  echo "ERROR: archive is not a valid Agent Protocol package"
  exit 1
}

echo "  package: $PKG"
bash "$PKG/.agents/scripts/init.sh" "${ARGS[@]:---here}"
