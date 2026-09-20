#!/usr/bin/env bash
set -euo pipefail

PKG="D:/Downloads/agent-protocol/agent-protocol-1.0.0"
SCRATCH="/tmp/ap-scratch-consumer-gate"
rm -rf "$SCRATCH"
mkdir -p "$SCRATCH"
cd "$SCRATCH"

echo "=== 1. Init scratch consumer ==="
bash "$PKG/bin/agent-protocol" init --adapters none >/dev/null 2>&1
echo "PASS: init completed"

echo "=== 2. Doctor and Resume ==="
bash .agents/scripts/doctor.sh >/dev/null
echo "PASS: doctor exit 0"
bash .agents/scripts/resume.sh >/dev/null
echo "PASS: resume exit 0"

echo "=== 3. T1 plan with 3 tasks + 3 acceptance checkboxes ==="
mkdir -p plans/test-t1
cat << 'EOF' > plans/test-t1/plan.md
<!-- T1: task.sh defaults to '## Tasks'. Use --acceptance for '## Acceptance'. See AGENTS.md. -->
# test-t1
**Complexity**: T1
## Goal
Test T1 plan

## Acceptance
- [ ] acc1
- [ ] acc2
- [ ] acc3

## Tasks
- [ ] task1
- [ ] task2
- [ ] task3
EOF

# Toggle tasks
bash .agents/scripts/task.sh plans/test-t1 1 start >/dev/null
bash .agents/scripts/task.sh plans/test-t1 1 done >/dev/null
bash .agents/scripts/task.sh plans/test-t1 2 start >/dev/null
bash .agents/scripts/task.sh plans/test-t1 2 done >/dev/null
bash .agents/scripts/task.sh plans/test-t1 3 start >/dev/null
bash .agents/scripts/task.sh plans/test-t1 3 done >/dev/null

# Toggle acceptance via --acceptance
bash .agents/scripts/task.sh --acceptance plans/test-t1 1 done >/dev/null
bash .agents/scripts/task.sh --acceptance plans/test-t1 2 done >/dev/null
bash .agents/scripts/task.sh --acceptance plans/test-t1 3 done >/dev/null

# Verify all 6 checkboxes are [x]
x_count=$(grep -c '^- \[x\]' plans/test-t1/plan.md || true)
if [[ "$x_count" -eq 6 ]]; then
  echo "PASS: all 3 tasks + 3 acceptance checkboxes cleanly marked [x]"
else
  echo "FAIL: expected 6 [x], found $x_count"
  exit 1
fi

echo "=== 4. verify-checklist.sh --strict ==="
# Clean plan exits 0
bash .agents/scripts/verify-checklist.sh --strict plans/test-t1 >/dev/null
echo "PASS: verify-checklist --strict clean plan exit 0"

# Close and archive test-t1
bash .agents/scripts/close-plan.sh plans/test-t1 >/dev/null
bash .agents/scripts/archive.sh plans/test-t1 >/dev/null

# Plan with open task flags line number and exits 1
bash .agents/scripts/new-plan.sh T1 open-t1 >/dev/null
out=$(bash .agents/scripts/verify-checklist.sh --strict plans/open-t1 2>&1 || true)
if echo "$out" | grep -qE "plan\.md:[0-9]+:- \[ \]"; then
  echo "PASS: verify-checklist --strict flags open task with line number"
else
  echo "FAIL: verify-checklist --strict did not flag line number: $out"
  exit 1
fi
# Cleanup open plan
bash .agents/scripts/close-plan.sh --force plans/open-t1 >/dev/null
rm -rf plans/open-t1

echo "=== 5. T3 nested epic archive ==="
bash .agents/scripts/new-plan.sh T3 parent-epic >/dev/null
bash .agents/scripts/new-plan.sh T1 child-sub parent-epic >/dev/null
# Resolve child
bash .agents/scripts/task.sh plans/parent-epic/child-sub 1 done >/dev/null
bash .agents/scripts/task.sh plans/parent-epic/child-sub 2 done >/dev/null
bash .agents/scripts/task.sh --acceptance plans/parent-epic/child-sub 1 done >/dev/null
bash .agents/scripts/close-plan.sh plans/parent-epic/child-sub >/dev/null
bash .agents/scripts/archive.sh plans/parent-epic/child-sub >/dev/null

if [[ -d plans/_archive/parent-epic/child-sub ]]; then
  echo "PASS: nested epic hierarchy preserved under plans/_archive/parent-epic/child-sub"
else
  echo "FAIL: nested epic hierarchy not preserved"
  exit 1
fi

# Resolve parent epic and archive
sed -i.bak 's/- \[ \]/- [x]/' plans/parent-epic/OVERVIEW.md
bash .agents/scripts/close-plan.sh plans/parent-epic >/dev/null
bash .agents/scripts/archive.sh plans/parent-epic >/dev/null

echo "=== 6. Legacy flat archive readable by doctor ==="
mkdir -p plans/_archive/legacy-flat
printf '%s\n' '# Review' '## Built' '- legacy item' > plans/_archive/legacy-flat/review.md
bash .agents/scripts/doctor.sh >/dev/null
echo "PASS: doctor cleanly reads legacy flat archive"

echo "=== 7. All protocol scripts respond to --help / -h with exit 0 ==="
scripts_fail=0
for s in doctor.sh status.sh task.sh new-plan.sh close-plan.sh archive.sh \
         session-log.sh update-doc.sh verify-checklist.sh promote.sh \
         resume.sh list-plans.sh next-task.sh lint-encoding.sh \
         update-project.sh sync-adapters.sh bootstrap.sh init.sh protocol.sh; do
  bash ".agents/scripts/$s" --help >/dev/null 2>&1 || { echo "FAIL $s --help"; scripts_fail=1; }
  bash ".agents/scripts/$s" -h >/dev/null 2>&1 || { echo "FAIL $s -h"; scripts_fail=1; }
done
if [[ "$scripts_fail" -eq 0 ]]; then
  echo "PASS: all scripts respond to --help / -h with exit 0"
else
  echo "FAIL: some scripts failed --help / -h"
  exit 1
fi

echo "=== 8. --ascii on doctor.sh ==="
doc_ascii=$(bash .agents/scripts/doctor.sh --ascii)
if echo "$doc_ascii" | grep -q '\[OK\]'; then
  # Check no UTF-8 checkmark or warning sign
  if echo "$doc_ascii" | grep -qE '\xe2\x9c\x93|\xe2\x9a\xa0'; then
    echo "FAIL: doctor.sh --ascii contained UTF-8 symbols"
    exit 1
  fi
  echo "PASS: doctor.sh --ascii outputs [OK] and no UTF-8 status marks"
else
  echo "FAIL: doctor.sh --ascii did not contain [OK]"
  exit 1
fi

echo "=== ALL SCRATCH CONSUMER GATES PASSED ==="
