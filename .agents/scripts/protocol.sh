#!/usr/bin/env bash
# protocol.sh — Single entry point for the whole framework.
# Usage: protocol.sh <command> [args]
#   boot|resume                 session resume
#   new  <T0|T1|T2|T3> <n> [p]  new plan
#   task <plan> <n|txt> <act>   task transition (start|done|block|cancel|reopen)
#   status | list | next        overview / list / next task
#   promote <plan>              T1 -> T2
#   close <plan> [--force]      close plan
#   archive <plan>|--all        archive closed plan(s)
#   log "title" "done" [...]    session log
#   doc adr|pattern|stack ...   living docs
#   doctor                      audit
#   verify                      pre-[x] checklist
#   test                        run smoke tests
#   sync                        sync tool adapters
#   bootstrap ["Name"] ["Purp"] init plans/
#   init [--here] [--force] [--name N] [--purpose P]  add protocol to project
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
CMD="${1:-}"; shift || true
case "$CMD" in
  boot|resume) "$D/resume.sh" "$@" ;;
  new)         "$D/new-plan.sh" "$@" ;;
  task)        "$D/task.sh" "$@" ;;
  status)      "$D/status.sh" "$@" ;;
  list)        "$D/list-plans.sh" "$@" ;;
  next)        "$D/next-task.sh" "$@" ;;
  promote)     "$D/promote.sh" "$@" ;;
  close)       "$D/close-plan.sh" "$@" ;;
  archive)     "$D/archive.sh" "$@" ;;
  log)         "$D/session-log.sh" "$@" ;;
  doc)         "$D/update-doc.sh" "$@" ;;
  doctor)      "$D/doctor.sh" "$@" ;;
  verify)      "$D/verify-checklist.sh" "$@" ;;
  test)        "$D/test-scripts.sh" "$@" ;;
  sync)        "$D/sync-adapters.sh" "$@" ;;
  bootstrap)   "$D/bootstrap.sh" "$@" ;;
  init)        "$D/init.sh" "$@" ;;
  *) grep '^#' "$0" | head -n 18; exit 1 ;;
esac
