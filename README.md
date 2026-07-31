# Hide Cursor

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
