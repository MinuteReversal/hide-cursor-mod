#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p build
${CC:-cc} -std=c11 -Wall -Wextra -Werror -O2 hide_cursor.c -o build/hide-cursor \
    $(pkg-config --cflags --libs x11)
