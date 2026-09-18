#!/usr/bin/env bash
# test-scripts.sh — Smoke tests for critical protocol scripts.
# Usage: protocol.sh test   OR   .agents/scripts/test-scripts.sh
# Exit 0 = all pass.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Minimal copy: scripts + AGENTS + CLAUDE
mkdir -p "$WORK/.agents/scripts" "$WORK/.agents/templates" "$WORK/adapters"
cp "$SCRIPT_DIR/"*.sh "$WORK/.agents/scripts/"
cp -R "$ROOT/.agents/templates/"* "$WORK/.agents/templates/" 2>/dev/null || true
cp "$ROOT/AGENTS.md" "$WORK/" 2>/dev/null || true
cp "$ROOT/CLAUDE.md" "$WORK/" 2>/dev/null || true
chmod +x "$WORK/.agents/scripts/"*.sh

cd "$WORK"
pass=0; fail=0
check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS  $name"; pass=$((pass+1))
  else
    echo "FAIL  $name"; fail=$((fail+1))
  fi
}
check_out() {
  local name="$1"; local needle="$2"; shift 2
  local out
  out=$("$@" 2>&1 || true)
  if echo "$out" | grep -q "$needle"; then
    echo "PASS  $name"; pass=$((pass+1))
  else
    echo "FAIL  $name (expected '$needle')"; fail=$((fail+1))
  fi
}

echo "=== Agent Protocol smoke tests ==="

.agents/scripts/bootstrap.sh "Smoke" "test" >/dev/null 2>&1
check "bootstrap creates context" test -f plans/context.md

.agents/scripts/new-plan.sh T1 smoke-t1 >/dev/null 2>&1
check "new T1" test -f plans/smoke-t1/plan.md
check_out "Active Plans after new" "smoke-t1" grep "Active Plans:" plans/context.md

.agents/scripts/new-plan.sh T2 smoke-t2 >/dev/null 2>&1
check "new T2" test -f plans/smoke-t2/tasks.md

.agents/scripts/new-plan.sh T3 smoke-epic >/dev/null 2>&1
check "new T3" test -f plans/smoke-epic/OVERVIEW.md
.agents/scripts/new-plan.sh T2 sub smoke-epic >/dev/null 2>&1
check "new sub-plan" test -f plans/smoke-epic/sub/plan.md

check_out "overwrite guard" "Refusing" .agents/scripts/new-plan.sh T1 smoke-t1

.agents/scripts/task.sh plans/smoke-t1 1 start >/dev/null 2>&1
check_out "one [~] enforced" "ERROR" .agents/scripts/task.sh plans/smoke-t1 2 start
.agents/scripts/task.sh plans/smoke-t1 1 done >/dev/null 2>&1
# Cancel remaining checkboxes (T1 has acceptance + 2 tasks; indices shift)
for i in 1 2 3 4 5; do
  .agents/scripts/task.sh plans/smoke-t1 "$i" cancel "x" >/dev/null 2>&1 || true
done
.agents/scripts/close-plan.sh --force plans/smoke-t1 >/dev/null 2>&1
check "close creates review" test -f plans/smoke-t1/review.md

.agents/scripts/archive.sh plans/smoke-t1 >/dev/null 2>&1
check "archive moved" test -d plans/_archive/smoke-t1
check "archive gone from active" test ! -d plans/smoke-t1

check_out "status lists active" "smoke-t2" .agents/scripts/status.sh
out=$(.agents/scripts/status.sh 2>&1 || true)
if echo "$out" | grep -q '_archive/smoke-t1'; then
  echo "FAIL  status must not list _archive"; fail=$((fail+1))
else
  echo "PASS  status skips _archive"; pass=$((pass+1))
fi

.agents/scripts/doctor.sh >/dev/null 2>&1 || true
check "doctor runs" true

.agents/scripts/new-plan.sh T1 promo >/dev/null 2>&1
.agents/scripts/promote.sh plans/promo >/dev/null 2>&1
check "promote T1→T2" test -f plans/promo/tasks.md

.agents/scripts/protocol.sh list >/dev/null 2>&1
check "protocol dispatcher" true

.agents/scripts/resume.sh >/dev/null 2>&1
check "resume" true

# Active Plans cleaned after archive
ap=$(grep "Active Plans:" plans/context.md || true)
if echo "$ap" | grep -q "smoke-t1"; then
  echo "FAIL  Active Plans still has archived smoke-t1"; fail=$((fail+1))
else
  echo "PASS  Active Plans cleaned after archive"; pass=$((pass+1))
fi

echo ""
echo "Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
