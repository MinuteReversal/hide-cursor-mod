#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
bash build.sh
game_dir="$HOME/Library/Application Support/Steam/steamapps/common/The Binding of Isaac Rebirth"
game_binary="$game_dir/The Binding of Isaac Rebirth.app/Contents/MacOS/The Binding of Isaac Afterbirth+"
shim="$HOME/Library/Application Support/IsaacDyldShim/isaac_dyld_shim.dylib"
loader="$HOME/Library/Application Support/Steam/Steam.AppBundle/Steam/Contents/MacOS/steamloader.dylib"
for required in "$game_binary" "$shim" "$loader"; do
    if [ ! -f "$required" ]; then
        echo "Missing: $required" >&2
        exit 1
    fi
done
prototype="$PWD/build/HideCursor.dylib"
log_path="$PWD/build/game.log"
cd "$game_dir"
export SteamAppId=250900
export SteamGameId=250900
export DYLD_INSERT_LIBRARIES="$shim:$loader:$prototype"
exec "$game_binary" > "$log_path" 2>&1
