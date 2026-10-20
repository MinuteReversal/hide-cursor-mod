#define _POSIX_C_SOURCE 200809L
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/extensions/Xfixes.h>
#include <assert.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

static void settle(void) { struct timespec t = {0, 250000000}; nanosleep(&t, NULL); }
static int visible(Display *display) {
    XFixesCursorImage *image = XFixesGetCursorImage(display);
    assert(image);
    int found = 0;
    for (unsigned long i = 0; i < (unsigned long)image->width * image->height; ++i)
        if ((image->pixels[i] >> 24) & 255UL) found = 1;
    XFree(image);
    return found;
}
static void append(const char *path, const char *line) {
    FILE *file = fopen(path, "a"); assert(file);
    fprintf(file, "%s\n", line); fclose(file); settle();
}
int main(int argc, char **argv) {
    assert(argc == 2);
    Display *display = XOpenDisplay(NULL); assert(display);
    Window root = DefaultRootWindow(display);
    Window game = XCreateSimpleWindow(display, root, 100, 100, 400, 300, 0, 0, 0);
    XStoreName(display, game, "Isaac test window");
    unsigned long pid = (unsigned long)getpid();
    XChangeProperty(display, game, XInternAtom(display, "_NET_WM_PID", False),
        XA_CARDINAL, 32, PropModeReplace, (unsigned char *)&pid, 1);
    XMapWindow(display, game); XSync(display, False);
    XSetInputFocus(display, game, RevertToParent, CurrentTime);
    XWarpPointer(display, None, root, 0, 0, 0, 0, 200, 200);
    XSync(display, False);
    char path[] = "/tmp/hide-cursor-test-XXXXXX";
    int fd = mkstemp(path); assert(fd >= 0); close(fd);
    char pid_text[32]; snprintf(pid_text, sizeof(pid_text), "%lu", pid);
    pid_t helper = fork(); assert(helper >= 0);
    if (!helper) { execl(argv[1], argv[1], pid_text, path, (char *)NULL); _exit(127); }
    settle();
    assert(!visible(display)); // Default OFF: menu hidden.
    append(path, "Hide Cursor: native alwaysShow=1");
    assert(visible(display)); // Menu follows ON.
    append(path, "Hide Cursor: native phase=game");
    assert(!visible(display)); // In game Lua owns the visible crosshair.
    XWarpPointer(display, None, root, 0, 0, 0, 0, 700, 500); XSync(display, False); settle();
    assert(visible(display)); // Desktop stays visible.
    XWarpPointer(display, None, root, 0, 0, 0, 0, 200, 200);
    XSetInputFocus(display, root, RevertToParent, CurrentTime); XSync(display, False); settle();
    assert(visible(display)); // Inactive game releases its cursor override.
    XSetInputFocus(display, game, RevertToParent, CurrentTime); XSync(display, False); settle();
    assert(!visible(display));
    append(path, "Hide Cursor: native phase=menu");
    assert(visible(display));
    append(path, "Hide Cursor: native alwaysShow=0");
    assert(!visible(display));
    kill(helper, SIGTERM);
    int status; waitpid(helper, &status, 0);
    assert(WIFEXITED(status) && WEXITSTATUS(status) == 0);
    assert(visible(display)); // Normal shutdown restores the game window.
    unlink(path); XDestroyWindow(display, game); XCloseDisplay(display);
    puts("PASS: X11 cursor pixels, menu setting, game phase, desktop, focus, shutdown");
    return 0;
}
