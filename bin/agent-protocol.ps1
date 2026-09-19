# agent-protocol.ps1 - Windows CLI (no Git required for core commands)
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
$Pkg   = if ($env:AGENT_PROTOCOL_HOME)  {
  $env:AGENT_PROTOCOL_HOME
} elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "..\AGENTS.md")) -and (Test-Path (Join-Path $PSScriptRoot "..\.agents\scripts"))) {
  (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
} else {
  Join-Path $env:LOCALAPPDATA "agent-protocol"
}

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

function Write-Utf8File([string]$Path, [string[]]$Lines) {
  $dir = Split-Path $Path -Parent
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  $content = ($Lines -join "`n") + "`n"
  [System.IO.File]::WriteAllText($Path, $content, $utf8NoBom)
}

function Show-Help {
  Write-Host "Agent Protocol CLI (Windows)"
  Write-Host "  version | home | help"
  Write-Host "  init [--adapters none|all|claude,cursor] [--force]"
  Write-Host "  update [--force]"
  Write-Host "  upgrade"
  if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Write-Host "WARN: Git Bash not found. Commands like doctor/status/test require it." -ForegroundColor Yellow
  }
  Write-Host "With Git Bash: doctor status resume test stress new task ..."
}

function Update-Project {
  param([switch]$Force)
  $target = (Get-Location).Path
  if (-not (Test-Path (Join-Path $target "AGENTS.md")) -and -not (Test-Path (Join-Path $target ".agents"))) {
    Write-Host "ERROR: not an Agent Protocol project. Run: agent-protocol init" -ForegroundColor Red
    exit 1
  }
  if (-not (Test-Path (Join-Path $Pkg "AGENTS.md"))) {
    Write-Host "ERROR: global package missing at $Pkg" -ForegroundColor Red
    exit 1
  }
  $pkgFull = (Resolve-Path $Pkg).Path
  $tgtFull = (Resolve-Path $target).Path
  if ($pkgFull -eq $tgtFull) {
    Write-Host "ERROR: package path equals project path" -ForegroundColor Red
    exit 1
  }

  $bash = Get-Bash
  if ($bash) {
    $script = (Join-Path $Pkg ".agents\scripts\update-project.sh") -replace '\\', '/'
    if (Test-Path $script) {
      $pkgBash = $pkgFull -replace '\\', '/'
      $cmdArgs = @($script, "--from", $pkgBash, "--here")
      if ($Force) { $cmdArgs += "--force" }
      if ($Rest) {
        foreach ($r in $Rest) {
          if ($r -ne "update" -and $r -ne "--force") {
            $cmdArgs += $r
          }
        }
      }
      & $bash @cmdArgs
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
      return
    }
  }

  Write-Host "WARN: Git Bash not found; falling back to PowerShell update." -ForegroundColor Yellow
  Write-Host "=== Update protocol in project ===" -ForegroundColor Cyan
  Write-Host "  package: $Pkg"
  Write-Host "  target : $target"

  Copy-Item -Force (Join-Path $Pkg "AGENTS.md") (Join-Path $target "AGENTS.md")
  Write-Host "  + AGENTS.md"

  $srcScripts = Join-Path $Pkg ".agents\scripts"
  $dstScripts = Join-Path $target ".agents\scripts"
  New-Item -ItemType Directory -Force -Path $dstScripts | Out-Null
  if (Test-Path $srcScripts) {
    Copy-Item -Recurse -Force (Join-Path $srcScripts "*") $dstScripts
    Write-Host "  + .agents/scripts/"
  }
  foreach ($sub in @("skills", "agents", "rules", "templates")) {
    $s = Join-Path $Pkg ".agents\$sub"
    if (Test-Path $s) {
      $d = Join-Path $target ".agents\$sub"
      New-Item -ItemType Directory -Force -Path $d | Out-Null
      Copy-Item -Recurse -Force (Join-Path $s "*") $d
      Write-Host "  + .agents/$sub/"
    }
  }
  Write-Utf8File (Join-Path $target ".agents\PROTOCOL_VERSION") @("1.1.0")

  if ($Force) {
    $ad = Join-Path $Pkg "adapters"
    if (Test-Path $ad) {
      $d = Join-Path $target "adapters"
      New-Item -ItemType Directory -Force -Path $d | Out-Null
      Copy-Item -Recurse -Force (Join-Path $ad "*") $d
      Write-Host "  + adapters/"
    }
    foreach ($f in @("CLAUDE.md", "GEMINI.md")) {
      $s = Join-Path $Pkg $f
      if (Test-Path $s) {
        Copy-Item -Force $s (Join-Path $target $f)
        Write-Host "  + $f"
      }
    }
  }
  Write-Host "  keep: plans/ (untouched)"
  Write-Host "=== Project protocol updated ===" -ForegroundColor Green
}

function Install-Init {
  $adapters = "none"
  $force = $false
  $i = 0
  while ($i -lt $Rest.Count) {
    switch ($Rest[$i]) {
      "--adapters" { $i++; if ($i -lt $Rest.Count) { $adapters = $Rest[$i] } }
      "--force" { $force = $true }
      default { }
    }
    $i++
  }

  $target = (Get-Location).Path
  if (-not (Test-Path (Join-Path $Pkg "AGENTS.md"))) {
    Write-Host "ERROR: global package missing at $Pkg - re-run install-global.ps1" -ForegroundColor Red
    exit 1
  }

  $bash = Get-Bash
  if ($bash) {
    $script = (Join-Path $Pkg ".agents\scripts\init.sh") -replace '\\', '/'
    if (Test-Path $script) {
      $targetBash = (Resolve-Path $target).Path -replace '\\', '/'
      $cmdArgs = @($script, $targetBash)
      if ($force) { $cmdArgs += "--force" }
      if ($Rest) {
        foreach ($r in $Rest) {
          if ($r -ne "init" -and $r -ne "--force") {
            $cmdArgs += $r
          }
        }
      }
      & $bash @cmdArgs
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
      return
    }
  }

  Write-Host "=== init from global package ===" -ForegroundColor Cyan
  Copy-Item -Force (Join-Path $Pkg "AGENTS.md") (Join-Path $target "AGENTS.md")
  Write-Host "  + AGENTS.md"

  $dstAgents = Join-Path $target ".agents"
  if ((Test-Path $dstAgents) -and $force) {
    Remove-Item -Recurse -Force $dstAgents
  }
  if (-not (Test-Path $dstAgents)) {
    Copy-Item -Recurse -Force (Join-Path $Pkg ".agents") $dstAgents
    Write-Host "  + .agents/"
  } else {
    $ds = Join-Path $dstAgents "scripts"
    New-Item -ItemType Directory -Force -Path $ds | Out-Null
    Copy-Item -Recurse -Force (Join-Path $Pkg ".agents\scripts\*") $ds
    Write-Host "  + .agents/scripts/ (refreshed)"
  }

  $ad = Join-Path $Pkg "adapters"
  if (Test-Path $ad) {
    $d = Join-Path $target "adapters"
    if (-not (Test-Path $d)) {
      New-Item -ItemType Directory -Force -Path $d | Out-Null
      Copy-Item -Recurse -Force (Join-Path $ad "*") $d
      Write-Host "  + adapters/"
    }
  }

  if ($adapters -match "all|claude") {
    $s = Join-Path $Pkg "CLAUDE.md"
    if (Test-Path $s) { Copy-Item -Force $s (Join-Path $target "CLAUDE.md"); Write-Host "  + CLAUDE.md" }
  }
  if ($adapters -match "all|gemini") {
    $s = Join-Path $Pkg "GEMINI.md"
    if (Test-Path $s) { Copy-Item -Force $s (Join-Path $target "GEMINI.md"); Write-Host "  + GEMINI.md" }
  }

  $ctx = Join-Path $target "plans\context.md"
  if (-not (Test-Path $ctx)) {
    $plans = Join-Path $target "plans"
    New-Item -ItemType Directory -Force -Path $plans | Out-Null
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
    Write-Utf8File $ctx @(
      "# Project Context"
      ""
      "Purpose: TBD"
      "Current Status: Bootstrapped"
      "Critical Constraints: TBD"
      "Active Plans: none"
      "Known Issues: none"
      ""
    )
    Write-Utf8File (Join-Path $plans "ARCH.md") @(
      "# Architecture"
      ""
      "## High-level"
      "TBD"
      ""
      "## Key modules"
      "TBD"
      ""
    )
    Write-Utf8File (Join-Path $plans "TECH_STACK.md") @(
      "# Tech Stack"
      ""
      "| Layer | Choice | Version | Reason |"
      "|-------|--------|---------|--------|"
      "| Language | TBD |  |  |"
      "| Framework | TBD |  |  |"
      "| DB | TBD |  |  |"
      "| Testing | TBD |  |  |"
      ""
    )
    Write-Utf8File (Join-Path $plans "DECISIONS.md") @(
      "# Architecture Decision Records"
      ""
      "<!-- ADR-NNN: Date / Status / Context / Decision / Alternatives / Consequences -->"
      ""
    )
    Write-Utf8File (Join-Path $plans "PATTERNS.md") @(
      "# Patterns"
      ""
      "<!-- Problem / Solution / Example / Gotchas -->"
      ""
    )
    Write-Utf8File (Join-Path $plans "SESSION_LOG.md") @(
      "# Session Log"
      ""
      ("## " + (Get-Date -Format 'yyyy-MM-dd HH:mm UTC') + " - Bootstrap")
      "- Done: Created initial plans/ brain"
      "- Decisions: none yet"
      "- Files: context ARCH TECH_STACK DECISIONS PATTERNS SESSION_LOG"
      "- Resume: classify first work (T0-T3) then start"
    )
    Write-Host "  + plans/"
  }

  Write-Host "=== Ready (README and app source untouched) ===" -ForegroundColor Green
}

function Upgrade-Global {
  Write-Host "=== Upgrade global package ===" -ForegroundColor Cyan
  $url = "https://raw.githubusercontent.com/$Owner/$Repo/$Ref/install-global.ps1"
  Write-Host "  $url"
  $script = Invoke-RestMethod -Uri $url
  Invoke-Expression $script
}

switch ($Command.ToLower()) {
  "help" { Show-Help }
  "-h" { Show-Help }
  "--help" { Show-Help }
  "version" {
    Write-Host "CLI: 1.1.0 (Windows PowerShell)"
    Write-Host "PKG: $Pkg"
    $vf = Join-Path $Pkg "VERSION"
    if (Test-Path $vf) {
      Write-Host ("VERSION file: " + ((Get-Content $vf -Raw).Trim()))
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
      Write-Host "Command '$Command' needs Git Bash." -ForegroundColor Yellow
      Write-Host "Install: https://git-scm.com/download/win"
      Write-Host "Or use without Git: version | home | init | update | upgrade | help"
      exit 1
    }
    $cli = Join-Path $Pkg "bin\agent-protocol"
    if (-not (Test-Path $cli)) {
      Write-Host "ERROR: missing $cli" -ForegroundColor Red
      exit 1
    }
    & $bash $cli $Command @Rest
    exit $LASTEXITCODE
  }
}
