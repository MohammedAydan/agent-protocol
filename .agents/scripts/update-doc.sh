#!/usr/bin/env bash
# update-doc.sh — Append a structured entry to living docs (ADR / pattern / tech-stack).
# Usage:
#   update-doc.sh adr "Title" "Context" "Decision" ["Alternatives"] ["Consequences"]
#   update-doc.sh pattern "Problem" "Solution" ["Example"] ["Gotchas"]
#   update-doc.sh stack "Layer" "Choice" "Version" "Reason"

set -euo pipefail

KIND="${1:-}"
shift || true

mkdir -p plans

case "$KIND" in
  adr)
    TITLE="${1:-Untitled}"
    CONTEXT="${2:-}"
    DECISION="${3:-}"
    ALTS="${4:-}"
    CONS="${5:-}"
    FILE="plans/DECISIONS.md"
    [[ -f "$FILE" ]] || echo -e "# Architecture Decision Records\n" > "$FILE"
    # next number
    LAST=$(grep -oE 'ADR-[0-9]+' "$FILE" 2>/dev/null | grep -oE '[0-9]+' | sort -n | tail -1 || true)
    NUM=$(( ${LAST:-0} + 1 ))
    PAD=$(printf '%03d' "$NUM")
    {
      echo ""
      echo "### ADR-${PAD} — ${TITLE}"
      echo "Date: $(date -u +%Y-%m-%d)  |  Status: Accepted"
      echo ""
      echo "**Context:** ${CONTEXT}"
      echo ""
      echo "**Decision:** ${DECISION}"
      [[ -n "$ALTS" ]] && echo -e "\n**Alternatives:** ${ALTS}"
      [[ -n "$CONS" ]] && echo -e "\n**Consequences:** ${CONS}"
      echo ""
    } >> "$FILE"
    echo "Appended ADR-${PAD} → ${FILE}"
    ;;
  pattern)
    PROB="${1:-}"
    SOL="${2:-}"
    EX="${3:-}"
    GOT="${4:-}"
    FILE="plans/PATTERNS.md"
    [[ -f "$FILE" ]] || echo -e "# Patterns\n" > "$FILE"
    {
      echo ""
      echo "### $(echo "$PROB" | head -c 60)"
      echo "**Problem:** ${PROB}"
      echo "**Solution:** ${SOL}"
      [[ -n "$EX" ]] && echo "**Example:** ${EX}"
      [[ -n "$GOT" ]] && echo "**Gotchas:** ${GOT}"
      echo ""
    } >> "$FILE"
    echo "Appended pattern → ${FILE}"
    ;;
  stack)
    LAYER="${1:-}"
    CHOICE="${2:-}"
    VER="${3:-}"
    REASON="${4:-}"
    FILE="plans/TECH_STACK.md"
    [[ -f "$FILE" ]] || echo -e "# Tech Stack\n\n| Layer | Choice | Version | Reason |\n|-------|--------|---------|--------|\n" > "$FILE"
    # append row if table exists
    if grep -q '| Layer |' "$FILE" 2>/dev/null; then
      echo "| ${LAYER} | ${CHOICE} | ${VER} | ${REASON} |" >> "$FILE"
    else
      echo "- ${LAYER}: ${CHOICE} ${VER} — ${REASON}" >> "$FILE"
    fi
    echo "Updated stack → ${FILE}"
    ;;
  *)
    echo "Usage:"
    echo "  update-doc.sh adr \"Title\" \"Context\" \"Decision\" [alts] [consequences]"
    echo "  update-doc.sh pattern \"Problem\" \"Solution\" [example] [gotchas]"
    echo "  update-doc.sh stack \"Layer\" \"Choice\" \"Version\" \"Reason\""
    exit 1
    ;;
esac
