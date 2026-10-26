@echo off
setlocal enabledelayedexpansion
title root@homework: ~

rem ANSI colors (Windows 10/11 cmd supports VT sequences). %E% is the ESC char.
for /f %%a in ('echo prompt $E^| cmd') do set "E=%%a"
set "R=%E%[0m"
set "G=%E%[1;92m"
set "DG=%E%[32m"
set "D=%E%[90m"
set "W=%E%[1;97m"
set "C=%E%[1;96m"
set "Y=%E%[1;93m"
set "RED=%E%[1;91m"
set "LIST=%~dp0items.txt"
rem Unplug-close is handled by the poller (HomeworkWatch.bat), which closes this menu when the drive is removed.

rem ====================================================================
rem  Built-in entries (cannot be deleted from the menu - edit here).
rem  Format:  call :add "Title"  "path.bat"   (path relative to this folder)
rem ====================================================================
:build
set "n=0"
call :add "Test"            "test.bat"
set "builtins=%n%"
rem --- saved entries (items.txt: one "Title|path.bat" per line) ---
if exist "%LIST%" for /f "usebackq tokens=1,* delims=|" %%a in ("%LIST%") do call :add "%%a" "%%b"
goto menu

:add
set /a n+=1
set "name[%n%]=%~1"
set "path[%n%]=%~2"
goto :eof

:menu
cls
echo(
echo   %G%:: HOMEWORK//QUICKSTART %D%v2.0 %G%::::::::::::::::::::::::%R%
echo(
echo   %D%  session %DG%  %USERNAME%@%COMPUTERNAME%%R%
echo   %D%  uplink  %DG%  %date% %time:~0,8%%R%
echo   %D%  modules %DG%  !n! loaded%R%
echo(
echo   %DG%--------------------------------------------------%R%
for /l %%i in (1,1,%n%) do ( set "p=0%%i" & echo     %D%[%G%!p:~-2!%D%]%R%  %W%!name[%%i]!%R% )
echo   %DG%--------------------------------------------------%R%
echo     %G%[P]%D% save   %G%[O]%D% delete   %G%[S]%D% sort   %RED%[0]%D% uninstall   %G%[Q]%D% exit%R%
echo(
set "sel="
set /p "sel=  %G%root@homework%R%:%C%~%R%$ "
if /i "!sel!"=="Q" exit
if /i "!sel!"=="P" goto padd
if /i "!sel!"=="O" goto odel
if /i "!sel!"=="S" goto sortdev
if "!sel!"=="0" ( set "target=su.bat" & goto run )
rem accept "01" as well as "1"
if "!sel:~0,1!"=="0" set "sel=!sel:~1!"
for /l %%i in (1,1,%n%) do if "!sel!"=="%%i" ( set "target=!path[%%i]!" & goto run )
goto menu

:padd
echo(
set "chain="
:padd_more
set "src="
set /p "src=  %G%[?]%D% file to run/open (drag it onto this window): %R%"
if not defined src goto padd_done
set "src=!src:"=!"
if not exist "!src!" echo   %RED%[x]%R% not found: !src! & pause >nul & goto padd_more
rem Copy it into this folder so it is saved on the drive (ignore "same file" if already here). Any type.
copy /y "!src!" "%~dp0" >nul 2>&1
for %%f in ("!src!") do set "bn=%%~nxf"
if defined chain (set "chain=!chain!|!bn!") else (set "chain=!bn!")
echo   %G%[+]%R% added %W%!bn!%R%
set "ans="
set /p "ans=  %G%[?]%D% chain another file to run after it? (y/N): %R%"
if /i "!ans!"=="y" goto padd_more
:padd_done
if not defined chain goto menu
set "nm="
set /p "nm=  %G%[?]%D% label: %R%"
if not defined nm goto menu
>>"%LIST%" echo !nm!^|!chain!
echo   %G%[+]%R% module saved: %W%!nm!%R%
timeout /t 1 >nul
goto build

:odel
echo(
set "num="
set /p "num=  %G%[?]%D% delete entry #: %R%"
if not defined num goto menu
if "!num:~0,1!"=="0" set "num=!num:~1!"
set /a chk=num 2>nul
if not "!chk!"=="!num!" goto menu
if !num! leq %builtins% echo   %Y%[x]%R% built-in - edit menu.bat to remove it & pause >nul & goto menu
if !num! gtr %n% goto menu
set /a li=num-builtins
set "tmp=%~dp0items.tmp"
del "%tmp%" 2>nul
set "c=0"
for /f "usebackq delims=" %%L in ("%LIST%") do (
  set /a c+=1
  if not "!c!"=="!li!" >>"%tmp%" echo %%L
)
if exist "%tmp%" ( move /y "%tmp%" "%LIST%" >nul ) else ( del "%LIST%" 2>nul )
echo   %G%[-]%R% entry purged
timeout /t 1 >nul
goto build

:sortdev
rem Sort loose files into Homework\Devices\<COMPUTERNAME>\. sort.bat sits in this Homework folder.
echo(
if exist "%~dp0sort.bat" ( call "%~dp0sort.bat" ) else echo   %RED%[x]%R% sort.bat not found in the Homework folder & pause >nul
goto build

:run
rem target is a chain: one or more files separated by | . Run each in order, waiting for each to finish.
echo(
echo   %DG%--------------------------------------------------%R%
set "chain=!target!"
:run_next
for /f "tokens=1* delims=|" %%x in ("!chain!") do ( set "one=%%x" & set "chain=%%y" & call :runone )
if defined chain goto run_next
echo   %DG%--------------------------------------------------%R%
echo   %G%[+]%D% chain finished - any key to return%R%
pause >nul
goto menu

:runone
rem Run/open one file by its type: .bat/.cmd inline (call), anything else via its default program.
set "full=%~dp0!one!"
if not exist "!full!" ( echo   %RED%[x]%R% missing: !one! & goto :eof )
echo   %G%[*]%D% run %W%!one!%R%
if /i "!one:~-4!"==".bat" ( call "!full!" & goto :eof )
if /i "!one:~-4!"==".cmd" ( call "!full!" & goto :eof )
start "" /wait "!full!"
goto :eof
