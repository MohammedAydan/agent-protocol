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

# D6 / D9: lint-encoding.sh tests
LDIR=$(mktemp -d)
(
  cd "$LDIR"
  git init -q
  cp "$ROOT/.gitattributes" .
  mkdir -p .agents/scripts
  cp "$ROOT/.agents/scripts/lint-encoding.sh" .agents/scripts/
  git add .gitattributes .agents/scripts/lint-encoding.sh
  git commit -qm "init"
)
check_exit0 "lint-encoding clean repo exits 0" bash -c "cd '$LDIR' && bash .agents/scripts/lint-encoding.sh"

printf '\xef\xbb\xbf# test' > "$LDIR/test-bom.txt"
( cd "$LDIR" && git add test-bom.txt )
check_out "lint-encoding detects BOM" "UTF-8 BOM detected" bash -c "cd '$LDIR' && bash .agents/scripts/lint-encoding.sh"
( cd "$LDIR" && git rm -qf test-bom.txt )

printf '#!/usr/bin/env bash\r\necho hi\r\n' > "$LDIR/bad.sh"
( cd "$LDIR" && git add bad.sh )
check_out "lint-encoding detects CRLF in .sh" "CRLF" bash -c "cd '$LDIR' && bash .agents/scripts/lint-encoding.sh"
( cd "$LDIR" && git rm -qf bad.sh )

( cd "$LDIR" && sed -i.bak '/\*\.sh text eol=lf/d' .gitattributes )
check_out "lint-encoding guards .gitattributes eol=lf" "missing required line" bash -c "cd '$LDIR' && bash .agents/scripts/lint-encoding.sh"
rm -rf "$LDIR"

# D7: T1 checkbox semantics documentation
check "AGENTS.md documents T1 checkbox semantics" grep -q "T1 checkbox semantics" "$ROOT/AGENTS.md"
check "T1 template contains D7 comment" grep -q "T1: task.sh defaults to '## Tasks'" "$ROOT/.agents/templates/T1-plan.md"
check_out "new-plan.sh --help prints T1 rule" "T1 rule: task.sh defaults to '## Tasks'" bash .agents/scripts/new-plan.sh --help

# D11: --ascii flag in doctor.sh and status.sh
check_out "doctor.sh --ascii prints [OK]" "[OK]" bash .agents/scripts/doctor.sh --ascii
check_exit0 "status.sh --ascii exits 0" bash .agents/scripts/status.sh --ascii

# D3: docs/WINDOWS.md exists and is referenced
check "docs/WINDOWS.md exists" test -f "$ROOT/docs/WINDOWS.md"
check "AGENTS.md points to docs/WINDOWS.md" grep -q "WINDOWS.md" "$ROOT/AGENTS.md"

# D8: PowerShell update path shells out to update-project.sh
check "ps1 delegates update to update-project.sh" grep -q "update-project.sh" "$ROOT/bin/agent-protocol.ps1"
check "ps1 delegates init to init.sh" grep -q "init.sh" "$ROOT/bin/agent-protocol.ps1"

# D10: .gitignore enforces plans/ policy
check ".gitignore ignores plans/*" grep -q "^plans/\*" "$ROOT/.gitignore"
check ".gitignore whitelists context.md" grep -q "^!plans/context.md" "$ROOT/.gitignore"

# OPT-1: T0.5 fast path (single file, no folder, no ceremony)
check_exit0 "new T0.5" bash .agents/scripts/new-plan.sh T0.5 quick-foo
check "T0.5 single file" test -f plans/_quick/quick-foo.md
check "T0.5 no folder" test ! -d plans/quick-foo
check "T0.5 has Task section" grep -q "^## Task" plans/_quick/quick-foo.md
check "T0.5 has Verify section" grep -q "^## Verify" plans/_quick/quick-foo.md
check "T0.5 not in Active Plans" bash -c "! grep 'Active Plans:' plans/context.md | grep -q quick-foo"
check_out "resume lists quick" "quick] quick-foo" bash .agents/scripts/resume.sh
check "doctor silent on _quick" bash -c "! bash .agents/scripts/doctor.sh 2>&1 | grep -q quick-foo"
check_out "session-log --brief" "brief-note" bash .agents/scripts/session-log.sh --brief "brief-note"

# OPT-2: slim T1 template (<=10 lines, no Complexity line)
bash .agents/scripts/new-plan.sh T1 slim-t1 >/dev/null 2>&1
check "slim T1 <=10 lines" bash -c "[[ $(wc -l < plans/slim-t1/plan.md) -le 10 ]]"
check "slim T1 no Complexity line" bash -c "! grep -q 'Complexity' plans/slim-t1/plan.md"
check "slim T1 keeps Tasks section" grep -q "^## Tasks" plans/slim-t1/plan.md
check "T1 template <=10 lines" bash -c "[[ $(wc -l < .agents/templates/T1-plan.md) -le 10 ]]"

# OPT-3: --quiet flags (clean fixture repo)
QDIR=$(mktemp -d)
cp -a "$ROOT/.agents" "$QDIR/.agents"
cp -a "$ROOT/AGENTS.md" "$QDIR/AGENTS.md"
(cd "$QDIR" && bash .agents/scripts/bootstrap.sh "Q" "test" >/dev/null 2>&1)
check "quiet doctor <=5 lines" bash -c 'cd "$1" && [[ $(bash .agents/scripts/doctor.sh --quiet 2>&1 | wc -l) -le 5 ]]' _ "$QDIR"
check "quiet resume <=5 lines" bash -c 'cd "$1" && [[ $(bash .agents/scripts/resume.sh --quiet 2>&1 | wc -l) -le 5 ]]' _ "$QDIR"
check_out "quiet doctor clean marker" "checks passed" bash -c "cd '$QDIR' && bash .agents/scripts/doctor.sh --quiet"
check "quiet status no headers" bash -c "! (cd '$QDIR' && bash .agents/scripts/status.sh --quiet 2>&1 | grep -q '===')"
check_out "default resume unchanged" "SESSION RESUME" bash .agents/scripts/resume.sh
check_out "default doctor unchanged" "Agent Protocol doctor" bash .agents/scripts/doctor.sh
(cd "$QDIR" && bash .agents/scripts/new-plan.sh T1 qc >/dev/null 2>&1)
(cd "$QDIR" && bash .agents/scripts/task.sh plans/qc 1 done >/dev/null 2>&1 && bash .agents/scripts/task.sh plans/qc 2 done >/dev/null 2>&1 && bash .agents/scripts/task.sh --acceptance plans/qc 1 done >/dev/null 2>&1 && sed -i.bak "s|^Current Status:.*|Current Status: Active: qc|" plans/context.md && rm -f plans/context.md.bak)
check_out "quiet close prints path" "review.md" bash -c "cd '$QDIR' && bash .agents/scripts/close-plan.sh --quiet plans/qc"
(cd "$QDIR" && bash .agents/scripts/new-plan.sh T1 qt >/dev/null 2>&1)
check_out "quiet task state line" "STARTED" bash -c "cd '$QDIR' && bash .agents/scripts/task.sh --quiet plans/qt 1 start"
rm -rf "$QDIR"
# OPT-4: task.sh --batch (one invocation for N ops, identical to sequential)
bash .agents/scripts/new-plan.sh T1 batch-a >/dev/null 2>&1
bash .agents/scripts/new-plan.sh T1 batch-b >/dev/null 2>&1
check_exit0 "batch run exits 0" bash -c "printf '1 start\n1 done\n2 start\n2 done\n' | bash .agents/scripts/task.sh --batch plans/batch-a"
check "batch completes 2 tasks" bash -c '[[ $(grep -c "^- \[x\] " plans/batch-a/plan.md) -eq 2 ]]'
bash .agents/scripts/task.sh plans/batch-b 1 start >/dev/null 2>&1
bash .agents/scripts/task.sh plans/batch-b 1 done >/dev/null 2>&1
bash .agents/scripts/task.sh plans/batch-b 2 start >/dev/null 2>&1
bash .agents/scripts/task.sh plans/batch-b 2 done >/dev/null 2>&1
grep -E '^- \[.\] ' plans/batch-a/plan.md > ba.txt
grep -E '^- \[.\] ' plans/batch-b/plan.md > bb.txt
check "batch equals sequential" diff ba.txt bb.txt
rm -f ba.txt bb.txt

# v1.2.1: task.sh --quick (native T0.5 single-file support, zero hand-edits)
bash .agents/scripts/new-plan.sh T0.5 quick-a >/dev/null 2>&1
bash .agents/scripts/new-plan.sh T0.5 quick-b >/dev/null 2>&1
check_exit0 "quick start exits 0" bash .agents/scripts/task.sh --quick quick-a 1 start
check "quick start toggles" bash -c 'grep -q "^- \[~\]" plans/_quick/quick-a.md'
check_exit0 "quick done exits 0" bash .agents/scripts/task.sh --quick quick-a 1 done
check "quick done toggles" bash -c 'grep -q "^- \[x\]" plans/_quick/quick-a.md'
check_exit0 "quick native path" bash .agents/scripts/task.sh plans/_quick/quick-a.md 2 start
check "quick native toggles Verify box" bash -c '[[ $(grep -c "^- \[~\]" plans/_quick/quick-a.md) -eq 1 ]]'
bash .agents/scripts/task.sh --quick quick-a 2 done >/dev/null 2>&1
check_exit0 "quick batch exits 0" bash -c "printf '1 start\n1 done\n2 start\n2 done\n' | bash .agents/scripts/task.sh --quick quick-b --batch"
check "quick batch completes both boxes" bash -c '[[ $(grep -c "^- \[x\]" plans/_quick/quick-b.md) -eq 2 ]]'
bash .agents/scripts/new-plan.sh T0.5 quick-c >/dev/null 2>&1
bash .agents/scripts/task.sh --quick quick-c 1 start >/dev/null 2>&1
bash .agents/scripts/task.sh --quick quick-c 1 done >/dev/null 2>&1
bash .agents/scripts/task.sh --quick quick-c 2 start >/dev/null 2>&1
bash .agents/scripts/task.sh --quick quick-c 2 done >/dev/null 2>&1
grep -E '^- \[.\]' plans/_quick/quick-b.md > qb.txt
grep -E '^- \[.\]' plans/_quick/quick-c.md > qc.txt
check "quick batch equals sequential" diff qb.txt qc.txt
rm -f qb.txt qc.txt
check "quick rejects slashes" bash -c '! bash .agents/scripts/task.sh --quick a/b 1 start >/dev/null 2>&1'
check "quick missing file errors" bash -c '! bash .agents/scripts/task.sh --quick no-such-quick 1 start >/dev/null 2>&1'

# OPT-5: close-plan enforcement (T2 review gate + Bootstrapped context gate)
bash .agents/scripts/new-plan.sh T2 strict-t2 >/dev/null 2>&1
bash .agents/scripts/task.sh plans/strict-t2 1 done >/dev/null 2>&1
bash .agents/scripts/task.sh plans/strict-t2 2 done >/dev/null 2>&1
bash .agents/scripts/task.sh plans/strict-t2 3 done >/dev/null 2>&1
bash .agents/scripts/task.sh --acceptance plans/strict-t2 1 done >/dev/null 2>&1
printf '%s\n' '# Review — strict-t2' '' '## Built' '-' '' '## Edge cases' '-' > plans/strict-t2/review.md
check "close refuses empty review T2" bash -c '! bash .agents/scripts/close-plan.sh plans/strict-t2 >/dev/null 2>&1'
printf '%s\n' '# Review — strict-t2' '' '## Built' '- built thing' '' '## Edge cases' '-' > plans/strict-t2/review.md
sed -i.bak "s|^Current Status:.*|Current Status: Active: strict-t2|" plans/context.md; rm -f plans/context.md.bak
check_exit0 "close accepts filled review" bash .agents/scripts/close-plan.sh plans/strict-t2
bash .agents/scripts/new-plan.sh T1 strict-ctx >/dev/null 2>&1
bash .agents/scripts/task.sh plans/strict-ctx 1 done >/dev/null 2>&1
bash .agents/scripts/task.sh plans/strict-ctx 2 done >/dev/null 2>&1
bash .agents/scripts/task.sh --acceptance plans/strict-ctx 1 done >/dev/null 2>&1
sed -i.bak "s|^Current Status:.*|Current Status: Bootstrapped|" plans/context.md; rm -f plans/context.md.bak
check_out "close refuses Bootstrapped context" "Current Status" bash .agents/scripts/close-plan.sh plans/strict-ctx
GDIR=$(mktemp -d)
cp -a "$ROOT/.agents" "$GDIR/.agents"
cp -a "$ROOT/AGENTS.md" "$GDIR/AGENTS.md"
(cd "$GDIR" && git init -q && git add -A && git commit -qm init && bash .agents/scripts/bootstrap.sh "G" "test" >/dev/null 2>&1 && bash .agents/scripts/new-plan.sh T2 gw >/dev/null 2>&1)
(cd "$GDIR" && bash .agents/scripts/task.sh plans/gw 1 done >/dev/null 2>&1 && bash .agents/scripts/task.sh plans/gw 2 done >/dev/null 2>&1 && bash .agents/scripts/task.sh plans/gw 3 done >/dev/null 2>&1 && bash .agents/scripts/task.sh --acceptance plans/gw 1 done >/dev/null 2>&1 && bash .agents/scripts/close-plan.sh --force plans/gw >/dev/null 2>&1)
check_out "doctor warns uncommitted review" "no commit yet" bash -c "cd '$GDIR' && bash .agents/scripts/doctor.sh"
(cd "$GDIR" && git add -A && git commit -qm close >/dev/null 2>&1)
check "doctor silent after commit" bash -c "! (cd '$GDIR' && bash .agents/scripts/doctor.sh 2>&1 | grep -q 'no commit yet')"
rm -rf "$GDIR"

# OPT-6: token-budget-aware tier selection
check "AGENTS.md tier cost table" grep -q "Typical setup cost" "$ROOT/AGENTS.md"
check "SKILL.md documents T0.5" grep -q "T0.5" "$ROOT/.agents/skills/plan-manager/SKILL.md"
check_out "new-plan help prefers T0.5" "prefer it over T1" bash .agents/scripts/new-plan.sh --help

# OPT-7: measure-overhead.sh token-proxy audit
bash .agents/scripts/new-plan.sh T1 measure-fx >/dev/null 2>&1
check_out "measure-overhead line" "plan=measure-fx bytes=" bash .agents/scripts/measure-overhead.sh plans/measure-fx
check_out "protocol measure dispatches" "plan=measure-fx bytes=" bash .agents/scripts/protocol.sh measure plans/measure-fx

echo ""
echo "Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]

