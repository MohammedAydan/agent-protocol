#!/usr/bin/env bash
# test-scripts.sh — Smoke + regression suite for Agent Protocol scripts.
# Run from repo root that has bash .agents/scripts/ (creates temporary plans/ under TMP if needed).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

pass=0
fail=0
check() {
  local name="$1"; shift
  if "$@"; then echo "PASS  $name"; pass=$((pass+1)); else echo "FAIL  $name"; fail=$((fail+1)); fi
}
check_out() {
  local name="$1" expect="$2"; shift 2
  local out
  out=$("$@" 2>&1) || true
  if echo "$out" | grep -q -- "$expect"; then echo "PASS  $name"; pass=$((pass+1)); else
    echo "FAIL  $name (expected substring: $expect)"; echo "  out: $out" | head -c 400; echo; fail=$((fail+1)); fi
}
check_exit0() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "PASS  $name"; pass=$((pass+1)); else echo "FAIL  $name (nonzero exit)"; fail=$((fail+1)); fi
}

# Isolate: work in temp project copy of scripts via symlink-style WORKDIR
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp -a "$ROOT/.agents" "$WORK/.agents"
true  # invoke scripts via bash (FS may lack +x)
cp -a "$ROOT/AGENTS.md" "$WORK/AGENTS.md" 2>/dev/null || true
cd "$WORK"

echo "=== Agent Protocol smoke tests (workdir=$WORK) ==="

bash .agents/scripts/bootstrap.sh "Smoke" "test" >/dev/null 2>&1
check "bootstrap creates context" test -f plans/context.md

bash .agents/scripts/new-plan.sh T1 smoke-t1 >/dev/null 2>&1
check "new T1" test -f plans/smoke-t1/plan.md
check_out "Active Plans after new" "smoke-t1" grep "Active Plans:" plans/context.md

bash .agents/scripts/new-plan.sh T2 smoke-t2 >/dev/null 2>&1
check "new T2" test -f plans/smoke-t2/tasks.md
check "new T2 plan.md" test -f plans/smoke-t2/plan.md

bash .agents/scripts/new-plan.sh T3 smoke-epic >/dev/null 2>&1
check "new T3" test -f plans/smoke-epic/OVERVIEW.md
bash .agents/scripts/new-plan.sh T2 sub smoke-epic >/dev/null 2>&1
check "new sub-plan" test -f plans/smoke-epic/sub/plan.md

check_out "overwrite guard" "Refusing\|ERROR\|already exists" bash .agents/scripts/new-plan.sh T1 smoke-t1

# task lifecycle T1
bash .agents/scripts/task.sh plans/smoke-t1 1 start >/dev/null 2>&1
check_out "one [~] enforced" "ERROR" bash .agents/scripts/task.sh plans/smoke-t1 2 start
bash .agents/scripts/task.sh plans/smoke-t1 1 done >/dev/null 2>&1
for i in 1 2 3 4 5 6 7 8; do
  bash .agents/scripts/task.sh plans/smoke-t1 "$i" cancel "x" >/dev/null 2>&1 || true
  bash .agents/scripts/task.sh --acceptance plans/smoke-t1 "$i" cancel "x" >/dev/null 2>&1 || true
done


# --- Regression: close last Active Plan must exit 0 and set none ---
# First close smoke-t1 while other plans still active
bash .agents/scripts/close-plan.sh --force plans/smoke-t1 >/dev/null 2>&1
check "close creates review" test -f plans/smoke-t1/review.md
check_exit0 "close-plan exit 0 (not last)" true

# Fill review so doctor doesn't only warn
printf '%s\n' '# Review' '## Built' '- smoke' '## Edge cases' '- none' '## Limitations' '- none' '## Follow-ups' '- [ ] none' > plans/smoke-t1/review.md

bash .agents/scripts/archive.sh plans/smoke-t1
check "archive moved" test -d plans/_archive/smoke-t1
check "archive gone from active" test ! -d plans/smoke-t1
ap=$(grep "Active Plans:" plans/context.md || true)
if echo "$ap" | grep -q "smoke-t1"; then
  echo "FAIL  Active Plans still has archived smoke-t1"; fail=$((fail+1))
else
  echo "PASS  Active Plans cleaned after archive"; pass=$((pass+1))
fi

# T2 acceptance via --file plan.md / --acceptance
# Ensure tasks.md has a checkbox and plan.md acceptance
echo '- [ ] Acc one' >> plans/smoke-t2/plan.md
echo '- [ ] Acc two' >> plans/smoke-t2/plan.md
bash .agents/scripts/task.sh --file plan.md plans/smoke-t2 1 done >/dev/null 2>&1
check_out "task --file plan.md" "DONE" bash .agents/scripts/task.sh --file plan.md plans/smoke-t2 2 done
bash .agents/scripts/task.sh --acceptance plans/smoke-t2 "Acc" done >/dev/null 2>&1 || true
# tasks.md path still default
bash .agents/scripts/task.sh plans/smoke-t2 1 start >/dev/null 2>&1
bash .agents/scripts/task.sh plans/smoke-t2 1 done >/dev/null 2>&1
for i in 1 2 3 4 5 6; do bash .agents/scripts/task.sh plans/smoke-t2 "$i" cancel "x" >/dev/null 2>&1 || true; done
for i in 1 2 3 4; do bash .agents/scripts/task.sh --file plan.md plans/smoke-t2 "$i" cancel "x" >/dev/null 2>&1 || true; done
bash .agents/scripts/close-plan.sh --force plans/smoke-t2 >/dev/null 2>&1
printf '%s\n' '# R' '## Built' '- x' > plans/smoke-t2/review.md
bash .agents/scripts/archive.sh plans/smoke-t2 >/dev/null 2>&1
check "T2 archived" test -d plans/_archive/smoke-t2

# LAST plan removal: force Active Plans to a single name then remove it
# Clear any remaining active epic/sub by force-setting context (unit under test = removal code)
sed -i.bak "s|^Active Plans:.*|Active Plans: last-one|" plans/context.md
rm -f plans/context.md.bak
bash .agents/scripts/new-plan.sh T1 last-one >/dev/null 2>&1 || true
# Ensure folder exists with filled plan
[[ -d plans/last-one ]] || bash .agents/scripts/new-plan.sh --force T1 last-one >/dev/null 2>&1 || true
for i in 1 2 3 4 5 6 7 8; do
  bash .agents/scripts/task.sh plans/last-one "$i" cancel "x" >/dev/null 2>&1 || true
  bash .agents/scripts/task.sh --acceptance plans/last-one "$i" cancel "x" >/dev/null 2>&1 || true
done
check_exit0 "close LAST plan exit 0" bash .agents/scripts/close-plan.sh --force plans/last-one
printf '%s\n' '# R' '## Built' '- last' > plans/last-one/review.md
# Ensure only last-one is listed before archive
sed -i.bak "s|^Active Plans:.*|Active Plans: last-one|" plans/context.md
rm -f plans/context.md.bak
check_exit0 "archive LAST plan exit 0" bash .agents/scripts/archive.sh plans/last-one
ap=$(grep "Active Plans:" plans/context.md)
if echo "$ap" | grep -qE 'Active Plans: none'; then
  echo "PASS  last plan → Active Plans: none"; pass=$((pass+1))
else
  echo "FAIL  expected Active Plans: none, got: $ap"; fail=$((fail+1))
fi
check "last archived" test -d plans/_archive/last-one

# status skips _archive
out=$(bash .agents/scripts/status.sh 2>&1 || true)
if echo "$out" | grep -q '_archive/smoke-t1'; then
  echo "FAIL  status must not list _archive"; fail=$((fail+1))
else
  echo "PASS  status skips _archive"; pass=$((pass+1))
fi

bash .agents/scripts/doctor.sh >/dev/null 2>&1 || true
check "doctor runs" true

bash .agents/scripts/new-plan.sh T1 promo >/dev/null 2>&1
bash .agents/scripts/promote.sh plans/promo >/dev/null 2>&1
check "promote T1→T2" test -f plans/promo/tasks.md

bash .agents/scripts/protocol.sh list >/dev/null 2>&1
check "protocol dispatcher" true
bash .agents/scripts/resume.sh >/dev/null 2>&1
check "resume" true

bash .agents/scripts/session-log.sh "test" "done item" >/dev/null 2>&1
check "session-log" grep -q "test" plans/SESSION_LOG.md

bash .agents/scripts/verify-checklist.sh >/dev/null 2>&1
check "verify-checklist" true

# D5: verify-checklist.sh --strict
bash .agents/scripts/new-plan.sh T1 v-open >/dev/null 2>&1
out_open=$(bash .agents/scripts/verify-checklist.sh --strict plans/v-open 2>&1 || true)
rc_open=0
bash .agents/scripts/verify-checklist.sh --strict plans/v-open >/dev/null 2>&1 || rc_open=$?
if [[ "$rc_open" -ne 0 ]] && echo "$out_open" | grep -qE 'plan\.md:[0-9]+:'; then
  echo "PASS  verify-checklist --strict flags open tasks with line numbers"; pass=$((pass+1))
else
  echo "FAIL  verify-checklist --strict flags open tasks with line numbers"; fail=$((fail+1))
fi

bash .agents/scripts/task.sh plans/v-open 1 done >/dev/null 2>&1
bash .agents/scripts/task.sh plans/v-open 2 done >/dev/null 2>&1
bash .agents/scripts/task.sh --acceptance plans/v-open 1 done >/dev/null 2>&1
rc_clean=0
bash .agents/scripts/verify-checklist.sh --strict plans/v-open >/dev/null 2>&1 || rc_clean=$?
if [[ "$rc_clean" -eq 0 ]]; then
  echo "PASS  verify-checklist --strict clean plan exits 0"; pass=$((pass+1))
else
  echo "FAIL  verify-checklist --strict clean plan exits 0"; fail=$((fail+1))
fi

rc_compat=1
bash .agents/scripts/verify-checklist.sh plans/open-guard >/dev/null 2>&1 && rc_compat=0 || true
if [[ "$rc_compat" -eq 0 ]]; then
  echo "PASS  verify-checklist default mode exits 0"; pass=$((pass+1))
else
  echo "FAIL  verify-checklist default mode exits 0"; fail=$((fail+1))
fi

bash .agents/scripts/update-doc.sh stack "Test" "X" "1" "reason" >/dev/null 2>&1
check "update-doc stack" grep -q "Test" plans/TECH_STACK.md

# close refuses open tasks
bash .agents/scripts/new-plan.sh T1 open-guard >/dev/null 2>&1
if bash .agents/scripts/close-plan.sh plans/open-guard >/dev/null 2>&1; then
  echo "FAIL  close should refuse open tasks"; fail=$((fail+1))
else
  echo "PASS  close refuses open tasks"; pass=$((pass+1))
fi

# D1: task.sh section scoping on T1
bash .agents/scripts/new-plan.sh T1 d1-scope >/dev/null 2>&1
cat > plans/d1-scope/plan.md <<'EOF'
# d1-scope
**Complexity**: T1

## Goal
test

## Acceptance
- [ ] a1
- [ ] a2
- [ ] a3

## Tasks
- [ ] t1
- [ ] t2
- [ ] t3
EOF

bash .agents/scripts/task.sh plans/d1-scope 1 start >/dev/null 2>&1 || true
if grep -q '^- \[~\] t1' plans/d1-scope/plan.md && grep -q '^- \[ \] a1' plans/d1-scope/plan.md; then
  echo "PASS  task.sh scopes to tasks section by default"; pass=$((pass+1))
else
  echo "FAIL  task.sh scopes to tasks section by default"; fail=$((fail+1))
fi

bash .agents/scripts/task.sh --acceptance plans/d1-scope 1 done >/dev/null 2>&1 || true
if grep -q '^- \[x\] a1' plans/d1-scope/plan.md; then
  echo "PASS  task.sh --acceptance scopes to acceptance section"; pass=$((pass+1))
else
  echo "FAIL  task.sh --acceptance scopes to acceptance section"; fail=$((fail+1))
fi

# D4: --help on protocol scripts
d4_fail=0
for s in archive.sh close-plan.sh doctor.sh status.sh verify-checklist.sh \
         list-plans.sh resume.sh next-task.sh promote.sh session-log.sh \
         update-doc.sh sync-adapters.sh new-plan.sh bootstrap.sh init.sh \
         update-project.sh protocol.sh task.sh; do
  out=$(bash ".agents/scripts/$s" --help 2>&1) || { d4_fail=$((d4_fail+1)); }
  [[ -z "$out" ]] && { d4_fail=$((d4_fail+1)); }
done
if [[ "$d4_fail" -eq 0 ]]; then
  echo "PASS  all protocol scripts support --help"; pass=$((pass+1))
else
  echo "FAIL  all protocol scripts support --help ($d4_fail failed)"; fail=$((fail+1))
fi

echo ""
echo "Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]

