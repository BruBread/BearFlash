# BearFlash

A USB flash drive that opens a terminal-style quickstart menu when you plug it into a Windows 11 laptop.

Built to speed up setting up laptops by hand at a booth. You run a one-time setup per laptop, and from then on: plug in the drive → a menu of your `.bat` shortcuts appears.

---

## ⚠️ Intended use

**Use BearFlash only on computers you own or are explicitly authorized to set up.**

This tool installs a background process and a Startup entry on the machine, and (optionally) adds a Windows Defender exclusion. Those are normal, visible, user-level actions — but they are still changes to someone's computer. Running them on a device that isn't yours, or that you don't have permission to modify, is not okay.

- Test and use it on **your own devices**, or on devices whose owner has asked you to set them up.
- Do not use it to run code on machines without the owner's knowledge and consent.
- Nothing here is designed to hide itself, bypass security, or persist against the user's wishes. Everything it does is reversible (see Uninstall).

If you aren't sure whether you're allowed to run this on a given machine, don't.

---

## What makes it safe

BearFlash is deliberately built to be transparent and reversible:

- **No admin required for the core feature.** Setup, the menu, and the background poller all run as the normal user (non-elevated, no UAC for the main install). The only elevated step is an *optional* Defender exclusion, which throws its own clearly-labeled UAC prompt that you can decline.
- **It never disables your antivirus.** It cannot turn off Defender's real-time protection (Tamper Protection prevents that), and it doesn't try. The only security-related action it takes is `Unblock-File` (clearing the "downloaded from the internet" flag so SmartScreen stops warning on *these files*) and an optional, per-PC Defender exclusion that you explicitly approve.
- **It stays in its lane.** On the USB drive it only ever touches `s.bat` and the `Homework\` folder. The rest of the drive (your photos, music, documents) is never modified. On the laptop it only writes to your own user folders (`%LOCALAPPDATA%\Homework\` and your Startup folder).
- **It's fully reversible.** The uninstall (`su.bat`, also menu option `[0]`) removes the background process, the Startup entry, the local files, and — if you added it — the Defender exclusion. It restores the "downloaded from the internet" flag it cleared.
- **It's plain batch and VBScript you can read.** No compiled binaries doing hidden work, no obfuscation. Open the `.bat` files and see exactly what runs.
- **It doesn't phone home.** No network connections, no telemetry. The only thing it writes to the drive is a one-line-per-boot log (`boot.log`) recording which machines opened the menu.

---

## How it works

1. **`s.bat`** (run once per laptop, no admin): installs a small background poller to `%LOCALAPPDATA%\Homework\`, registers it to start hidden at logon, and starts it immediately.
2. **Poller**: every 2 seconds it checks for a drive labeled `BEARFLASH`. When the drive is plugged in, it opens the menu; when you unplug the drive, it closes the menu.
3. **Menu (`menu.bat`)**: a terminal-style list of your shortcuts. Add your own entries by dragging files in, delete them, or run them — all from the menu.
4. **`su.bat`**: uninstalls everything.

### Menu keys

| Key | Action |
|-----|--------|
| `[P]` | Save a new entry (drag in a file, optionally chain more files, then name it) |
| `[O]` | Delete a saved entry |
| `[S]` | Sort loose files into `Homework\Devices\<COMPUTERNAME>\` |
| `[0]` | Uninstall |
| `[Q]` | Quit (close the menu window) |

---

## Setup

1. Copy `s.bat` to the root of a USB drive labeled `BEARFLASH`, and the `Homework\` folder onto the same drive.
2. On each laptop you want to use it on, run `s.bat` once.
3. From then on, plugging the drive into that laptop opens the menu automatically.

## Uninstall

Run `su.bat`, or pick `[0]` from the menu. This removes everything BearFlash installed on that laptop and restores what it changed.

---

## Requirements

- Windows 11 (built and tested on 11 Home, 24H2+).
- A USB drive you can label `BEARFLASH`.

## Known limits

- Windows 11 ignores `autorun.inf` on USB drives, so a one-time per-laptop setup is unavoidable — nothing on the stick alone can run on insert.
- The auto-close on unplug only covers menus the poller opened; a menu you double-click open yourself stays open.
- The drive is matched by its volume label, which anyone can copy to another drive.
- The Startup entry can be disabled in Task Manager, and some antivirus flags `.vbs` files in Startup.

## License

Provided as-is, with no warranty. You are responsible for how and where you use it — see **Intended use** above.
