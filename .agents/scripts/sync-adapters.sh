#!/usr/bin/env bash
# sync-adapters.sh — Install thin tool adapters + native mirrors.
# Usage:
#   sync-adapters.sh [--force] [--only all|claude,cursor,...]
# Never touches application source or README.md.

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,6p' "$0"
  exit 0
fi

FORCE=0
ONLY="all"
ROOT="$(pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force|-f) FORCE=1; shift ;;
    --only)     ONLY="${2:-all}"; shift 2 ;;
    *)          echo "Unknown: $1"; exit 1 ;;
  esac
done
ONLY="$(echo "$ONLY" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"

want() {
  local key="$1"
  [[ "$ONLY" == "all" ]] && return 0
  [[ "$ONLY" == "none" ]] && return 1
  case ",$ONLY," in
    *,"$key",*) return 0 ;;
    *) return 1 ;;
  esac
}

copy() {
  local src="$1" dst="$2"
  [[ -f "$src" || -d "$src" ]] || return 0
  if [[ -e "$dst" && "$FORCE" -eq 0 ]]; then
    echo "  skip (exists): $dst"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp -R "$src" "$dst"
  echo "  installed: $dst"
}

echo "Root: $ROOT"
echo "Adapters: $ONLY"

# --- Claude Code ---
if want claude; then
  if [[ -f "${ROOT}/adapters/claude/CLAUDE.md" ]]; then
    copy "${ROOT}/adapters/claude/CLAUDE.md" "${ROOT}/CLAUDE.md"
  elif [[ -f "${ROOT}/CLAUDE.md" ]]; then
    : # already present
  else
    printf '%s\n' '@AGENTS.md' '' '> Agent Protocol adapter. Canonical rules in AGENTS.md.' > "${ROOT}/CLAUDE.md"
    echo "  installed: CLAUDE.md (minimal)"
  fi
  if [[ -d "${ROOT}/.agents/skills" ]]; then
    mkdir -p "${ROOT}/.claude/skills"
    for skill_dir in "${ROOT}/.agents/skills"/*/; do
      [[ -d "$skill_dir" ]] || continue
      name=$(basename "$skill_dir")
      mkdir -p "${ROOT}/.claude/skills/${name}"
      [[ -f "${skill_dir}/SKILL.md" ]] && copy "${skill_dir}/SKILL.md" "${ROOT}/.claude/skills/${name}/SKILL.md"
    done
  fi
  if [[ -d "${ROOT}/.agents/agents" ]]; then
    mkdir -p "${ROOT}/.claude/agents"
    for agent_file in "${ROOT}/.agents/agents"/*.md; do
      [[ -f "$agent_file" ]] || continue
      copy "$agent_file" "${ROOT}/.claude/agents/$(basename "$agent_file")"
    done
  fi
fi

# --- Cursor ---
if want cursor && [[ -f "${ROOT}/adapters/cursor/rules.mdc" ]]; then
  mkdir -p "${ROOT}/.cursor/rules"
  copy "${ROOT}/adapters/cursor/rules.mdc" "${ROOT}/.cursor/rules/agent-protocol.mdc"
fi

# --- Copilot ---
if want copilot && [[ -f "${ROOT}/adapters/copilot/copilot-instructions.md" ]]; then
  mkdir -p "${ROOT}/.github"
  copy "${ROOT}/adapters/copilot/copilot-instructions.md" "${ROOT}/.github/copilot-instructions.md"
fi

# --- Windsurf / Devin ---
if want windsurf && [[ -f "${ROOT}/adapters/windsurf/windsurfrules" ]]; then
  copy "${ROOT}/adapters/windsurf/windsurfrules" "${ROOT}/.windsurfrules"
  mkdir -p "${ROOT}/.windsurf/rules" "${ROOT}/.devin/rules"
  copy "${ROOT}/adapters/windsurf/windsurfrules" "${ROOT}/.windsurf/rules/agent-protocol.md"
  copy "${ROOT}/adapters/windsurf/windsurfrules" "${ROOT}/.devin/rules/agent-protocol.md"
fi

# --- Codex ---
if want codex && [[ -d "${ROOT}/.agents/skills" ]]; then
  mkdir -p "${ROOT}/.codex/skills"
  for skill_dir in "${ROOT}/.agents/skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    name=$(basename "$skill_dir")
    mkdir -p "${ROOT}/.codex/skills/${name}"
    [[ -f "${skill_dir}/SKILL.md" ]] && copy "${skill_dir}/SKILL.md" "${ROOT}/.codex/skills/${name}/SKILL.md"
  done
fi

# --- Cline / Roo ---
if want cline && [[ -f "${ROOT}/adapters/cline/clinerules" ]]; then
  copy "${ROOT}/adapters/cline/clinerules" "${ROOT}/.clinerules"
fi
if want roo && [[ -f "${ROOT}/adapters/roo/roorules" ]]; then
  copy "${ROOT}/adapters/roo/roorules" "${ROOT}/.roorules"
fi

# --- Gemini / Antigravity ---
if want gemini; then
  if [[ -f "${ROOT}/adapters/../GEMINI.md" ]]; then
    copy "${ROOT}/GEMINI.md" "${ROOT}/GEMINI.md" 2>/dev/null || true
  fi
  if [[ ! -f "${ROOT}/GEMINI.md" && -f "$(dirname "$0")/../../GEMINI.md" ]]; then
    copy "$(cd "$(dirname "$0")/../.." && pwd)/GEMINI.md" "${ROOT}/GEMINI.md"
  fi
  # package GEMINI may already be copied by init
  [[ -f "${ROOT}/GEMINI.md" ]] && echo "  present: GEMINI.md"
fi

echo ""
echo "Done. AGENTS.md remains the single source of truth."
echo "Re-run with --force to overwrite existing adapter files."
