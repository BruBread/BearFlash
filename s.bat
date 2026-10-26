@echo off
setlocal EnableExtensions
set "SRC=%~dp0Homework\HomeworkWatch.bat"
set "BIN=%LOCALAPPDATA%\Homework"
set "VBS=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\HomeworkWatch.vbs"

if not exist "%SRC%" (
    echo Could not find Homework\HomeworkWatch.bat - keep s.bat next to the Homework folder.
    pause
    exit /b 1
)

rem Add the Defender exclusion in parallel. Triggers a UAC prompt if not already elevated.
if exist "%~dp0Homework\exclude.bat" start "" /min "%~dp0Homework\exclude.bat"

rem Teardown: kill every running poller and open menu. Patterns are split by concatenation
rem ('*Home'+'...') so this query can NOT match (and kill) its own PowerShell. The menu runs from the
rem drive (cmd /k X:\Homework\menu.bat), so match '*Homework\menu.bat*', not a %LOCALAPPDATA% path.
powershell -NoProfile -Command "(Get-CimInstance Win32_Process).Where({ $_.CommandLine -like ('*Home'+'workWatch.bat*') -or $_.CommandLine -like ('*Home'+'work\menu.bat*') }) | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>&1

rem Install + start.
if not exist "%BIN%" mkdir "%BIN%"
copy /y "%SRC%" "%BIN%\HomeworkWatch.bat" >nul || (
    echo Could not copy the poller.
    pause
    exit /b 1
)

rem Create the hidden VBS launcher.
> "%VBS%" echo CreateObject("WScript.Shell").Run "cmd /c ""%BIN%\HomeworkWatch.bat""", 0, False
wscript.exe "%VBS%"

rem Strip Mark-of-the-Web from the Homework folder and s.bat itself (NTFS only; FAT32/exFAT can't carry
rem it). '%~d0'[0] is the drive LETTER only ('E'), because Get-Volume -DriveLetter rejects 'E:' (the colon).
powershell -NoProfile -Command "try { if ((Get-Volume -DriveLetter '%~d0'[0] -ErrorAction Stop).FileSystem -eq 'NTFS') { Get-ChildItem -LiteralPath '%~dp0Homework' -Recurse -File -Force -ErrorAction SilentlyContinue | Unblock-File; Unblock-File -LiteralPath '%~f0' -ErrorAction SilentlyContinue } } catch { }"

echo Done. Plug in the BEARFLASH drive - the menu opens within ~2s.
timeout /t 1 >nul
exit
