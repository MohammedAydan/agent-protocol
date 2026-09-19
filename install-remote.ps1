# Agent Protocol — Windows installer
# One-liner (project folder):
#   irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex
#
# Options via env (before the command):
#   $env:AP_ADAPTERS="claude,cursor"; irm ... | iex
#   $env:AP_FORCE="1"; irm ... | iex
#
# Or save & run:
#   iwr -useb URL -OutFile ap.ps1; powershell -ExecutionPolicy Bypass -File .\ap.ps1 -Adapters all

param(
  [string]$Adapters = $(if ($env:AP_ADAPTERS) { $env:AP_ADAPTERS } else { "all" }),
  [string]$Ref = $(if ($env:AP_REF) { $env:AP_REF } else { "main" }),
  [string]$Owner = $(if ($env:AP_OWNER) { $env:AP_OWNER } else { "MohammedAydan" }),
  [string]$Repo = $(if ($env:AP_REPO) { $env:AP_REPO } else { "agent-protocol" }),
  [string]$Name = "",
  [string]$Purpose = $(if ($env:AP_PURPOSE) { $env:AP_PURPOSE } else { "TBD" }),
  [switch]$Force
)

if ($env:AP_FORCE -eq "1") { $Force = $true }

$ErrorActionPreference = "Stop"
$Target = (Get-Location).Path
if (-not $Name) { $Name = Split-Path $Target -Leaf }

Write-Host "=== Agent Protocol (Windows) ===" -ForegroundColor Cyan
Write-Host "  target  : $Target"
Write-Host "  repo    : $Owner/$Repo@$Ref"
Write-Host "  adapters: $Adapters"

$bash = $null
foreach ($c in @(
  "$env:ProgramFiles\Git\bin\bash.exe",
  "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
  "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
)) { if (Test-Path $c) { $bash = $c; break } }
if (-not $bash) {
  $g = Get-Command bash -ErrorAction SilentlyContinue
  if ($g) { $bash = $g.Source }
}

$tmp = Join-Path $env:TEMP ("ap-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
  if ($Ref -eq "main" -or $Ref -eq "master") {
    $zipUrl = "https://github.com/$Owner/$Repo/archive/refs/heads/$Ref.zip"
  } else {
    $zipUrl = "https://github.com/$Owner/$Repo/archive/refs/tags/$Ref.zip"
  }
  $zipPath = Join-Path $tmp "p.zip"
  Write-Host "  download: $zipUrl"
  try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
  } catch {
    $zipUrl = "https://github.com/$Owner/$Repo/archive/refs/heads/main.zip"
    Write-Host "  retry   : $zipUrl"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
  }

  Expand-Archive -Path $zipPath -DestinationPath $tmp -Force
  $pkg = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like "$Repo-*" } | Select-Object -First 1
  if (-not $pkg) { throw "Bad archive" }

  function Copy-Proto($rel) {
    $s = Join-Path $pkg.FullName $rel
    $d = Join-Path $Target $rel
    if (-not (Test-Path $s)) { return }
    if ((Test-Path $d) -and -not $Force) { Write-Host "  skip: $rel"; return }
    if (Test-Path $d) { Remove-Item -Recurse -Force $d }
    $parent = Split-Path $d -Parent
    if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    Copy-Item -Recurse -Force $s $d
    Write-Host "  + $rel"
  }

  Write-Host "Installing (README & app source untouched)..."
  Copy-Proto "AGENTS.md"
  Copy-Proto ".agents"
  Copy-Proto "adapters"
  if ($Adapters -match '(^|,)(all|claude)(,|$)') { Copy-Proto "CLAUDE.md" }
  if ($Adapters -match '(^|,)(all|gemini)(,|$)') { Copy-Proto "GEMINI.md" }
  "1.0.0" | Set-Content -Encoding ascii (Join-Path $Target ".agents\PROTOCOL_VERSION")

  # plans/
  $plans = Join-Path $Target "plans"
  if (-not (Test-Path (Join-Path $plans "context.md"))) {
    New-Item -ItemType Directory -Force -Path $plans | Out-Null
    @"
# Project Context

Purpose: $Purpose
Current Status: Bootstrapped
Critical Constraints: TBD
Active Plans: none
Known Issues: none
"@ | Set-Content -Encoding utf8 (Join-Path $plans "context.md")
    @"
# Session Log

## $(Get-Date -Format 'yyyy-MM-dd HH:mm') UTC — Bootstrap
- Done: Windows install bootstrap
- Resume: start with T0–T3 for first task
"@ | Set-Content -Encoding utf8 (Join-Path $plans "SESSION_LOG.md")
    foreach ($f in @("ARCH.md","TECH_STACK.md","DECISIONS.md","PATTERNS.md")) {
      "# $($f.Replace('.md',''))`n" | Set-Content -Encoding utf8 (Join-Path $plans $f)
    }
    Write-Host "  + plans/"
  }

  # adapters mirrors
  $ad = Join-Path $pkg.FullName "adapters"
  function Install-Mirror($want, $srcRel, $dstRel) {
    if ($Adapters -notmatch "(^|,)($want|all)(,|$)") { return }
    $s = Join-Path $ad $srcRel
    if (-not (Test-Path $s)) { return }
    $d = Join-Path $Target $dstRel
    $dir = Split-Path $d -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if ((Test-Path $d) -and -not $Force) { Write-Host "  skip: $dstRel"; return }
    Copy-Item $s $d -Force
    Write-Host "  + $dstRel"
  }
  Install-Mirror "cursor" "cursor\rules.mdc" ".cursor\rules\agent-protocol.mdc"
  Install-Mirror "copilot" "copilot\copilot-instructions.md" ".github\copilot-instructions.md"
  Install-Mirror "cline" "cline\clinerules" ".clinerules"
  Install-Mirror "roo" "roo\roorules" ".roorules"
  if ($Adapters -match '(^|,)(all|windsurf)(,|$)') {
    $s = Join-Path $ad "windsurf\windsurfrules"
    if (Test-Path $s) {
      Copy-Item $s (Join-Path $Target ".windsurfrules") -Force
      New-Item -ItemType Directory -Force -Path (Join-Path $Target ".windsurf\rules") | Out-Null
      New-Item -ItemType Directory -Force -Path (Join-Path $Target ".devin\rules") | Out-Null
      Copy-Item $s (Join-Path $Target ".windsurf\rules\agent-protocol.md") -Force
      Copy-Item $s (Join-Path $Target ".devin\rules\agent-protocol.md") -Force
      Write-Host "  + windsurf/devin rules"
    }
  }
  if ($Adapters -match '(^|,)(all|claude)(,|$)') {
    $skills = Join-Path $Target ".agents\skills"
    if (Test-Path $skills) {
      New-Item -ItemType Directory -Force -Path (Join-Path $Target ".claude\skills") | Out-Null
      New-Item -ItemType Directory -Force -Path (Join-Path $Target ".claude\agents") | Out-Null
      Get-ChildItem $skills -Directory | ForEach-Object {
        $d = Join-Path $Target ".claude\skills\$($_.Name)"
        New-Item -ItemType Directory -Force -Path $d | Out-Null
        $sk = Join-Path $_.FullName "SKILL.md"
        if (Test-Path $sk) { Copy-Item $sk (Join-Path $d "SKILL.md") -Force }
      }
      $ag = Join-Path $Target ".agents\agents"
      if (Test-Path $ag) {
        Get-ChildItem $ag -Filter *.md | ForEach-Object {
          Copy-Item $_.FullName (Join-Path $Target ".claude\agents\$($_.Name)") -Force
        }
      }
      Write-Host "  + .claude mirrors"
    }
  }

  Write-Host ""
  Write-Host "=== Ready ===" -ForegroundColor Green
  Write-Host "  README.md and app source were NOT modified."
  Write-Host "  Open this folder in your AI agent (AGENTS.md is loaded automatically by many tools)."
  if ($bash) {
    Write-Host "  Git Bash found — optional: bash .agents/scripts/resume.sh"
  } else {
    Write-Host "  Optional: install Git for Windows to use .agents/scripts/*.sh"
  }
}
finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
