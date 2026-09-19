#!/usr/bin/env bash
# update-project.sh — Refresh protocol files in a project from a package root.
# Never deletes plans/ or app source.
#
# Usage:
#   update-project.sh [--from /path/to/package] [--force] [--adapters list] [target]
#   update-project.sh --here
#
# Package source resolution (first hit wins):
#   1) --from PATH
#   2) $AGENT_PROTOCOL_HOME
#   3) directory containing this script's package (../../ from scripts if it has AGENTS.md
#      AND is not the same as target)
#   4) ~/.local/share/agent-protocol

set -euo pipefail

FROM=""
FORCE=0
HERE=0
TARGET=""
ADAPTERS_SPEC="${AP_ADAPTERS:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from) FROM="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --here) HERE=1; shift ;;
    --adapters) ADAPTERS_SPEC="$2"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [[ "$HERE" -eq 1 || -z "${TARGET}" ]]; then
  TARGET="$(pwd)"
fi
TARGET="$(cd "$TARGET" && pwd)"

is_pkg() { [[ -f "$1/AGENTS.md" && -d "$1/.agents/scripts" ]]; }

resolve_from() {
  if [[ -n "$FROM" ]]; then
    echo "$FROM"; return
  fi
  if [[ -n "${AGENT_PROTOCOL_HOME:-}" ]] && is_pkg "$AGENT_PROTOCOL_HOME"; then
    echo "$AGENT_PROTOCOL_HOME"; return
  fi
  local self_pkg
  self_pkg="$(cd "$(dirname "$0")/../.." && pwd)"
  if is_pkg "$self_pkg" && [[ "$self_pkg" != "$TARGET" ]]; then
    echo "$self_pkg"; return
  fi
  local home="${HOME}/.local/share/agent-protocol"
  if is_pkg "$home"; then
    echo "$home"; return
  fi
  # last resort: self_pkg even if same (will no-op copy carefully)
  echo "$self_pkg"
}

PKG="$(cd "$(resolve_from)" && pwd)"

if ! is_pkg "$PKG"; then
  echo "ERROR: package not found (AGENTS.md + .agents/scripts)."
  echo "  Install global: bash install-global.sh"
  echo "  Or set AGENT_PROTOCOL_HOME"
  exit 1
fi

if [[ "$PKG" == "$TARGET" ]]; then
  echo "ERROR: package path equals project path — refusing self-copy."
  echo "  Install global CLI first: curl …/install-global.sh | bash"
  echo "  Then: agent-protocol update"
  exit 1
fi

if [[ ! -f "$TARGET/AGENTS.md" && ! -d "$TARGET/.agents" ]]; then
  echo "ERROR: $TARGET is not an Agent Protocol project."
  echo "  Use: agent-protocol init --here"
  exit 1
fi

echo "=== Update protocol in project ==="
echo "  package: $PKG"
echo "  target : $TARGET"
echo "  force  : $FORCE"

copy_file() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] || return 0
  mkdir -p "$(dirname "$dst")"
  if [[ -f "$dst" && "$FORCE" -eq 0 ]]; then
    # For core protocol files we still refresh AGENTS + scripts even without force
    return 0
  fi
  cp -a "$src" "$dst"
  echo "  + ${dst#$TARGET/}"
}

# Always refresh these (safe; plans/ never touched)
cp -a "$PKG/AGENTS.md" "$TARGET/AGENTS.md"
echo "  + AGENTS.md"
mkdir -p "$TARGET/.agents/scripts"
cp -a "$PKG/.agents/scripts"/. "$TARGET/.agents/scripts"/
echo "  + .agents/scripts/"
for sub in skills agents rules templates; do
  if [[ -d "$PKG/.agents/$sub" ]]; then
    mkdir -p "$TARGET/.agents/$sub"
    cp -a "$PKG/.agents/$sub"/. "$TARGET/.agents/$sub"/
    echo "  + .agents/$sub/"
  fi
done
echo "1.1.0" > "$TARGET/.agents/PROTOCOL_VERSION"

if [[ "$FORCE" -eq 1 ]]; then
  if [[ -d "$PKG/adapters" ]]; then
    mkdir -p "$TARGET/adapters"
    cp -a "$PKG/adapters"/. "$TARGET/adapters"/
    echo "  + adapters/"
  fi
  [[ -f "$PKG/CLAUDE.md" ]] && cp -a "$PKG/CLAUDE.md" "$TARGET/CLAUDE.md" && echo "  + CLAUDE.md"
  [[ -f "$PKG/GEMINI.md" ]] && cp -a "$PKG/GEMINI.md" "$TARGET/GEMINI.md" && echo "  + GEMINI.md"
fi

echo "  keep: plans/ (untouched)"

if [[ -n "$ADAPTERS_SPEC" ]]; then
  (
    cd "$TARGET"
    bash .agents/scripts/sync-adapters.sh --only "$ADAPTERS_SPEC" 2>/dev/null || true
  )
fi

echo "=== Project protocol updated ==="
