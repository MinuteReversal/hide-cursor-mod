#!/bin/sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
game_pid=${1:-}
log_path=${2:-}
if [ -z "$game_pid" ]; then
    candidates=$(pgrep -x 'isaac\.x64|isaac-ng|isaac' || true)
    count=$(printf '%s\n' "$candidates" | awk 'NF {n++} END {print n+0}')
    if [ "$count" -ne 1 ]; then
        echo "Start native Isaac first, or pass GAME_PID and LOG_PATH explicitly." >&2
        exit 1
    fi
    game_pid=$candidates
fi
case "$game_pid" in *[!0-9]*|'') echo "Invalid game PID" >&2; exit 1;; esac
if [ -z "$log_path" ]; then
    game_executable=$(readlink -f "/proc/$game_pid/exe")
    path_info="$(dirname "$game_executable")/savedatapath.txt"
    if [ -f "$path_info" ]; then
        save_path=$(sed -n 's/^Save Data Path: *//p' "$path_info" | tr -d '\r' | head -n 1)
        if [ -n "$save_path" ]; then log_path="$save_path/log.txt"; fi
    fi
fi
if [ -z "$log_path" ] || [ ! -f "$log_path" ]; then
    echo "Pass GAME_PID and the active log.txt path from savedatapath.txt." >&2
    exit 1
fi
if [ ! -x "$script_dir/build/hide-cursor" ]; then
    echo "Build the helper first: sh $script_dir/build.sh" >&2
    exit 1
fi
exec "$script_dir/build/hide-cursor" "$game_pid" "$log_path"
