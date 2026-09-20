#!/usr/bin/env bash
# repro-D6.sh — D6: lint-encoding.sh missing
echo "Checking for .agents/scripts/lint-encoding.sh:"
ls .agents/scripts/lint-encoding.sh || echo "exit:$?"
