#!/usr/bin/env bash
# repro-D4.sh — D4: --help flag missing across protocol scripts
for s in task.sh archive.sh close-plan.sh doctor.sh status.sh verify-checklist.sh \
         list-plans.sh resume.sh next-task.sh promote.sh session-log.sh \
         adr.sh pattern.sh update-doc.sh sync-adapters.sh; do
  echo "--- $s --help ---"
  bash ".agents/scripts/$s" --help 2>&1 || echo "exit:$?"
done
