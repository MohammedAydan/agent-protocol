# install-global.ps1 — Agent Protocol global install (Windows, PowerShell-native)
# irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-global.ps1 | iex
#
# Does NOT require Git for Windows for: version, home, init, update, upgrade

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
  try {
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
  } catch {
    $url = "https://github.com/$Owner/$Repo/archive/refs/heads/main.zip"
    Write-Host "  retry: $url"
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
  }
  Expand-Archive -Path $zip -DestinationPath $tmp -Force
  $pkg = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like "$Repo-*" } | Select-Object -First 1
  if (-not $pkg -or -not (Test-Path (Join-Path $pkg.FullName "AGENTS.md"))) {
    throw "Invalid package archive from GitHub"
  }

  if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
  New-Item -ItemType Directory -Path $Dest -Force | Out-Null
  Copy-Item -Recurse -Force (Join-Path $pkg.FullName "*") $Dest

  $ps1Path = Join-Path $Dest "bin\agent-protocol.ps1"
  if (-not (Test-Path $ps1Path)) {
    throw "Package missing bin/agent-protocol.ps1 — push latest release to GitHub main"
  }

  # Shim: always PowerShell (never requires Git Bash)
  $shimDir = Join-Path $env:LOCALAPPDATA "agent-protocol\shims"
  New-Item -ItemType Directory -Path $shimDir -Force | Out-Null
  $cmdFile = Join-Path $shimDir "agent-protocol.cmd"
  @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$ps1Path" %*
"@ | Set-Content -Encoding ascii $cmdFile

  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if (-not $userPath) { $userPath = "" }
  if ($userPath -notlike "*$shimDir*") {
    [Environment]::SetEnvironmentVariable("Path", ($userPath.TrimEnd(';') + ";" + $shimDir), "User")
    Write-Host "  User PATH += $shimDir" -ForegroundColor Green
  }
  $env:Path = $shimDir + ";" + $env:Path

  "1.0.0" | Set-Content -Encoding ascii (Join-Path $Dest "VERSION")

  Write-Host ""
  Write-Host "=== Installed (PowerShell-native, Git optional) ===" -ForegroundColor Green
  Write-Host "  Package: $Dest"
  Write-Host "  Shim   : $cmdFile"
  Write-Host ""
  Write-Host "  Open a NEW PowerShell window, then:"
  Write-Host "    agent-protocol version"
  Write-Host "    agent-protocol update"
  Write-Host "    agent-protocol upgrade"
  Write-Host "    agent-protocol init --adapters none"
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
