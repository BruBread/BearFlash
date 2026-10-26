@echo off
rem Undo what s.bat did. Non-elevated. unexclude.bat is started FIRST and async (start, not call), so its
rem elevated Defender work runs in parallel with the uninstall below instead of after it.
if exist "%~dp0unexclude.bat" start "" /min "%~dp0unexclude.bat"

rem Old admin install (rare): scheduled task + %ProgramData% files. Only runs if that task still exists.
schtasks /query /tn "HomeworkAutorun" >nul 2>&1 && powershell -NoProfile -Command "Start-Process -Verb RunAs -Wait -WindowStyle Hidden cmd -ArgumentList '/c schtasks /delete /tn HomeworkAutorun /f & del /q \"%ProgramData%\Homework*.*\"'"

rem Instant file ops: drop the Startup launcher and the deployed poller copy.
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\HomeworkWatch.vbs" >nul 2>&1
rd /s /q "%LOCALAPPDATA%\Homework" >nul 2>&1

rem ONE PowerShell call (one cold start): stop any running poller, then on NTFS re-block Homework + s.bat.
powershell -NoProfile -Command "(Get-CimInstance Win32_Process).Where({ $_.CommandLine -like ('*Home'+'workWatch.bat*') }) | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }; if ((Get-Volume -DriveLetter '%~d0'[0]).FileSystem -eq 'NTFS') { @(Get-ChildItem -LiteralPath '%~dp0' -Recurse -File -Force -ErrorAction SilentlyContinue) + @(Get-Item -LiteralPath '%~dp0..\s.bat' -Force -ErrorAction SilentlyContinue) | ForEach-Object { Set-Content -LiteralPath $_.FullName -Stream Zone.Identifier -Value \"[ZoneTransfer]`r`nZoneId=3\" -ErrorAction SilentlyContinue } }" >nul 2>&1

echo Undone. Autorun removed. Closing...
timeout /t 1 >nul
rem Close any leftover menu window(s) via a detached hidden PowerShell that outlives this exit, then close
rem this window. Pattern is split by concatenation so the helper can't match (and kill) itself.
start "" powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Milliseconds 300; (Get-CimInstance Win32_Process).Where({ $_.CommandLine -like ('*Home'+'work*menu.bat*') }) | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
exit
