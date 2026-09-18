#!/usr/bin/env bash
# install.sh — backward-compatible alias → init.sh --force
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-}"; NAME="${2:-}"; PURPOSE="${3:-}"
[[ -z "$TARGET" ]] && { echo "Usage: install.sh <target> [name] [purpose]"; echo "Prefer: init.sh --here [--adapters all]"; exit 1; }
args=("$TARGET" --force --non-interactive --adapters all)
[[ -n "$NAME" ]] && args+=(--name "$NAME")
[[ -n "$PURPOSE" ]] && args+=(--purpose "$PURPOSE")
exec bash "$D/init.sh" "${args[@]}"
