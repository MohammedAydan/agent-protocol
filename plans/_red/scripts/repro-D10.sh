#!/usr/bin/env bash
# repro-D10.sh — D10: plans/ gitignore policy check
echo "Checking git ignore on plans/context.md (must NOT be ignored):"
git check-ignore plans/context.md || echo "exit:$? (1 = tracked exception, correct)"
echo "Checking git ignore on plans/fix-D1-task-scoping (must be ignored):"
git check-ignore plans/fix-D1-task-scoping && echo "exit:0 (ignored, correct)"
