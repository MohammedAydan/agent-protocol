# Agent Protocol — Windows installer (interactive by default)
#
# Short:
#   irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex
#
# Skip menu (automation):
#   $env:AP_ADAPTERS="claude,cursor"; irm ... | iex
#   $env:AP_ADAPTERS="all"; irm ... | iex
#   $env:AP_NONINTERACTIVE="1"; $env:AP_ADAPTERS="none"; irm ... | iex
#
# Force refresh protocol files:
#   $env:AP_FORCE="1"; irm ... | iex

param(
  [string]$Adapters = "",
  [string]$Ref = $(if ($env:AP_REF) { $env:AP_REF } else { "main" }),
  [string]$Owner = $(if ($env:AP_OWNER) { $env:AP_OWNER } else { "MohammedAydan" }),
  [string]$Repo = $(if ($env:AP_REPO) { $env:AP_REPO } else { "agent-protocol" }),
  [string]$Name = "",
  [string]$Purpose = $(if ($env:AP_PURPOSE) { $env:AP_PURPOSE } else { "TBD" }),
  [switch]$Force,
  [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
if ($env:AP_FORCE -eq "1") { $Force = $true }
if ($env:AP_NONINTERACTIVE -eq "1") { $NonInteractive = $true }
if (-not $Adapters -and $env:AP_ADAPTERS) { $Adapters = $env:AP_ADAPTERS }
if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
  Write-Host "WARN: Git Bash not found. Commands like doctor/status/test require it." -ForegroundColor Yellow
}

$Target = (Get-Location).Path
if (-not $Name) { $Name = Split-Path $Target -Leaf }

function Show-AdapterMenu {
  Write-Host ""
  Write-Host "Which AI harness adapters to install?" -ForegroundColor Cyan
  Write-Host "  (AGENTS.md is always installed — works with many tools without adapters)"
  Write-Host ""
  Write-Host "  1) All harnesses"
  Write-Host "  2) None  (AGENTS.md only — cleanest)"
  Write-Host "  3) Claude Code"
  Write-Host "  4) Cursor"
  Write-Host "  5) GitHub Copilot"
  Write-Host "  6) Windsurf / Devin"
  Write-Host "  7) Cline"
  Write-Host "  8) Roo"
  Write-Host "  9) Codex CLI"
  Write-Host " 10) Gemini / Antigravity"
  Write-Host " 11) Custom list  (e.g. claude,cursor)"
  Write-Host ""
  Write-Host "  Tips: enter several numbers separated by comma  →  3,4"
  Write-Host "        or names                                  →  claude,cursor"
  Write-Host ""
  $choice = Read-Host "Choice [2=None]"
  if ([string]::IsNullOrWhiteSpace($choice)) { return "none" }

  $map = @{
    "1" = "all"; "2" = "none"; "3" = "claude"; "4" = "cursor"
    "5" = "copilot"; "6" = "windsurf"; "7" = "cline"; "8" = "roo"
    "9" = "codex"; "10" = "gemini"
  }

  $choice = $choice.Trim().ToLower() -replace '\s+', ''

  if ($choice -eq "11" -or $choice -eq "custom") {
    $custom = Read-Host "Enter list (claude,cursor,copilot,...)"
    if ([string]::IsNullOrWhiteSpace($custom)) { return "none" }
    return ($custom.ToLower() -replace '\s+', '')
  }

  # already a name list?
  if ($choice -match '^(all|none|[a-z]+(,[a-z]+)*)$' -and $choice -notmatch '^\d') {
    return $choice
  }

  $parts = $choice -split ','
  $names = @()
  foreach ($p in $parts) {
    if ($map.ContainsKey($p)) {
      if ($map[$p] -eq "all") { return "all" }
      if ($map[$p] -eq "none") { return "none" }
      $names += $map[$p]
    } elseif ($p -match '^(claude|cursor|copilot|windsurf|cline|roo|codex|gemini)$') {
      $names += $p
    }
  }
  if ($names.Count -eq 0) { return "none" }
  return (($names | Select-Object -Unique) -join ',')
}

# Resolve adapters: env/param wins; else interactive menu; else none (safe default)
if (-not $Adapters) {
  $canPrompt = -not $NonInteractive -and [Environment]::UserInteractive
  # Also try console host
  try {
    if ($Host.Name -eq "ConsoleHost" -or $Host.UI.RawUI) { $canPrompt = -not $NonInteractive }
  } catch {}

  if ($canPrompt) {
    $Adapters = Show-AdapterMenu
  } else {
    Write-Host "Non-interactive session and no AP_ADAPTERS set → installing AGENTS.md only (none)." -ForegroundColor Yellow
    Write-Host "  Set `$env:AP_ADAPTERS='claude,cursor' (or 'all') to choose without a menu."
    $Adapters = "none"
  }
}
$Adapters = ($Adapters.ToLower() -replace '\s+', '')

Write-Host ""
Write-Host "=== Agent Protocol (Windows) ===" -ForegroundColor Cyan
Write-Host "  target  : $Target"
Write-Host "  repo    : $Owner/$Repo@$Ref"
Write-Host "  adapters: $Adapters"
Write-Host "  force   : $Force"

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
  if (-not $pkg) { throw "Bad archive from GitHub" }

  function Copy-Proto([string]$rel) {
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

  function Want([string]$key) {
    if ($Adapters -eq "all") { return $true }
    if ($Adapters -eq "none") { return $false }
    return ($Adapters -split ',' ) -contains $key
  }

  Write-Host "Installing (README & app source untouched)..."
  Copy-Proto "AGENTS.md"
  Copy-Proto ".agents"
  # adapters folder always available for later selective sync; small
  Copy-Proto "adapters"
  if (Want "claude") { Copy-Proto "CLAUDE.md" }
  if (Want "gemini") { Copy-Proto "GEMINI.md" }
  "1.2.0" | Set-Content -Encoding ascii (Join-Path $Target ".agents\PROTOCOL_VERSION")

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

  $ad = Join-Path $pkg.FullName "adapters"
  function Install-Mirror([string]$key, [string]$srcRel, [string]$dstRel) {
    if (-not (Want $key)) { return }
    $s = Join-Path $ad $srcRel
    if (-not (Test-Path $s)) { return }
    $d = Join-Path $Target $dstRel
    $dir = Split-Path $d -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if ((Test-Path $d) -and -not $Force) { Write-Host "  skip: $dstRel"; return }
    Copy-Item $s $d -Force
    Write-Host "  + $dstRel"
  }

  Install-Mirror "cursor"  "cursor\rules.mdc"                    ".cursor\rules\agent-protocol.mdc"
  Install-Mirror "copilot" "copilot\copilot-instructions.md"      ".github\copilot-instructions.md"
  Install-Mirror "cline"   "cline\clinerules"                    ".clinerules"
  Install-Mirror "roo"     "roo\roorules"                        ".roorules"

  if (Want "windsurf") {
    $s = Join-Path $ad "windsurf\windsurfrules"
    if (Test-Path $s) {
      if ($Force -or -not (Test-Path (Join-Path $Target ".windsurfrules"))) {
        Copy-Item $s (Join-Path $Target ".windsurfrules") -Force
        New-Item -ItemType Directory -Force -Path (Join-Path $Target ".windsurf\rules") | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $Target ".devin\rules") | Out-Null
        Copy-Item $s (Join-Path $Target ".windsurf\rules\agent-protocol.md") -Force
        Copy-Item $s (Join-Path $Target ".devin\rules\agent-protocol.md") -Force
        Write-Host "  + windsurf/devin rules"
      } else { Write-Host "  skip: windsurf/devin rules" }
    }
  }

  if (Want "claude") {
    $skills = Join-Path $Target ".agents\skills"
    if (Test-Path $skills) {
      New-Item -ItemType Directory -Force -Path (Join-Path $Target ".claude\skills") | Out-Null
      New-Item -ItemType Directory -Force -Path (Join-Path $Target ".claude\agents") | Out-Null
      Get-ChildItem $skills -Directory -ErrorAction SilentlyContinue | ForEach-Object {
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

  if (Want "codex") {
    $skills = Join-Path $Target ".agents\skills"
    if (Test-Path $skills) {
      New-Item -ItemType Directory -Force -Path (Join-Path $Target ".codex\skills") | Out-Null
      Get-ChildItem $skills -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $d = Join-Path $Target ".codex\skills\$($_.Name)"
        New-Item -ItemType Directory -Force -Path $d | Out-Null
        $sk = Join-Path $_.FullName "SKILL.md"
        if (Test-Path $sk) { Copy-Item $sk (Join-Path $d "SKILL.md") -Force }
      }
      Write-Host "  + .codex mirrors"
    }
  }

  Write-Host ""
  Write-Host "=== Ready ===" -ForegroundColor Green
  Write-Host "  adapters installed: $Adapters"
  Write-Host "  README.md and app source were NOT modified."
  Write-Host "  Later (Git Bash): bash .agents/scripts/resume.sh"
  Write-Host ""
  Write-Host "  Change adapters later:"
  Write-Host "    `$env:AP_FORCE='1'; `$env:AP_ADAPTERS='claude,cursor'; irm ... | iex"
}
finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
