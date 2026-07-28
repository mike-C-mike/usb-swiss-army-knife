@echo off
setlocal
set "REPO_ROOT=%~dp0."
cd /d "%REPO_ROOT%"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%REPO_ROOT%\tools\Invoke-ProjectTests.ps1" -RepositoryRoot "%REPO_ROOT%"
exit /b %ERRORLEVEL%
