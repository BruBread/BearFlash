@echo off
setlocal enabledelayedexpansion
rem sort.bat - lives inside the Homework folder. Sorts this device's loose files into
rem Homework\Devices\<device>\ so you can tell which files belong to which PC. Moves every file in
rem this Homework folder EXCEPT programs (.bat, .exe), items.txt, and watch.lock. Same-volume move =
rem instant. Optional arg overrides the device name:
rem   sort.bat            -> uses %COMPUTERNAME%
rem   sort.bat FrontDesk  -> uses "FrontDesk"
set "DEV=%~1"
if not defined DEV set "DEV=%COMPUTERNAME%"
set "HOMEDIR=%~dp0"
set "DEST=%HOMEDIR%Devices\%DEV%"
if not exist "%DEST%" mkdir "%DEST%"

set /a moved=0
rem for %%F over a wildcard matches FILES only, never folders, so the Devices\ subfolder is never swept.
for %%F in ("%HOMEDIR%*") do (
  set "keep="
  if /i "%%~xF"==".bat" set "keep=1"
  if /i "%%~xF"==".exe" set "keep=1"
  if /i "%%~nxF"=="items.txt" set "keep=1"
  if /i "%%~nxF"=="watch.lock" set "keep=1"
  if /i "%%~nxF"=="boot.log" set "keep=1"
  if not defined keep ( move "%%F" "%DEST%\" >nul 2>&1 && set /a moved+=1 )
)
echo Sorted !moved! file(s) into Devices\%DEV%\
timeout /t 2 >nul
