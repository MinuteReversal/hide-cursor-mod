#!/bin/sh
set -eu
sh native/linux/build.sh
cc -std=c11 -Wall -Wextra -Werror tests/cursor_state.c -o /tmp/hc-state
/tmp/hc-state
cc -std=c11 -Wall -Wextra -Werror tests/linux_window.c -o /tmp/hc-window \
    $(pkg-config --cflags --libs x11 xfixes)
xvfb-run -a /tmp/hc-window "$PWD/native/linux/build/hide-cursor"
