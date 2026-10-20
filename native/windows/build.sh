#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
for arch in x86 x64; do
    if [ "$arch" = x86 ]; then compiler=i686-w64-mingw32-gcc; else compiler=x86_64-w64-mingw32-gcc; fi
    mkdir -p "build/$arch"
    "$compiler" -std=c11 -Wall -Wextra -Werror -O2 -shared HideCursor.c \
        -Wl,--kill-at -o "build/$arch/HideCursor.dll" -luser32
    "$compiler" -std=c11 -Wall -Wextra -Werror -Wno-cast-function-type -O2 \
        -municode attach.c -o "build/$arch/HideCursor.exe" -luser32
done
