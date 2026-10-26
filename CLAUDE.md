# BearFlash: USB quickstart menu

A flash drive labeled `BEARFLASH` that opens a terminal-style menu of `.bat` shortcuts when it's plugged into a Windows 11 laptop. Built because setting up laptops by hand at a booth was too slow. One-time setup per laptop (`s.bat`), then plug in → menu.

## Rules from the user
- Never commit or push until the user says so.
- No `Co-Authored-By` trailer and no Claude credit in commits.
- The user restyled `menu.bat` by hand (green `root@homework` terminal look). Don't redesign it without asking; make targeted edits only.
- Wants flashy but fast. No sleeps or animations that slow startup.

## Layout
This folder mirrors the drive root:
```
s.bat                  setup / clean restart (run once per laptop, no admin)
Homework\menu.bat      the menu
Homework\HomeworkWatch.bat   background poller (s.bat deploys it)
Homework\su.bat        uninstall (menu option [0])
Homework\sort.bat      sorts loose files into Homework\Devices\<COMPUTERNAME>\ (menu option [S])
Homework\exclude.bat   adds a Defender exclusion for Homework\test.exe (self-elevates); s.bat calls it
Homework\unexclude.bat removes that exclusion (self-elevates); su.bat calls it
Homework\test.bat      sample entry
```
exclude/unexclude are a SEPARATE concern (per-PC Defender exclusions, admin) from the menu install.
s.bat runs exclude.bat at the end, su.bat runs unexclude.bat at the end - each throws its own UAC prompt,
while s.bat/su.bat themselves stay non-elevated. They target `%~dp0test.exe` on the drive (test file for now).
Everything lives in `Homework\` except `s.bat`. The drive is shared storage (phone/SD card with DCIM, Music, LWeek2026, ...): never touch anything outside `s.bat` and `Homework\`.

On the drive only, never in this folder: `Homework\items.txt` (the user's saved entries), files they saved through `[P]`, `Homework\Devices\`, and `Homework\boot.log` (auto-boot log). Never overwrite or delete them.

## How it works
1. `s.bat` (per-user, no admin, no UAC): kills every running poller and open menu, copies `HomeworkWatch.bat` to `%LOCALAPPDATA%\Homework\`, writes `HomeworkWatch.vbs` to the user's Startup folder (runs the poller hidden at logon), starts it now, then runs `Unblock-File` on `Homework\` (recursive) and itself so SmartScreen stops warning. Every run is a full clean restart. `su.bat` reverses all of it, including re-adding the `Zone.Identifier` stream (ZoneId=3) to the same files only.
2. Poller: every 2 s it scans drive letters D–Z with `vol` for the label `BEARFLASH` (pure batch, no PowerShell, so it's fast). When it finds the drive it runs `start "HOMEWORK" cmd /k X:\Homework\menu.bat`, appends one line (date, COMPUTERNAME, user, drive) to `Homework\boot.log` on the drive, then waits (1 s checks) until the drive is gone and closes the menu by killing processes whose command line matches `*Homework*menu.bat*` (PowerShell CIM). `boot.log` is excluded from sort.bat. Single instance via a `9>"%~dp0watch.lock"` handle lock.
3. Menu: built-in entries are `call :add "Title" "file.bat"` lines; saved entries are in `items.txt`, one `Title|file1|file2|...` per line (a chain). `[P]` save: drag in any file type (copied into Homework), optionally chain more files that run after it, then a label. Running an entry runs the chain in order: `.bat`/`.cmd` via `call`, anything else via `start "" /wait` (default program). `[O]` delete (saved entries only, whole chain), `[S]` runs `sort.bat`, `[0]` runs `su.bat`, `[Q]` is `exit` (closes the window). Colors are ANSI via an ESC char captured with `echo prompt $E| cmd`.
   `sort.bat` moves every file directly in `Homework\` except `.bat`, `.exe`, `items.txt` and `watch.lock` into `Homework\Devices\<COMPUTERNAME>\` (optional arg overrides the name). A file moved this way no longer runs from its old `[P]` entry.
4. Migration: older versions installed an admin scheduled task `HomeworkAutorun` plus `%ProgramData%\Homework*` files. `s.bat` and `su.bat` remove them with one elevated `schtasks /delete` + `del` if that task still exists.

## Hard-won facts (don't relearn these)
- Windows 11 ignores `autorun.inf` on USB drives. Nothing on the stick alone can run on insert; per-laptop setup is unavoidable.
- The USB-insert event trigger (DriverFrameworks-UserMode Event ID 2003) was dropped: event IDs depend on the driver (one laptop logs 2100–2106). Polling works on every machine.
- `wmic` is removed on Windows 11 24H2+. Use `vol`, or PowerShell `Get-Volume` / CIM.
- Elevated vs non-elevated runs caused "stacking" (several pollers, several menus): different tokens, different `%TEMP%`, so the lock didn't dedupe. Keep everything non-elevated.
- Window-title matching is unreliable. Elevated windows are titled `Administrator:  ...`; `tasklist /fi "WINDOWTITLE eq ..."` missed a window that existed; capturing your own PID via a title marker failed because `tasklist /v` doesn't see a new title immediately. Kill by command line instead.
- A CIM query matches itself if its own command line contains the search text. Build patterns by concatenation: `('*Home'+'workWatch.bat*')`.
- Inside `for /f ('...')`: no pipes (use `.Where({...})`) and no `-Filter "Name='cmd.exe'"` (the `=` gets mangled).
- Batch: `if X ( set ... & goto y )` needs the parens, or the `goto` runs unconditionally. `|` inside `%%L` / `!var!` data is literal; write a literal pipe to a file with `^|`.
- SmartScreen ("Windows protected your PC") is a reputation check on files carrying Mark-of-the-Web, separate from Defender antivirus. Defender exclusions don't affect it; `Unblock-File` does. Scripts can't turn Defender's real-time protection off (Tamper Protection), so don't try.
- Leftover-window bug (recurring): a bat hosted by `cmd /K` stays at a prompt after the script ends. `exit /b` only ends the script, NOT the window; `exit` closes the window under both `/c` and `/k`. Self-elevating bats (exclude.bat, unexclude.bat) must end every branch with `exit`, never `exit /b` — including the non-admin relaunch branch. `exit` is safe ONLY because s.bat/su.bat launch them via `start` (own process), never `call`. If you ever switch to `call`, `exit` would kill the parent — change the launch, don't revert to `exit /b`. su.bat also spawns a detached hidden PowerShell to close leftover menu windows (`cmd /k ...menu.bat`).
- The BEARFLASH drive is FAT32. FAT32/exFAT have no alternate data streams, so files on the drive can't carry Mark-of-the-Web (Windows strips it on copy). `s.bat`/`su.bat` check `Get-Volume ... FileSystem` and skip unblock/reblock unless the drive is NTFS.

## Testing in Claude Code
- Shells here have no console window: `tasklist /v` shows titles as N/A, so title/PID tricks can't be verified here, only on a real window.
- Never pipe several answers into the menu's `set /p` prompts. At EOF it loops forever and the command hangs. Pipe just `Q`, or test logic in a small scratch `.bat`.
- Git Bash's `find` shadows `find.exe`. Run test `.bat` files through PowerShell `cmd /c`, and use `.\menu.bat` (a bare `menu.bat` isn't found).
- `taskkill` is blocked by the auto-mode classifier. Stop your own background commands with TaskStop.
- Don't run `s.bat` / `su.bat` yourself (they change the system and may prompt UAC); the user runs them.

## Syncing to the drive
The user asks "sync to drive" often. Find the drive by label, then copy `s.bat` to its root and `Homework\*.bat` into its `Homework\`, and compare hashes:
```powershell
$d = (Get-Volume -FileSystemLabel BEARFLASH).DriveLetter + ':'
```
The letter varies (`E:` here, `D:` on other laptops). Don't touch `items.txt`. Don't copy `CLAUDE.md` to the drive.

## Known limits / open ideas
- Unplug-close only covers menus the poller opened; a double-clicked menu stays open.
- Startup apps can be disabled in Task Manager, and some antivirus flags `.vbs` in Startup.
- The drive is matched by label, which anyone can copy. Matching the hardware serial (`Get-Partition -DriveLetter X | Get-Disk` → `SerialNumber`) was discussed but not built.
- Run from the menu, `su.bat` needs two key presses (its own `pause` plus the menu's).
