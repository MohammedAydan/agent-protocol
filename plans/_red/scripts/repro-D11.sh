#!/usr/bin/env bash
# repro-D11.sh — D11: UTF-8 symbols in doctor.sh without --ascii option
echo "--- UTF-8 check/warn symbols in doctor.sh ---"
grep -n 'warn()\|ok()' .agents/scripts/doctor.sh | head -4
grep -o '✓\|⚠' .agents/scripts/doctor.sh | head -4 | od -An -tx1
