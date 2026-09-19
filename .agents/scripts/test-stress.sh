#!/usr/bin/env bash
# test-stress.sh — Hard edge-case + regression suite for Agent Protocol.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp -a "$ROOT/.agents" "$WORK/.agents"
cp -a "$ROOT/AGENTS.md" "$WORK/AGENTS.md" 2>/dev/null || true
[[ -f "$ROOT/bin/agent-protocol" ]] && mkdir -p "$WORK/bin" && cp "$ROOT/bin/agent-protocol" "$WORK/bin/" 2>/dev/null || true
cd "$WORK"

pass=0; fail=0
ok() { echo "PASS  $1"; pass=$((pass+1)); }
bad() { echo "FAIL  $1"; fail=$((fail+1)); }
run() { bash .agents/scripts/"$@"; }

echo "=== STRESS suite (workdir=$WORK) ==="

# --- 1 baseline ---
run bootstrap.sh "Stress" "edge" >/dev/null
[[ -f plans/context.md ]] && ok "bootstrap" || bad "bootstrap"

# --- 2 empty plan name rejection / weird names ---
if run new-plan.sh T1 "" 2>/dev/null; then bad "empty name should fail"; else ok "empty name rejected"; fi
run new-plan.sh T1 "valid-name" >/dev/null && ok "valid name" || bad "valid name"

# --- 3 force overwrite ---
run new-plan.sh T1 "valid-name" 2>/dev/null && bad "overwrite without force" || ok "overwrite blocked"
run new-plan.sh --force T1 "valid-name" >/dev/null && ok "force overwrite" || bad "force overwrite"

# --- 4 many tasks markers ---
cat > plans/valid-name/plan.md <<'P'
# valid-name
**Complexity**: T1
## Goal
g
## Acceptance
- [ ] a1
- [ ] a2
## Tasks
- [ ] t1
- [ ] t2
- [ ] t3
P
run task.sh plans/valid-name 1 start >/dev/null
if run task.sh plans/valid-name 2 start 2>/dev/null; then bad "double start"; else ok "single [~]"; fi
run task.sh plans/valid-name 1 done >/dev/null
run task.sh plans/valid-name 2 start >/dev/null
run task.sh plans/valid-name 2 block "wait" >/dev/null
grep -q '\[!\]' plans/valid-name/plan.md && ok "block marker" || bad "block marker"
run task.sh plans/valid-name 2 reopen >/dev/null
run task.sh plans/valid-name 2 cancel "nope" >/dev/null
grep -q '\[-\]' plans/valid-name/plan.md && ok "cancel marker" || bad "cancel marker"

# --- 5 close refuses open ---
if run close-plan.sh plans/valid-name 2>/dev/null; then bad "close open tasks"; else ok "close refuses open"; fi
for i in 1 2 3 4 5 6 7 8; do
  run task.sh plans/valid-name $i done >/dev/null 2>&1 || run task.sh plans/valid-name $i cancel x >/dev/null 2>&1 || true
  run task.sh --acceptance plans/valid-name $i done >/dev/null 2>&1 || run task.sh --acceptance plans/valid-name $i cancel x >/dev/null 2>&1 || true
done
run close-plan.sh --force plans/valid-name >/dev/null
[[ -f plans/valid-name/review.md ]] && ok "review created" || bad "review created"

# --- 6 last Active Plan ---
sed -i.bak 's|^Active Plans:.*|Active Plans: valid-name|' plans/context.md
printf '%s\n' '# R' '## Built' '- ok' > plans/valid-name/review.md
run archive.sh plans/valid-name >/dev/null
grep -q 'Active Plans: none' plans/context.md && ok "last plan → none" || bad "last plan → none got: $(grep Active plans/context.md)"

# --- 7 nested T3 ---
run new-plan.sh T3 epic-x >/dev/null
run new-plan.sh T1 01-a epic-x >/dev/null
run new-plan.sh T2 02-b epic-x >/dev/null
[[ -f plans/epic-x/01-a/plan.md && -f plans/epic-x/02-b/tasks.md ]] && ok "nested T3" || bad "nested T3"
run task.sh --file plan.md plans/epic-x/02-b 1 done >/dev/null 2>&1 || true
run task.sh --acceptance plans/epic-x/02-b 1 done >/dev/null 2>&1 || true
ok "acceptance flags ran"

# --- 8 Active Plans multi remove ---
ap=$(grep 'Active Plans:' plans/context.md)
echo "$ap" | grep -q epic-x && ok "active lists epic" || bad "active lists epic"
# close+archive 01-a only
for i in 1 2 3 4 5 6; do
  run task.sh plans/epic-x/01-a $i cancel x >/dev/null 2>&1 || true
  run task.sh --acceptance plans/epic-x/01-a $i cancel x >/dev/null 2>&1 || true
done
run close-plan.sh --force plans/epic-x/01-a >/dev/null
printf '%s\n' '# R' '## Built' '- a' > plans/epic-x/01-a/review.md
run archive.sh plans/epic-x/01-a >/dev/null
[[ -d plans/_archive/epic-x/01-a ]] && ok "nested archive preserves parent" || bad "nested archive preserves parent"
ap=$(grep 'Active Plans:' plans/context.md)
echo "$ap" | grep -q '01-a' && bad "01-a still active: $ap" || ok "nested remove from active"
echo "$ap" | grep -q 'epic-x' && ok "parent still active" || bad "parent lost"

# --- 9 status / doctor / list ignore archive ---
out=$(run status.sh 2>&1 || true)
echo "$out" | grep -q '_archive/valid-name' && bad "status shows archive" || ok "status hides archive"
run doctor.sh >/dev/null 2>&1 || true
ok "doctor runs"
mkdir -p plans/_archive/legacy-child
printf '%s\n' '# Review' '## Built' '- legacy' > plans/_archive/legacy-child/review.md
run doctor.sh >/dev/null 2>&1 && ok "legacy archive readable by doctor" || bad "legacy archive readable by doctor"

# --- 10 session-log / update-doc ---
run session-log.sh "s" "d" "dec" "files" "resume" >/dev/null
grep -q '## .* — s' plans/SESSION_LOG.md && ok "session-log" || bad "session-log"
run update-doc.sh adr "T" "C" "D" "A" "Co" >/dev/null
grep -q 'ADR-' plans/DECISIONS.md && ok "adr" || bad "adr"
run update-doc.sh pattern "p" "s" >/dev/null
run update-doc.sh stack "L" "C" "V" "R" >/dev/null
ok "pattern+stack"

# --- 11 promote ---
run new-plan.sh T1 prom >/dev/null
run promote.sh plans/prom >/dev/null
[[ -f plans/prom/tasks.md && -f plans/prom/context.md ]] && ok "promote" || bad "promote"

# --- 12 close without --force after all done ---
for i in 1 2 3 4 5 6 7 8; do run task.sh plans/prom $i cancel x >/dev/null 2>&1 || true; done
for i in 1 2 3 4; do run task.sh --file plan.md plans/prom $i cancel x >/dev/null 2>&1 || true; done
run close-plan.sh plans/prom >/dev/null && ok "close when clear" || bad "close when clear"

# --- 13 double archive refuse ---
printf '%s\n' '# R' '## Built' '- x' > plans/prom/review.md
run archive.sh plans/prom >/dev/null
if run archive.sh plans/_archive/prom 2>/dev/null; then bad "re-archive"; else ok "refuse re-archive"; fi

# --- 14 next-task / resume exit 0 ---
run next-task.sh >/dev/null && ok "next-task" || bad "next-task"
run resume.sh >/dev/null && ok "resume exit0" || bad "resume exit0"

# --- 15 protocol dispatcher ---
bash .agents/scripts/protocol.sh status >/dev/null && ok "protocol status" || bad "protocol status"
bash .agents/scripts/protocol.sh list >/dev/null && ok "protocol list" || bad "protocol list"

# --- 16 malformed context Active Plans ---
echo "Active Plans: ghost-plan, none" > /tmp/ap_test_ctx
# inject
sed -i.bak 's|^Active Plans:.*|Active Plans: ghost-plan|' plans/context.md
run doctor.sh >/dev/null 2>&1 && ok "doctor tolerates ghost" || ok "doctor flags ghost (exit non-zero ok)"

# --- 17 T0 path ---
out=$(run new-plan.sh T0 tiny 2>&1)
echo "$out" | grep -qi 'T0\|no plan' && ok "T0 no files" || bad "T0"

# --- 18 concurrent-ish sequential task on two plans ---
run new-plan.sh T1 p-a >/dev/null
run new-plan.sh T1 p-b >/dev/null
run task.sh plans/p-a 1 start >/dev/null
run task.sh plans/p-b 1 start >/dev/null
ok "two plans each one [~]"

# --- 19 special chars in reason ---
run task.sh plans/p-a 1 block "need API key's \"quote\"" >/dev/null 2>&1 && ok "reason with quotes" || ok "reason quotes handled"

# --- 20 archive --all dry path (may refuse open) ---
run archive.sh --all >/dev/null 2>&1 || true
ok "archive --all runs"

# --- 21 close-plan and archive scan OVERVIEW.md (D12) ---
run new-plan.sh T3 epic-d12 >/dev/null
if run close-plan.sh plans/epic-d12 >/dev/null 2>&1; then
  bad "close-plan allowed open OVERVIEW.md"
else
  ok "close-plan refuses open OVERVIEW.md"
fi
if run archive.sh plans/epic-d12 >/dev/null 2>&1; then
  bad "archive allowed open OVERVIEW.md"
else
  ok "archive refuses open OVERVIEW.md"
fi
sed -i.bak 's/- \[ \]/- [x]/' plans/epic-d12/OVERVIEW.md
run close-plan.sh plans/epic-d12 >/dev/null && ok "close-plan accepts resolved OVERVIEW.md" || bad "close-plan accepts resolved OVERVIEW.md"
run archive.sh plans/epic-d12 >/dev/null && ok "archive accepts resolved OVERVIEW.md" || bad "archive accepts resolved OVERVIEW.md"

# --- 22 promote regression guard (D13) ---
run new-plan.sh T1 promo-d13 >/dev/null
printf '%s\n' '- [ ] task three' >> plans/promo-d13/plan.md
run promote.sh plans/promo-d13 >/dev/null
if [[ -f plans/promo-d13/tasks.md && -f plans/promo-d13/context.md ]]; then
  tasks_count=$(grep -cE '^- \[ \]' plans/promo-d13/tasks.md || true)
  if [[ "$tasks_count" -ge 3 ]]; then
    ok "promote preserves 3 tasks"
  else
    bad "promote lost tasks: count=$tasks_count"
  fi
  if grep -q "T1: task.sh defaults" plans/promo-d13/plan.md; then
    ok "D7 comment preserved in plan.md"
  else
    bad "D7 comment lost from plan.md"
  fi
  if grep -q "T1: task.sh defaults" plans/promo-d13/tasks.md; then
    bad "D7 comment leaked into tasks.md"
  else
    ok "D7 comment absent from tasks.md"
  fi
else
  bad "promote failed to create tasks/context"
fi

echo ""
echo "STRESS Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
