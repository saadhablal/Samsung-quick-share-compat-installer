@echo off
setlocal
cd /d "%~dp0"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\Install-QuickShareCompat.ps1" -PauseWhenFinished
exit /b %errorlevel%

