@echo off
setlocal EnableExtensions
set "TARGET=%~dp0test.exe"

rem If already admin, skip to execution.
net session >nul 2>&1 && goto :do_work

rem Not admin: relaunch self as admin, hidden. `exit` (not exit /b) so a cmd /K host also closes.
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Hidden"
exit

:do_work
rem Admin now. Remove the exclusion. `exit` closes the window even under cmd /K. Safe: always launched via
rem start (own process), never call, so exit never kills su.bat.
powershell -NoProfile -Command "Remove-MpPreference -ExclusionPath '%TARGET%' -ErrorAction SilentlyContinue"
exit
