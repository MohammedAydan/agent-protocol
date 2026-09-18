#!/usr/bin/env bash
# init.sh — Add Agent Protocol to any project (new or existing).
#
# Never replaces your README.md, package.json, source, or other app files.
# Only installs protocol-owned paths: AGENTS.md, CLAUDE.md, GEMINI.md, .agents/, adapters/.
#
# Usage:
#   init.sh --here
#   init.sh --here --force
#   init.sh --here --adapters all
#   init.sh --here --adapters claude,cursor
#   init.sh --here --adapters none
#   init.sh /path/to/repo --name "App" --purpose "…"
#   init.sh --here --non-interactive --adapters all
#
# --force     overwrite protocol-owned files only (never README or app code)
# --adapters  all | none | comma list: claude,cursor,copilot,windsurf,cline,roo,codex,gemini
# Without --adapters on a TTY: interactive menu. Non-TTY default: all.

set -euo pipefail

HERE=0
FORCE=0
TARGET=""
NAME=""
PURPOSE=""
ADAPTERS_SPEC=""
NON_INTERACTIVE=0

usage() {
  cat <<'U'
Usage: init.sh [target|--here] [options]

  --here              Install into current directory
  --force             Overwrite protocol files only (AGENTS.md, .agents, adapters, …)
  --name NAME         Project name for plans/context.md
  --purpose TEXT      Short purpose for plans/context.md
  --adapters LIST     all | none | claude,cursor,copilot,windsurf,cline,roo,codex,gemini
  --non-interactive   No prompts (default adapters=all if not set)
  -h, --help          Show help

Never modifies: README.md, CHANGELOG.md, package.json, source trees, .git, …
U
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --here|.)            HERE=1; shift ;;
    --force|-f)          FORCE=1; shift ;;
    --name)              NAME="${2:-}"; shift 2 ;;
    --purpose)           PURPOSE="${2:-}"; shift 2 ;;
    --adapters)          ADAPTERS_SPEC="${2:-}"; shift 2 ;;
    --non-interactive)   NON_INTERACTIVE=1; shift ;;
    -h|--help)           usage ;;
    -*)                  echo "Unknown option: $1"; usage ;;
    *)                   TARGET="$1"; shift ;;
  esac
done

if [[ "$HERE" -eq 1 || -z "${TARGET:-}" ]]; then
  TARGET="$(pwd)"
fi
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || { echo "ERROR: not a directory: ${TARGET:-}"; exit 1; }

# Safety: refuse filesystem roots unless forced via env (extreme)
case "$TARGET" in
  /|/usr|/bin|/etc|/var|/home|/root)
    echo "ERROR: refusing to install into system path: $TARGET"
    exit 1
    ;;
esac

NAME="${NAME:-$(basename "$TARGET")}"
PURPOSE="${PURPOSE:-TBD}"
SRC="$(cd "$(dirname "$0")/../.." && pwd)"
[[ -f "$SRC/AGENTS.md" ]] || { echo "ERROR: protocol package incomplete at $SRC (missing AGENTS.md)"; exit 1; }

# --- Adapter selection ---
pick_adapters() {
  if [[ -n "$ADAPTERS_SPEC" ]]; then
    echo "$ADAPTERS_SPEC"
    return
  fi
  if [[ "$NON_INTERACTIVE" -eq 1 ]] || [[ ! -t 0 ]]; then
    echo "all"
    return
  fi
  echo "" >&2
  echo "Which AI harness adapters to install?" >&2
  echo "  1) All (recommended)" >&2
  echo "  2) None (AGENTS.md only — universal readers still work)" >&2
  echo "  3) Claude Code" >&2
  echo "  4) Cursor" >&2
  echo "  5) GitHub Copilot" >&2
  echo "  6) Windsurf / Devin" >&2
  echo "  7) Cline" >&2
  echo "  8) Roo" >&2
  echo "  9) Codex CLI" >&2
  echo " 10) Gemini / Antigravity" >&2
  echo " 11) Custom comma-list (e.g. claude,cursor)" >&2
  echo -n "Choice [1]: " >&2
  read -r choice || choice=1
  case "${choice:-1}" in
    1|"")  echo "all" ;;
    2)     echo "none" ;;
    3)     echo "claude" ;;
    4)     echo "cursor" ;;
    5)     echo "copilot" ;;
    6)     echo "windsurf" ;;
    7)     echo "cline" ;;
    8)     echo "roo" ;;
    9)     echo "codex" ;;
    10)    echo "gemini" ;;
    11)    echo -n "Enter list: " >&2; read -r custom; echo "${custom:-none}" ;;
    *)     echo "all" ;;
  esac
}

ADAPTERS_SPEC="$(pick_adapters)"
# normalize
ADAPTERS_SPEC="$(echo "$ADAPTERS_SPEC" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"

echo "=== Agent Protocol init ==="
echo "  target   : $TARGET"
echo "  name     : $NAME"
echo "  force    : $FORCE"
echo "  adapters : $ADAPTERS_SPEC"
echo ""

# Already installed?
if [[ "$FORCE" -eq 0 && ( -f "$TARGET/AGENTS.md" || -d "$TARGET/.agents" ) ]]; then
  echo "Protocol already present (AGENTS.md or .agents/)."
  echo "  Refresh protocol files:  re-run with --force"
  echo "  Adapters only:           bash .agents/scripts/sync-adapters.sh --only $ADAPTERS_SPEC"
  if [[ ! -f "$TARGET/plans/context.md" ]]; then
    if [[ -f "$TARGET/.agents/scripts/bootstrap.sh" ]]; then
      ( cd "$TARGET" && bash .agents/scripts/bootstrap.sh "$NAME" "$PURPOSE" )
    fi
  else
    echo "  plans/ OK — nothing to overwrite."
  fi
  echo "Done (safe no-overwrite mode)."
  exit 0
fi

# Copy only protocol-owned items — NEVER README.md / CHANGELOG.md / app files
copy_item() {
  local item="$1"
  local src="$SRC/$item"
  local dst="$TARGET/$item"
  [[ -e "$src" ]] || return 0
  if [[ -e "$dst" && "$FORCE" -eq 0 ]]; then
    echo "  skip (exists): $item"
    return 0
  fi
  if [[ -d "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    cp -R "$src" "$dst"
  else
    cp "$src" "$dst"
  fi
  echo "  installed: $item"
}

echo "Installing protocol files (app README and source untouched)…"
copy_item AGENTS.md
# CLAUDE.md / GEMINI.md only if those adapters requested or all
case ",$ADAPTERS_SPEC," in
  *,all,*|*,claude,*|*,gemini,*)
    case ",$ADAPTERS_SPEC," in
      *,all,*|*,claude,*) copy_item CLAUDE.md ;;
    esac
    case ",$ADAPTERS_SPEC," in
      *,all,*|*,gemini,*) copy_item GEMINI.md ;;
    esac
    ;;
esac
# If none/specific without claude/gemini, still ok — AGENTS.md is enough for most tools
copy_item .agents
# adapters/ templates always available for later sync; small
copy_item adapters

printf '%s\n' "1.0.0" > "$TARGET/.agents/PROTOCOL_VERSION"
echo "  installed: .agents/PROTOCOL_VERSION"

chmod +x "$TARGET/.agents/scripts/"*.sh 2>/dev/null || true

echo ""
echo "Bootstrapping plans/ (skip existing files)…"
( cd "$TARGET" && bash .agents/scripts/bootstrap.sh "$NAME" "$PURPOSE" )

if [[ "$ADAPTERS_SPEC" != "none" ]]; then
  echo ""
  echo "Syncing adapters: $ADAPTERS_SPEC"
  ( cd "$TARGET" && bash .agents/scripts/sync-adapters.sh --only "$ADAPTERS_SPEC" ${FORCE:+--force} )
else
  echo ""
  echo "Adapters skipped (AGENTS.md still works with native AGENTS.md readers)."
fi

echo ""
echo "=== Ready ==="
echo "  Your README.md and application files were not modified."
echo "  AGENTS.md  → rules for AI agents"
echo "  plans/     → project brain"
echo "  .agents/   → scripts + skills"
echo ""
echo "Next:"
echo "  bash .agents/scripts/resume.sh"
echo "  bash .agents/scripts/protocol.sh new T1 <feature>"
