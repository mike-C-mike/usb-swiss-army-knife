@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Invoke-ProjectTests.ps1"
exit /b %ERRORLEVEL%
