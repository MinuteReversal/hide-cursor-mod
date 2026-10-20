#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "../common/log_reader.h"

// Process-local prototype: no capture, clipping, global cursor replacement,
// or hide/unhide counter. The existing Lua mod still draws aiming reticles.
static NSCursor *blankCursor;
static NSCursor *previousCursor;
static BOOL ownsCursor;
static int loggedPolicy = -1;
static HCLogReader logReader;
static NSTimeInterval nextLogPoll;

static void refreshGamePhase(void) {
    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    if (now < nextLogPoll) return;
    nextLogPoll = now + 0.1;
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:
        @"Library/Application Support/Binding of Isaac Afterbirth+/log.txt"];
    hc_poll_log(&logReader, path.fileSystemRepresentation);
}
static void restoreCursor(void) {
    if (ownsCursor && [NSCursor currentCursor] == blankCursor) {
        [(previousCursor ?: [NSCursor arrowCursor]) set];
    }
    ownsCursor = NO;
    previousCursor = nil;
}

static void updateCursor(void) {
    refreshGamePhase();
    NSPoint point = [NSEvent mouseLocation];
    NSWindow *window = [NSApp keyWindow];
    NSView *view = window.contentView;
    Class glfwView = NSClassFromString(@"GLFWContentView");
    BOOL inside = NO;
    if (NSApp.active && window.visible && !window.miniaturized &&
        glfwView && [view isKindOfClass:glfwView]) {
        NSPoint local = [view convertPoint:[window convertPointFromScreen:point] fromView:nil];
        inside = NSPointInRect(local, view.bounds) &&
            [NSWindow windowNumberAtPoint:point belowWindowWithWindowNumber:0] == window.windowNumber;
    }
    if (inside) {
        if (!ownsCursor) {
            previousCursor = [NSCursor currentCursor];
            ownsCursor = YES;
        }
        [(hc_show_system_cursor(&logReader.state) ? [NSCursor arrowCursor] : blankCursor) set];
    } else {
        restoreCursor();
    }
    int policy = inside ? (hc_show_system_cursor(&logReader.state) ? 1 : 2) : 0;
    if (policy != loggedPolicy) {
        NSLog(@"[HideCursor] %@", policy == 1 ? @"menu: visible arrow" :
            policy == 2 ? @"inside: transparent system cursor" : @"outside/inactive: released cursor");
        loggedPolicy = policy;
    }
}

// GLFW may set its arrow on every cursor update. Run after its handler too.
static void hookCursorUpdate(void) {
    Class cls = NSClassFromString(@"GLFWContentView");
    SEL selector = @selector(cursorUpdate:);
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) return;
    IMP original = method_getImplementation(method);
    IMP replacement = imp_implementationWithBlock(^(id receiver, NSEvent *event) {
        ((void (*)(id, SEL, NSEvent *))original)(receiver, selector, event);
        updateCursor();
    });
    // Add an override if the method is inherited; don't change NSView globally.
    if (!class_addMethod(cls, selector, replacement, method_getTypeEncoding(method))) {
        method_setImplementation(method, replacement);
    }
}

__attribute__((constructor)) static void initializeHideCursor(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(16, 16)];
        [image lockFocus];
        [[NSColor clearColor] set];
        NSRectFillUsingOperation(NSMakeRect(0, 0, 16, 16), NSCompositingOperationCopy);
        [image unlockFocus];
        blankCursor = [[NSCursor alloc] initWithImage:image hotSpot:NSZeroPoint];
        hookCursorUpdate();
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        for (NSString *name in @[NSApplicationDidResignActiveNotification,
                                 NSWindowDidResignKeyNotification,
                                 NSApplicationWillTerminateNotification]) {
            [center addObserverForName:name object:nil queue:[NSOperationQueue mainQueue]
                           usingBlock:^(NSNotification *note) { restoreCursor(); }];
        }
        [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0 repeats:YES
                                         block:^(NSTimer *timer) { updateCursor(); }];
        NSLog(@"[HideCursor] macOS prototype loaded (default on)");
    });
}
