# install-global.ps1 — Agent Protocol global install for Windows (PowerShell-native CLI)
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

  # Ensure PS CLI exists even if archive was old
  $psCli = Join-Path $Dest "bin\agent-protocol.ps1"
  if (-not (Test-Path $psCli)) {
    Write-Host "WARNING: agent-protocol.ps1 missing in package" -ForegroundColor Yellow
  }

  $shimDir = Join-Path $env:LOCALAPPDATA "agent-protocol\shims"
  New-Item -ItemType Directory -Path $shimDir -Force | Out-Null

  # agent-protocol.cmd → PowerShell CLI (no Git Bash required)
  $cmdFile = Join-Path $shimDir "agent-protocol.cmd"
  $ps1 = Join-Path $Dest "bin\agent-protocol.ps1"
  @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$ps1" %*
"@ | Set-Content -Encoding ascii $cmdFile

  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if (-not $userPath) { $userPath = "" }
  if ($userPath -notlike "*$shimDir*") {
    [Environment]::SetEnvironmentVariable("Path", ($userPath.TrimEnd(';') + ";" + $shimDir), "User")
    Write-Host "  User PATH += $shimDir" -ForegroundColor Green
  }
  $env:Path = $shimDir + ";" + $env:Path

  "1.0.0" | Set-Content -Encoding ascii (Join-Path $Dest "VERSION")

  $bashOk = $false
  foreach ($c in @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
  )) { if (Test-Path $c) { $bashOk = $true; break } }

  Write-Host ""
  Write-Host "=== Installed ===" -ForegroundColor Green
  Write-Host "  Package: $Dest"
  Write-Host "  Command: agent-protocol (PowerShell-native)"
  if (-not $bashOk) {
    Write-Host "  Note: Git Bash not found — version/update/upgrade/init work without it." -ForegroundColor Yellow
    Write-Host "  Optional: install Git for Windows for doctor/test/task scripts."
  }
  Write-Host ""
  Write-Host "  Open a NEW PowerShell window, then:"
  Write-Host "    agent-protocol version"
  Write-Host "    agent-protocol update"
  Write-Host "    agent-protocol upgrade"
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
