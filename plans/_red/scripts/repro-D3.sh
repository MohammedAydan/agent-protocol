#!/usr/bin/env bash
# repro-D3.sh — D3: Windows / PowerShell 5.1 POSIX incompatibilities
echo "Testing PowerShell 5.1 incompatibilities documented in RED.md:"
powershell.exe -NoProfile -Command 'curl --version' 2>&1 || true
powershell.exe -NoProfile -Command 'head -1 README.md' 2>&1 || true
powershell.exe -NoProfile -Command 'which bash' 2>&1 || true
powershell.exe -NoProfile -Command 'echo a && echo b; Write-Host "exit:$LASTEXITCODE"' 2>&1 || true
