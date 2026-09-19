# install-global.ps1 — Agent Protocol global install for Windows
# irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.ps1 | iex

$ErrorActionPreference = "Stop"
$Owner = if ($env:AGENT_PROTOCOL_OWNER) { $env:AGENT_PROTOCOL_OWNER } else { "MohammedAydan" }
$Repo  = if ($env:AGENT_PROTOCOL_REPO)  { $env:AGENT_PROTOCOL_REPO }  else { "agent-protocol" }
$Ref   = if ($env:AGENT_PROTOCOL_REF)   { $env:AGENT_PROTOCOL_REF }   else { "main" }
$Dest  = if ($env:AGENT_PROTOCOL_HOME)  { $env:AGENT_PROTOCOL_HOME }  else { Join-Path $env:LOCALAPPDATA "agent-protocol" }

Write-Host "=== Agent Protocol global install (Windows) ===" -ForegroundColor Cyan
Write-Host "  dest: $Dest"

$tmp = Join-Path $env:TEMP ("ap-g-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  $url = if ($Ref -eq "main" -or $Ref -eq "master") {
    "https://github.com/$Owner/$Repo/archive/refs/heads/$Ref.zip"
  } else {
    "https://github.com/$Owner/$Repo/archive/refs/tags/$Ref.zip"
  }
  $zip = Join-Path $tmp "p.zip"
  Write-Host "  download: $url"
  try { Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing }
  catch {
    Invoke-WebRequest -Uri "https://github.com/$Owner/$Repo/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing
  }
  Expand-Archive -Path $zip -DestinationPath $tmp -Force
  $pkg = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like "$Repo-*" } | Select-Object -First 1
  if (-not $pkg -or -not (Test-Path (Join-Path $pkg.FullName "AGENTS.md"))) { throw "Invalid archive" }

  if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
  New-Item -ItemType Directory -Path $Dest -Force | Out-Null
  Copy-Item -Recurse -Force (Join-Path $pkg.FullName "*") $Dest

  $shimDir = Join-Path $env:LOCALAPPDATA "agent-protocol\shims"
  New-Item -ItemType Directory -Path $shimDir -Force | Out-Null

  $bash = $null
  foreach ($c in @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
  )) { if (Test-Path $c) { $bash = $c; break } }

  # agent-protocol.cmd — runs package CLI under Git Bash
  $cliUnix = ($Dest -replace '\\','/') -replace '^([A-Za-z]):', { param($m) '/' + $m.Groups[1].Value.ToLower() }
  # Simpler: pass Windows path; Git Bash accepts it often
  $cliWin = Join-Path $Dest "bin\agent-protocol"

  $cmdLines = @()
  $cmdLines += "@echo off"
  if ($bash) {
    # %* passes all args; bash -lc runs the script with bash
    $cmdLines += "set `"AP_HOME=$Dest`""
    $cmdLines += "`"$bash`" `"$cliWin`" %*"
  } else {
    $cmdLines += "echo ERROR: Git for Windows not found. Install from https://git-scm.com/download/win"
    $cmdLines += "exit /b 1"
  }
  $cmdLines | Set-Content -Encoding ascii (Join-Path $shimDir "agent-protocol.cmd")

  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if (-not $userPath) { $userPath = "" }
  if ($userPath -notlike "*$shimDir*") {
    [Environment]::SetEnvironmentVariable("Path", ($userPath.TrimEnd(';') + ";" + $shimDir), "User")
    Write-Host "  User PATH += $shimDir" -ForegroundColor Green
  }
  $env:Path = $shimDir + ";" + $env:Path

  "1.0.0" | Set-Content -Encoding ascii (Join-Path $Dest "VERSION")

  Write-Host ""
  Write-Host "=== Installed ===" -ForegroundColor Green
  Write-Host "  Package: $Dest"
  Write-Host "  Shim   : $shimDir\agent-protocol.cmd"
  if (-not $bash) {
    Write-Host "  Install Git for Windows, then re-run this installer." -ForegroundColor Yellow
  }
  Write-Host ""
  Write-Host "  Close this window and open a NEW PowerShell, then:"
  Write-Host "    agent-protocol version"
  Write-Host "    cd your-project"
  Write-Host "    agent-protocol init --here --adapters none"
  Write-Host "    agent-protocol update"
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
