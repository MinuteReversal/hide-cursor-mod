#define _POSIX_C_SOURCE 200809L
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/cursorfont.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "../common/log_reader.h"

static volatile sig_atomic_t stopping;
static void stop(int signal_number) { (void)signal_number; stopping = 1; }
static int ignore_destroyed_window(Display *display, XErrorEvent *error) {
    (void)display; (void)error;
    return 0;
}

static Window find_game(Display *display, Window parent, Atom pid_atom, unsigned long pid, int depth) {
    Atom type;
    int format;
    unsigned long count, remaining;
    unsigned char *property = NULL;
    if (XGetWindowProperty(display, parent, pid_atom, 0, 1, False, XA_CARDINAL,
        &type, &format, &count, &remaining, &property) == Success) {
        int matches = property && format == 32 && count == 1 && *(unsigned long *)property == pid;
        if (property) XFree(property);
        if (matches) {
            char *name = NULL;
            XWindowAttributes attributes;
            if (XFetchName(display, parent, &name) && name) {
                int isaac = strstr(name, "Isaac") != NULL || strstr(name, "isaac") != NULL;
                XFree(name);
                if (isaac && XGetWindowAttributes(display, parent, &attributes)
                    && attributes.map_state == IsViewable) return parent;
            }
        }
    }
    if (!depth) return None;
    Window root, owner, *children = NULL;
    unsigned int n;
    if (!XQueryTree(display, parent, &root, &owner, &children, &n)) return None;
    Window found = None;
    for (unsigned int i = 0; i < n && !found; ++i)
        found = find_game(display, children[i], pid_atom, pid, depth - 1);
    if (children) XFree(children);
    return found;
}

static int descendant(Display *display, Window child, Window ancestor) {
    for (int i = 0; child && i < 32; ++i) {
        if (child == ancestor) return 1;
        Window root, parent, *children = NULL;
        unsigned int n;
        if (!XQueryTree(display, child, &root, &parent, &children, &n)) return 0;
        if (children) XFree(children);
        if (parent == child) return 0;
        child = parent;
    }
    return 0;
}

static int pointer_inside_active_game(Display *display, Window game) {
    Window focus;
    int revert;
    XGetInputFocus(display, &focus, &revert);
    if (!descendant(display, focus, game)) return 0;
    Window root, child;
    int rx, ry, x, y;
    unsigned int mask;
    XWindowAttributes attributes;
    if (!XGetWindowAttributes(display, game, &attributes) || attributes.map_state != IsViewable
        || !XQueryPointer(display, game, &root, &child, &rx, &ry, &x, &y, &mask)) return 0;
    if (x < 0 || y < 0 || x >= attributes.width || y >= attributes.height) return 0;
    // Check the root's actual window under the pointer, not just the bounds;
    // another app/overlay can cover part of a focused game window.
    Window cursor_root, under;
    int unused_x, unused_y;
    if (!XQueryPointer(display, root, &cursor_root, &under, &rx, &ry, &unused_x, &unused_y, &mask)) return 0;
    return under && (descendant(display, game, under) || descendant(display, under, game));
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage: hide-cursor GAME_PID FULL_PATH_TO_GAME_LOG\n");
        return 2;
    }
    char *end;
    errno = 0;
    unsigned long pid = strtoul(argv[1], &end, 10);
    if (errno || !pid || *end || pid > 2147483647UL) return 2;
    FILE *probe = fopen(argv[2], "rb");
    if (!probe) { perror("Game log"); return 1; }
    fclose(probe);
    Display *display = XOpenDisplay(NULL);
    if (!display) {
        fprintf(stderr, "No X11 display. Use native Isaac under X11/XWayland; native Wayland is unsupported.\n");
        return 1;
    }
    XSetErrorHandler(ignore_destroyed_window);
    Window root = DefaultRootWindow(display);
    Atom pid_atom = XInternAtom(display, "_NET_WM_PID", False);
    Window game = find_game(display, root, pid_atom, pid, 5);
    if (!game) {
        fprintf(stderr, "No visible Isaac X11 window for PID %lu. Native Wayland/Proton is not auto-detected.\n", pid);
        XCloseDisplay(display);
        return 1;
    }
    char empty[] = {0};
    Pixmap bitmap = XCreateBitmapFromData(display, game, empty, 1, 1);
    XColor color = {0};
    Cursor blank = XCreatePixmapCursor(display, bitmap, bitmap, &color, &color, 0, 0);
    Cursor arrow = XCreateFontCursor(display, XC_left_ptr);
    XFreePixmap(display, bitmap);
    signal(SIGINT, stop);
    signal(SIGTERM, stop);
    HCLogReader reader = {0};
    int applied = 0;
    fprintf(stderr, "Attached to X11 window 0x%lx, PID %lu. Ctrl+C restores its cursor.\n", game, pid);
    while (!stopping && (kill((pid_t)pid, 0) == 0 || errno == EPERM)) {
        hc_poll_log(&reader, argv[2]);
        if (pointer_inside_active_game(display, game)) {
            XDefineCursor(display, game, hc_show_system_cursor(&reader.state) ? arrow : blank);
            applied = 1;
        } else if (applied) {
            XUndefineCursor(display, game);
            applied = 0;
        }
        XFlush(display);
        struct timespec interval = {0, 16000000};
        nanosleep(&interval, NULL);
    }
    XUndefineCursor(display, game);
    XFreeCursor(display, blank);
    XFreeCursor(display, arrow);
    XSync(display, False);
    XCloseDisplay(display);
    return 0;
}
