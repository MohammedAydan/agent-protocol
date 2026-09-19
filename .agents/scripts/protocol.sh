#!/usr/bin/env bash
# protocol.sh — Single entry point for the whole framework.
# Usage: protocol.sh <command> [args]
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
run() { bash "$D/$1" "${@:2}"; }
CMD="${1:-}"; shift || true
case "$CMD" in
  boot|resume) run resume.sh "$@" ;;
  new)         run new-plan.sh "$@" ;;
  task)        run task.sh "$@" ;;
  status)      run status.sh "$@" ;;
  list)        run list-plans.sh "$@" ;;
  next)        run next-task.sh "$@" ;;
  promote)     run promote.sh "$@" ;;
  close)       run close-plan.sh "$@" ;;
  archive)     run archive.sh "$@" ;;
  log)         run session-log.sh "$@" ;;
  doc)         run update-doc.sh "$@" ;;
  doctor)      run doctor.sh "$@" ;;
  verify)      run verify-checklist.sh "$@" ;;
  test)        run test-scripts.sh "$@" ;;
  sync)        run sync-adapters.sh "$@" ;;
  bootstrap)   run bootstrap.sh "$@" ;;
  init)        run init.sh "$@" ;;
  update)      run update-project.sh "$@" ;;
  lint)        run lint-encoding.sh "$@" ;;
  stress)      run test-stress.sh "$@" ;;
  help|-h|--help)
    cat <<USAGE
Usage: protocol.sh <command> [args]
  boot|resume | new | task | status | list | next | promote
  close | archive | log | doc | doctor | verify | test | stress | sync | bootstrap | init | update | lint
USAGE
    exit 0
    ;;
  *)
    cat <<USAGE
Usage: protocol.sh <command> [args]
  boot|resume | new | task | status | list | next | promote
  close | archive | log | doc | doctor | verify | test | stress | sync | bootstrap | init | update
USAGE
    exit 1
    ;;
esac
