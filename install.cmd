@echo off
set ADAPTERS=%~1
if "%ADAPTERS%"=="" set ADAPTERS=all
echo Agent Protocol install (adapters=%ADAPTERS%)
set AP_ADAPTERS=%ADAPTERS%
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/MohammedAydan/agent-protocol/main/install-remote.ps1 | iex"
if errorlevel 1 exit /b 1
echo Done.
