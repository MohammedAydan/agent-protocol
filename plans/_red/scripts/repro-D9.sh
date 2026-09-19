#!/usr/bin/env bash
# repro-D9.sh — D9: without .gitattributes, core.autocrlf=true corrupts .sh files
set -euo pipefail
R="/tmp/ap-nogitattr"
rm -rf "$R"
git clone -q . "$R"
cd "$R"
git rm -q .gitattributes
git commit -qm "test-remove-gitattributes"
git config core.autocrlf true
rm .agents/scripts/task.sh
git checkout -- .agents/scripts/task.sh
echo '--- file task.sh after autocrlf checkout ---'
file .agents/scripts/task.sh
echo "exit:$?"
