#ifndef HIDE_CURSOR_STATE_H
#define HIDE_CURSOR_STATE_H
#include <stddef.h>
#include <string.h>

typedef struct {
    int in_game;
    int always_show;
    char tail[64];
    size_t tail_length;
} HCState;

static inline void hc_reset(HCState *state) { memset(state, 0, sizeof(*state)); }

// Same ASCII lifecycle/settings protocol on every platform. Keep partial
// markers across reads; unrelated and malformed lines cannot change policy.
static inline void hc_feed(HCState *state, const char *bytes, size_t length) {
    while (length) {
        char text[4161];
        size_t n = length > 4096 ? 4096 : length;
        memcpy(text, state->tail, state->tail_length);
        memcpy(text + state->tail_length, bytes, n);
        size_t total = state->tail_length + n;
        text[total] = '\0';
        for (size_t i = 0; i < total; ++i) {
            const char *p = text + i;
            if (!strncmp(p, "Hide Cursor: native phase=game", 30)) state->in_game = 1;
            if (!strncmp(p, "Hide Cursor: native phase=menu", 30)) state->in_game = 0;
            if (!strncmp(p, "Hide Cursor: native alwaysShow=1", 32)) state->always_show = 1;
            if (!strncmp(p, "Hide Cursor: native alwaysShow=0", 32)) state->always_show = 0;
        }
        state->tail_length = total > 63 ? 63 : total;
        memcpy(state->tail, text + total - state->tail_length, state->tail_length);
        bytes += n;
        length -= n;
    }
}

static inline int hc_show_system_cursor(const HCState *state) {
    // In a run, Lua draws the always-on crosshair or the necessary aim cursor.
    return !state->in_game && state->always_show;
}
#endif
