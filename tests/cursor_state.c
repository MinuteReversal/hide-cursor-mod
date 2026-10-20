#include <assert.h>
#include <stdio.h>
#include "../native/common/cursor_state.h"

int main(void) {
    HCState state = {0};
    assert(!hc_show_system_cursor(&state));
    const char *stream = "noise\nHide Cursor: native alwaysShow=1\n"
        "Hide Cursor: native phase=game\nHide Cursor: native phase=menu\n";
    // All split positions exercise partial markers, including the last value.
    for (size_t split = 0; split <= strlen(stream); ++split) {
        hc_reset(&state);
        hc_feed(&state, stream, split);
        hc_feed(&state, stream + split, strlen(stream) - split);
        assert(state.always_show && !state.in_game && hc_show_system_cursor(&state));
    }
    hc_reset(&state);
    for (size_t i = 0; i < strlen(stream); ++i) hc_feed(&state, stream + i, 1);
    assert(hc_show_system_cursor(&state));
    const char *game = "Hide Cursor: native phase=game";
    hc_feed(&state, game, strlen(game));
    assert(!hc_show_system_cursor(&state));
    const char *off = "Hide Cursor: native alwaysShow=0";
    hc_feed(&state, off, strlen(off));
    assert(!state.always_show && !hc_show_system_cursor(&state));
    const char *menu = "Hide Cursor: native phase=menu";
    hc_feed(&state, menu, strlen(menu));
    assert(!hc_show_system_cursor(&state));
    const char *bad = "Hide Cursor: native alwaysShow=x";
    hc_feed(&state, bad, strlen(bad));
    assert(!state.always_show);
    hc_reset(&state);
    puts("PASS: shared cursor policy, all stream split positions, bytewise reads, malformed settings");
    return 0;
}
