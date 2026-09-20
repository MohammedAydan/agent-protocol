#!/usr/bin/env bash
# bootstrap.sh — Minimal plans/ brain for a new project.
# Usage: bootstrap.sh ["Project Name"] ["Short purpose"]
# Safe to re-run (skips existing files).

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,5p' "$0"
  exit 0
fi

NAME="${1:-New Project}"
PURPOSE="${2:-TBD}"
ROOT="plans"
mkdir -p "$ROOT"

create() {
  local f="$1" c="$2"
  if [[ -f "$f" ]]; then echo "exists: $f"; else printf '%s\n' "$c" > "$f"; echo "created: $f"; fi
}

create "$ROOT/context.md" "# Project Context

Purpose: ${PURPOSE}
Current Status: Bootstrapped
Critical Constraints: TBD
Active Plans: none
Known Issues: none
"

create "$ROOT/ARCH.md" "# Architecture

## High-level
TBD

## Key modules
TBD
"

create "$ROOT/TECH_STACK.md" "# Tech Stack

| Layer | Choice | Version | Reason |
|-------|--------|---------|--------|
| Language | TBD |  |  |
| Framework | TBD |  |  |
| DB | TBD |  |  |
| Testing | TBD |  |  |
"

create "$ROOT/DECISIONS.md" "# Architecture Decision Records

<!-- ADR-NNN: Date / Status / Context / Decision / Alternatives / Consequences -->
"

create "$ROOT/PATTERNS.md" "# Patterns

<!-- Problem / Solution / Example / Gotchas -->
"

if [[ ! -f "$ROOT/SESSION_LOG.md" ]]; then
  cat > "$ROOT/SESSION_LOG.md" <<EOF
# Session Log

## $(date -u +"%Y-%m-%d %H:%M UTC") — Bootstrap
- Done: Created initial plans/ brain
- Decisions: none yet
- Files: context ARCH TECH_STACK DECISIONS PATTERNS SESSION_LOG
- Resume: classify first work (T0–T3) then start
EOF
  echo "created: $ROOT/SESSION_LOG.md"
else
  echo "exists: $ROOT/SESSION_LOG.md"
fi

echo ""
echo "Bootstrap complete: ${NAME}"
echo "Next: .agents/scripts/new-plan.sh T1|T2|T3 <name>"
