#!/usr/bin/env bash
# install-remote.sh — Bootstrap Agent Protocol from GitHub into the current (or target) project.
#
# Recommended (pinned tag):
#   curl -fsSL https://raw.githubusercontent.com/<OWNER>/<REPO>/v1.0.0/install-remote.sh \
#     | bash -s -- --here --adapters all
#
# Or clone then init (safest — review code first):
#   git clone --depth 1 --branch v1.0.0 https://github.com/<OWNER>/<REPO>.git /tmp/agent-protocol
#   bash /tmp/agent-protocol/init --here --adapters all
#
# Security:
# - HTTPS only
# - Extracts to a temp dir, runs local init.sh (does not eval remote beyond this script)
# - Never overwrites README.md or application source
# - Refuses system paths
# - Prefer pinning a tag via AGENT_PROTOCOL_REF (default: v1.0.0)

set -euo pipefail

OWNER="${AGENT_PROTOCOL_OWNER:-}"
REPO="${AGENT_PROTOCOL_REPO:-agent-protocol}"
REF="${AGENT_PROTOCOL_REF:-v1.0.0}"

# Allow override of full archive URL (e.g. release asset)
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
  if [[ -z "$OWNER" ]]; then
    echo "ERROR: set AGENT_PROTOCOL_OWNER or pass --owner <github-user-or-org>"
    echo "Example:"
    echo "  AGENT_PROTOCOL_OWNER=myorg curl -fsSL …/install-remote.sh | bash -s -- --here"
    exit 1
  fi
  # GitHub archive of tag/branch
  ARCHIVE_URL="https://github.com/${OWNER}/${REPO}/archive/refs/tags/${REF}.tar.gz"
  # fallback tried later if tag missing: heads/main
fi

# Block clearly dangerous patterns in URL
case "$ARCHIVE_URL" in
  https://github.com/*|https://codeload.github.com/*) ;;
  *)
    echo "ERROR: only https://github.com/… archives are allowed by default."
    echo "  Set AGENT_PROTOCOL_URL only if you trust the source."
    exit 1
    ;;
esac

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing command: $1"; exit 1; }; }
need_cmd curl
need_cmd tar
need_cmd bash

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "=== Agent Protocol remote install ==="
echo "  url: $ARCHIVE_URL"
echo "  args: ${ARGS[*]:---here}"

ARCHIVE="$TMP/protocol.tgz"
if ! curl -fsSL --proto '=https' --tlsv1.2 "$ARCHIVE_URL" -o "$ARCHIVE"; then
  # try branch main if tag failed
  if [[ -n "$OWNER" ]]; then
    ARCHIVE_URL="https://github.com/${OWNER}/${REPO}/archive/refs/heads/main.tar.gz"
    echo "  tag fetch failed; trying $ARCHIVE_URL"
    curl -fsSL --proto '=https' --tlsv1.2 "$ARCHIVE_URL" -o "$ARCHIVE"
  else
    exit 1
  fi
fi

# Basic sanity: non-empty
[[ -s "$ARCHIVE" ]] || { echo "ERROR: empty download"; exit 1; }

tar -xzf "$ARCHIVE" -C "$TMP"
# GitHub archives extract to <repo>-<ref>/
PKG="$(find "$TMP" -maxdepth 1 -type d -name "${REPO}-*" | head -1)"
[[ -d "$PKG" ]] || PKG="$(find "$TMP" -maxdepth 1 -type d ! -path "$TMP" | head -1)"
[[ -f "$PKG/AGENTS.md" && -f "$PKG/.agents/scripts/init.sh" ]] || {
  echo "ERROR: downloaded archive is not a valid Agent Protocol package"
  exit 1
}

echo "  package: $PKG"
bash "$PKG/.agents/scripts/init.sh" "${ARGS[@]:---here}"
