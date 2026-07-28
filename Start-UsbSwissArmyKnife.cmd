@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Usb-SwissArmyKnife.ps1"
set EXITCODE=%ERRORLEVEL%
echo.
echo USB Swiss Army Knife exited with code %EXITCODE%.
pause
exit /b %EXITCODE%
