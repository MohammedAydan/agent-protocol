#!/usr/bin/env bash
# doctor.sh — Self-audit plans/ structure against protocol rules.
# Usage: doctor.sh [--ascii]
# Exit 0 = healthy, 1 = issues found.
# Portable: no process substitution. Skips plans/_archive/ for plan-structure checks.

set -euo pipefail

ASCII=0
for arg in "$@"; do
  case "$arg" in
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    --ascii) ASCII=1 ;;
  esac
done

ISSUES=0
if [[ "$ASCII" -eq 1 ]]; then
  warn() { echo "[WARN] $1"; ISSUES=$((ISSUES + 1)); }
  ok()   { echo "[OK]   $1"; }
else
  warn() { echo "⚠  $1"; ISSUES=$((ISSUES + 1)); }
  ok()   { echo "✓  $1"; }
fi

echo "=== Agent Protocol doctor ==="
echo ""

for f in context.md SESSION_LOG.md ARCH.md TECH_STACK.md DECISIONS.md PATTERNS.md; do
  if [[ -f "plans/$f" ]]; then
    ok "plans/$f exists"
  else
    warn "missing plans/$f (run bootstrap.sh)"
  fi
done

echo ""

if [[ ! -d plans ]]; then
  warn "no plans/ directory"
  echo ""
  echo "Issues: $ISSUES"
  exit 1
fi

tmp=$(mktemp)
find plans -type d -not -path '*/_archive*' 2>/dev/null > "$tmp" || true
while IFS= read -r dir; do
  [[ -z "$dir" ]] && continue
  rel="${dir#plans/}"
  [[ -z "$rel" || "$rel" == "$dir" ]] && continue

  has_plan=0; has_overview=0; has_tasks=0; has_context=0
  [[ -f "${dir}/plan.md" ]] && has_plan=1
  [[ -f "${dir}/OVERVIEW.md" ]] && has_overview=1
  [[ -f "${dir}/tasks.md" ]] && has_tasks=1
  [[ -f "${dir}/context.md" ]] && has_context=1

  if [[ $has_plan -eq 0 && $has_overview -eq 0 ]]; then
    continue
  fi

  if [[ $has_overview -eq 1 ]]; then
    ok "T3 epic: $rel"
  elif [[ $has_tasks -eq 1 && $has_context -eq 1 && $has_plan -eq 1 ]]; then
    ok "T2 plan: $rel"
  elif [[ $has_plan -eq 1 && $has_tasks -eq 0 ]]; then
    ok "T1 plan: $rel"
  elif [[ $has_plan -eq 1 && $has_tasks -eq 1 && $has_context -eq 0 ]]; then
    warn "$rel looks T2-ish but missing context.md"
  else
    warn "$rel has unexpected file mix (plan=$has_plan tasks=$has_tasks context=$has_context overview=$has_overview)"
  fi

  for f in "${dir}/tasks.md" "${dir}/plan.md"; do
    if [[ -f "$f" ]]; then
      n=$(grep -cE '^\- \[~\]' "$f" 2>/dev/null || true)
      n=${n:-0}
      if [[ "$n" -gt 1 ]]; then
        warn "$rel has $n in-progress [~] tasks (max 1 allowed)"
      fi
    fi
  done

  for f in "${dir}/plan.md" "${dir}/OVERVIEW.md"; do
    [[ -f "$f" ]] || continue
    lc=$(wc -l < "$f" | tr -d ' ')
    if [[ "$lc" -gt 80 ]]; then
      warn "$rel/$(basename "$f") = ${lc} lines (>80 = over-planning; split or implement)"
    fi
  done

  if [[ -f "${dir}/tasks.md" ]] && ! grep -qE '^\- \[.\]' "${dir}/tasks.md"; then
    warn "$rel/tasks.md has no checkboxes (empty or malformed)"
  fi

  # Closed plan still outside _archive without review.md is fine; with review.md suggest archive
  if [[ -f "${dir}/review.md" ]]; then
    open_left=0
    for f in "${dir}/tasks.md" "${dir}/plan.md"; do
      if [[ -f "$f" ]] && grep -qE '^\- \[ \]|^\- \[~\]' "$f" 2>/dev/null; then
        open_left=1
      fi
    done
    if [[ "$open_left" -eq 0 ]]; then
      ok "$rel has review.md (candidate for archive.sh)"
      # empty stub? Built section still blank
      if grep -qE '^## Built' "${dir}/review.md" 2>/dev/null; then
        built_body=$(awk '/^## Built/{f=1;next} /^## /{f=0} f' "${dir}/review.md" | sed '/^$/d' | sed 's/^[- ]*//' | grep -v '^$' || true)
        if [[ -z "$built_body" ]]; then
          warn "$rel/review.md looks empty (fill Built/Edge cases before archive or accept as stub)"
        fi
      fi
    fi
  fi
done < "$tmp"
rm -f "$tmp"

echo ""
if [[ -f AGENTS.md ]]; then
  ok "AGENTS.md present (canonical)"
else
  warn "AGENTS.md missing at repo root"
fi

if [[ -f CLAUDE.md ]]; then
  if grep -q 'AGENTS.md' CLAUDE.md 2>/dev/null; then
    ok "CLAUDE.md bridges to AGENTS.md"
  else
    warn "CLAUDE.md does not reference AGENTS.md"
  fi
fi

if [[ -f plans/context.md ]]; then
  tmp_ap=$(mktemp)
  awk -F: '/^Active Plans:/{print $2}' plans/context.md | tr ',' '\n' | sed 's/^ *//; s/ *$//' > "$tmp_ap" || true
  while IFS= read -r entry; do
    [[ -z "$entry" || "$entry" == "none" || "$entry" == "TBD" ]] && continue
    short="${entry#plans/}"
    if [[ ! -d "plans/${short}" && ! -d "plans/_archive/${short}" && ! -d "plans/_archive/$(basename "${short}")" ]]; then
      warn "Active Plans mentions '${entry}' but no such plan folder"
    fi
  done < "$tmp_ap"
  rm -f "$tmp_ap"
fi

# Orphan check: plan folders not listed in Active Plans (informational only if Active Plans is not "none")
if [[ -f plans/context.md ]]; then
  ap_line=$(grep -E '^Active Plans:' plans/context.md | head -1 || true)
  if [[ -n "$ap_line" && "$ap_line" != *"none"* && "$ap_line" != *"TBD"* ]]; then
    tmp2=$(mktemp)
    find plans -mindepth 1 -maxdepth 1 -type d -not -path '*/_archive*' 2>/dev/null > "$tmp2" || true
    while IFS= read -r dir; do
      [[ -z "$dir" ]] && continue
      name=$(basename "$dir")
      [[ -f "${dir}/plan.md" || -f "${dir}/OVERVIEW.md" ]] || continue
      if ! echo "$ap_line" | grep -qw "$name"; then
        warn "plan folder '$name' exists but not listed in Active Plans"
      fi
    done < "$tmp2"
    rm -f "$tmp2"
  fi
fi

echo ""
if [[ "$ISSUES" -eq 0 ]]; then
  echo "All checks passed."
  exit 0
else
  echo "Issues found: $ISSUES"
  exit 1
fi
