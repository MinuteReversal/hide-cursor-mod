# Hide Cursor

Native desktop adapters for macOS, Windows x86/x64 and Linux X11/XWayland are available as a preview. See [platform setup and validation limits](native/README_zh.md). The native components require a separate launcher/helper; Workshop Lua subscription alone does not load them. A user has confirmed Windows behavior matches Mac in one real-game environment; Linux has Xvfb window tests, not real-game acceptance.

## Windows installation and startup

**Workshop subscription does not install or start the native helper.** Lua handles settings and the in-game crosshair; the native component handles the system arrow. Without the helper, the arrow may remain visible or overlap the crosshair.

1. Subscribe to and enable the updated mod. Avoid enabling multiple copies.
2. Prepare matching Windows native binaries separately: `HideCursor.exe` and `HideCursor.dll` in each of `native/windows/build/x86/` and `build/x64/`. The source repository does not include binaries; build them before using the launcher.
3. Start the game through Steam, then run `native/windows/attach.cmd`.
4. Wait for **Native component confirmed in PID ...** and keep the helper running until the game exits. Repeat after each game restart; do not attach twice to the same game process.

With the helper loaded, OFF hides the system arrow while retaining necessary aiming reticles. ON shows the system arrow in menus and the white/red crosshair in a run. Leaving the game window restores the desktop cursor. For mouse controls, set `MouseControl=1` in the active save directory's `options.ini` and restart the game.

**A one-time installer and automatic loading are planned, not implemented.** The default Lua sandbox cannot install or launch EXE/DLL files. For now, run the helper as described above; `--luadebug` is not required.



## Cursor setting

**Always Show Cursor** defaults to OFF. In a run, press **F10** to open the standalone panel, **Enter / Left / Right** to toggle, and **Esc / F10** to close. With Mod Config Menu installed, use **Hide Cursor → General** instead.

ON always draws the existing white/red crosshair in a run, including while paused, regardless of MouseControl or items. Settings persist per save slot. The panel blocks player input but does not pause the scene. The render callback is in-game only. With the macOS trial launcher, the native component shows the system arrow in main menus only when Always Show Cursor is ON. OFF hides the menu cursor too. During a run the system arrow is hidden to avoid duplicates; Lua draws the configured crosshair or necessary aiming reticle. The desktop cursor is restored on leaving the window.

**English** | [中文](README_zh.md) | [日本語](README_ja.md)

Hides the mouse cursor by replacing the game's native cursor texture with a
transparent image.

Restores a custom 64×64 crosshair (white idle / red while LMB held) only when
**both** are true:

1. `options.ini` has `MouseControl=1`
2. The player holds a mouse-aim item (list below)

**Keyboard-only and controller players** (`MouseControl=0`): no extra reticle —
the cursor stays fully hidden. Mouse input is never disabled.

| State | Cursor |
|-------|--------|
| Default (menus / normal play) | Hidden |
| Keyboard / controller (`MouseControl=0`) | Always hidden |
| `MouseControl=1` + mouse-aim item | White cross (red while LMB held) |

Mouse-aim items:

- Epic Fetus (168)
- Ludovico Technique (329)
- Marked (394)
- Doctor's Remote (47)
- Analog Stick (465)
- Spear of Destiny (400)

> The game cannot unload a resource override at runtime, so “restore” draws a
> separate sprite at the mouse position. `MouseControl` is read from
> `options.ini` (`=0` never restore; `=1` or unreadable + aim item → show).

Source: https://github.com/MinuteReversal/hide-cursor-mod

## Local testing

### 1. Enable the debug console (once)

Edit `options.ini`:

- macOS Afterbirth+:  
  `~/Library/Application Support/Binding of Isaac Afterbirth+/options.ini`
- Windows (typical):  
  `Documents/My Games/Binding of Isaac …/options.ini`

```ini
EnableDebugConsole=1
```

Restart the game.

> Enabling the console usually **disables achievements** for that save. Use a
> test save.

Optional — enable mouse aim (Epic Fetus reticle follows the mouse):

```ini
MouseControl=1
```

### 2. Open the console in-game

Press **`` ` ``** (tilde / backtick, usually below Esc).

### 3. Give items

| Command | Effect |
|---------|--------|
| `g c168` | Epic Fetus |
| `g c329` | Ludovico Technique |
| `g c394` | Marked |
| `g c47` | Doctor's Remote |
| `g c465` | Analog Stick |
| `g c400` | Spear of Destiny |
| `spawn 5.100.168` | Spawn Epic Fetus pickup |

`g` = give, `c` + id = collectible.

### 4. Test this mod

1. Enable **Hide Cursor** in the Mods menu  
2. Cursor should stay invisible by default  
3. `MouseControl=0`: after `g c168`, still **no** custom crosshair  
4. `MouseControl=1`: restart, `g c168`, crosshair at mouse (red while LMB held)  

Restart after changing `MouseControl` (read on load / run start).

Local Mods folder (Afterbirth+):

```text
~/Library/Application Support/Binding of Isaac Afterbirth+ Mods/hide cursor
```

Sync from repo:

```bash
rsync -av --exclude '.git/' --exclude '.DS_Store' \
  ~/Documents/github/hide-cursor-mod/ \
  ~/Library/Application\ Support/Binding\ of\ Isaac\ Afterbirth+\ Mods/hide\ cursor/
```

## Tools

[Open ModUploader](<~/Library/Application Support/Steam/steamapps/common/The Binding of Isaac Rebirth/tools/ModUploader/>)
