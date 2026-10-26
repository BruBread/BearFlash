@echo off
rem Background poller (deployed to %LOCALAPPDATA%\Homework by s.bat, launched hidden at logon and by s.bat).
rem Scans for the BEARFLASH drive every 2s and opens its menu. No event IDs = works on any machine.
rem The 9> lock makes it single-instance: a second copy can't open the lock, so its block is skipped.
rem The lock sits next to this file (not %TEMP%), so a leftover poller from an old install can't hold it.
setlocal enabledelayedexpansion
2>nul ( 9>"%~dp0watch.lock" ( call :run ) )
exit /b

:run
:loop
set "FOUND="
for %%L in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do if not defined FOUND (
  vol %%L: 2>nul | find /i "BEARFLASH" >nul && if exist "%%L:\Homework\menu.bat" set "FOUND=%%L"
)
if defined FOUND (
  start "HOMEWORK" cmd /k "!FOUND!:\Homework\menu.bat"
  rem Log this auto-boot to the drive: one line per insertion (device, user, drive, time).
  >>"!FOUND!:\Homework\boot.log" echo !DATE! !TIME! - !COMPUTERNAME! - !USERNAME! - drive !FOUND!:
  rem Wait until the drive is removed before looping, so we open the menu once per insertion.
  :wait
  vol !FOUND!: 2>nul | find /i "BEARFLASH" >nul && ( timeout /t 1 /nobreak >nul & goto wait )
  rem Drive removed: close any open Homework menu window(s).
  powershell -NoProfile -Command "(Get-CimInstance Win32_Process).Where({ $_.CommandLine -like ('*Home'+'work*menu.bat*') }) | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>&1
)
timeout /t 2 /nobreak >nul
goto loop
