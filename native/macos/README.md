# macOS cursor prototype

Default-on native cursor hiding for the macOS Intel Afterbirth+ build. The Lua
mod provides an Always Show Cursor option (F10 or Mod Config Menu), drawing
its white/red crosshair even without an aiming item. The native component
keeps the system arrow hidden to avoid duplicate cursors. This is a local experiment, not
a Workshop-only feature or a verified borderless release.

Run `./try.command` with the game closed. Requires Xcode command-line tools,
the default Steam game path, and the existing IsaacDyldShim launch fix.
The launcher builds an x86_64 dylib and injects it for this launch only. It does
not modify the game executable, Steam launch options, or system cursor assets.
Quit this game process and launch normally to stop using the prototype.

The dylib uses a transparent NSCursor while the app is active and its GLFW
content view is the window under the pointer. It restores its previous cursor
on exit or loss of focus. Mouse capture and confinement are not used.
GLFW cursorUpdate is hooked within GLFWContentView; a main-thread timer also
rechecks window position, overlap and focus. Output is in `build/game.log`.

Validation so far: builds with warnings treated as errors, loads into the local
Afterbirth+ game, and logs inside/outside cursor transitions in windowed mode.
Still requires visual/manual checks for cursor flicker, Cmd+Tab, desktop clicks,
window controls, multi-monitor/Spaces, borderless mode, and aiming items.

The main menu displays the system arrow only when Always Show Cursor is ON.
OFF hides the menu cursor as well. Lua logs the initial and updated setting
so the native component follows the same saved preference. Lua logs explicit game-start and
game-exit markers, which all native components parse through native/common/cursor_state.h. The
macOS component follows them through the local AB+
log file. During a run (including pause), the system arrow is transparent and
the Lua setting controls the crosshair. Restart through try.command after
updating both main.lua and the dylib.
