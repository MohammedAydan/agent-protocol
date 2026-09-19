# agent-protocol.ps1 — Windows-native CLI (no Git Bash required for core commands)
# Installed under %LOCALAPPDATA%\agent-protocol and invoked via agent-protocol.cmd

param(
  [Parameter(Position = 0)]
  [string]$Command = "help",
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

$ErrorActionPreference = "Stop"
$Owner = if ($env:AGENT_PROTOCOL_OWNER) { $env:AGENT_PROTOCOL_OWNER } else { "MohammedAydan" }
$Repo  = if ($env:AGENT_PROTOCOL_REPO)  { $env:AGENT_PROTOCOL_REPO }  else { "agent-protocol" }
$Ref   = if ($env:AGENT_PROTOCOL_REF)   { $env:AGENT_PROTOCOL_REF }   else { "main" }
$Pkg   = if ($env:AGENT_PROTOCOL_HOME)  { $env:AGENT_PROTOCOL_HOME }  else { Join-Path $env:LOCALAPPDATA "agent-protocol" }

function Get-Bash {
  foreach ($c in @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
  )) { if (Test-Path $c) { return $c } }
  $g = Get-Command bash -ErrorAction SilentlyContinue
  if ($g) { return $g.Source }
  return $null
}

function Show-Help {
  @"
Agent Protocol CLI (Windows)

  agent-protocol version
  agent-protocol home
  agent-protocol init [--adapters none|all|claude,cursor] [--force]
  agent-protocol update [--force]
  agent-protocol upgrade
  agent-protocol help

With Git Bash installed, also:
  agent-protocol doctor | status | resume | test | stress | new | task | ...
"@
}

function Update-Project {
  param([switch]$Force)
  $target = (Get-Location).Path
  if (-not (Test-Path (Join-Path $target "AGENTS.md")) -and -not (Test-Path (Join-Path $target ".agents"))) {
    Write-Host "ERROR: not an Agent Protocol project. Run: agent-protocol init" -ForegroundColor Red
    exit 1
  }
  if (-not (Test-Path (Join-Path $Pkg "AGENTS.md"))) {
    Write-Host "ERROR: global package missing at $Pkg — run install-global.ps1" -ForegroundColor Red
    exit 1
  }
  if ((Resolve-Path $Pkg).Path -eq (Resolve-Path $target).Path) {
    Write-Host "ERROR: package == project; reinstall global package" -ForegroundColor Red
    exit 1
  }
  Write-Host "=== Update protocol in project ===" -ForegroundColor Cyan
  Write-Host "  package: $Pkg"
  Write-Host "  target : $target"
  Write-Host "  force  : $Force"

  Copy-Item -Force (Join-Path $Pkg "AGENTS.md") (Join-Path $target "AGENTS.md")
  Write-Host "  + AGENTS.md"
  $srcScripts = Join-Path $Pkg ".agents\scripts"
  $dstScripts = Join-Path $target ".agents\scripts"
  New-Item -ItemType Directory -Force -Path $dstScripts | Out-Null
  Copy-Item -Recurse -Force "$srcScripts\*" $dstScripts
  Write-Host "  + .agents/scripts/"
  foreach ($sub in @("skills","agents","rules","templates")) {
    $s = Join-Path $Pkg ".agents\$sub"
    if (Test-Path $s) {
      $d = Join-Path $target ".agents\$sub"
      New-Item -ItemType Directory -Force -Path $d | Out-Null
      Copy-Item -Recurse -Force "$s\*" $d
      Write-Host "  + .agents/$sub/"
    }
  }
  "1.0.0" | Set-Content -Encoding ascii (Join-Path $target ".agents\PROTOCOL_VERSION")
  if ($Force) {
    if (Test-Path (Join-Path $Pkg "adapters")) {
      $d = Join-Path $target "adapters"
      New-Item -ItemType Directory -Force -Path $d | Out-Null
      Copy-Item -Recurse -Force (Join-Path $Pkg "adapters\*") $d
      Write-Host "  + adapters/"
    }
    foreach ($f in @("CLAUDE.md","GEMINI.md")) {
      $s = Join-Path $Pkg $f
      if (Test-Path $s) { Copy-Item -Force $s (Join-Path $target $f); Write-Host "  + $f" }
    }
  }
  Write-Host "  keep: plans/ (untouched)"
  Write-Host "=== Project protocol updated ===" -ForegroundColor Green
}

function Install-Init {
  $adapters = "none"
  $force = $false
  $name = Split-Path (Get-Location).Path -Leaf
  $i = 0
  while ($i -lt $Rest.Count) {
    switch ($Rest[$i]) {
      "--adapters" { $i++; $adapters = $Rest[$i] }
      "--force" { $force = $true }
      "--here" { }
      "--non-interactive" { }
      "--name" { $i++; $name = $Rest[$i] }
      default { }
    }
    $i++
  }
  $env:AP_ADAPTERS = $adapters
  if ($force) { $env:AP_FORCE = "1" }
  $env:AP_NONINTERACTIVE = "1"
  # Re-use install-remote.ps1 logic by invoking packaged copy if present
  $remote = Join-Path $Pkg "install-remote.ps1"
  if (Test-Path $remote) {
    # Minimal inline: copy core files from global package
    $target = (Get-Location).Path
    Write-Host "=== init from global package ===" -ForegroundColor Cyan
    Copy-Item -Force (Join-Path $Pkg "AGENTS.md") (Join-Path $target "AGENTS.md")
    if (Test-Path (Join-Path $target ".agents")) {
      if ($force) { Remove-Item -Recurse -Force (Join-Path $target ".agents") }
      else { Write-Host "  skip: .agents exists (use --force)" }
    }
    if (-not (Test-Path (Join-Path $target ".agents"))) {
      Copy-Item -Recurse -Force (Join-Path $Pkg ".agents") (Join-Path $target ".agents")
    } else {
      # refresh scripts
      Copy-Item -Recurse -Force (Join-Path $Pkg ".agents\scripts\*") (Join-Path $target ".agents\scripts")
    }
    if ($adapters -match "all|claude") {
      Copy-Item -Force (Join-Path $Pkg "CLAUDE.md") (Join-Path $target "CLAUDE.md") -ErrorAction SilentlyContinue
    }
    if ($adapters -match "all|gemini") {
      Copy-Item -Force (Join-Path $Pkg "GEMINI.md") (Join-Path $target "GEMINI.md") -ErrorAction SilentlyContinue
    }
    if (-not (Test-Path (Join-Path $target "plans\context.md"))) {
      New-Item -ItemType Directory -Force -Path (Join-Path $target "plans") | Out-Null
      @"
# Project Context

Purpose: TBD
Current Status: Bootstrapped
Critical Constraints: TBD
Active Plans: none
Known Issues: none
"@ | Set-Content -Encoding utf8 (Join-Path $target "plans\context.md")
      @"
# Session Log

## $(Get-Date -Format 'yyyy-MM-dd HH:mm') UTC — Bootstrap
- Done: init via agent-protocol (Windows)
- Resume: classify first work T0–T3
"@ | Set-Content -Encoding utf8 (Join-Path $target "plans\SESSION_LOG.md")
      foreach ($f in @("ARCH.md","TECH_STACK.md","DECISIONS.md","PATTERNS.md")) {
        "# $f`n" | Set-Content -Encoding utf8 (Join-Path $target "plans\$f")
      }
    }
    Write-Host "=== Ready (README/app source untouched) ===" -ForegroundColor Green
  } else {
    Write-Host "ERROR: package incomplete at $Pkg" -ForegroundColor Red
    exit 1
  }
}

function Upgrade-Global {
  Write-Host "=== Upgrade global package ===" -ForegroundColor Cyan
  $url = "https://raw.githubusercontent.com/$Owner/$Repo/$Ref/install-global.ps1"
  Write-Host "  re-running: $url"
  $script = Invoke-RestMethod -Uri $url
  Invoke-Expression $script
}

switch ($Command.ToLower()) {
  "help" { Show-Help }
  "-h" { Show-Help }
  "--help" { Show-Help }
  "version" {
    Write-Host "CLI: 1.0.0 (Windows PowerShell)"
    Write-Host "PKG: $Pkg"
    if (Test-Path (Join-Path $Pkg "VERSION")) {
      Write-Host "VERSION file: $((Get-Content (Join-Path $Pkg 'VERSION') -Raw).Trim())"
    }
  }
  "home" { Write-Host $Pkg }
  "update" {
    $force = $Rest -contains "--force"
    Update-Project -Force:$force
  }
  "upgrade" { Upgrade-Global }
  "self-update" { Upgrade-Global }
  "init" { Install-Init }
  default {
    $bash = Get-Bash
    if (-not $bash) {
      Write-Host "Command '$Command' needs Git Bash for .sh scripts." -ForegroundColor Yellow
      Write-Host "Install: https://git-scm.com/download/win"
      Write-Host "Or use: version | update | upgrade | init (no bash required)"
      exit 1
    }
    $cli = Join-Path $Pkg "bin\agent-protocol"
    if (-not (Test-Path $cli)) {
      Write-Host "ERROR: missing $cli" -ForegroundColor Red
      exit 1
    }
    $argLine = (@($Command) + $Rest) -join ' '
    & $bash $cli $Command @Rest
    exit $LASTEXITCODE
  }
}
