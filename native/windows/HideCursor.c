#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#include <windows.h>
#include "protocol.h"
#include "../common/cursor_state.h"

static HMODULE module;
static HWND game_window;
static WNDPROC original_proc;
static WCHAR log_path[32768];
static HCState state;
static ULONGLONG log_offset;
static DWORD log_index_high, log_index_low;
static UINT_PTR timer;
static int visibility_balance;

static void restore_visibility(void) {
    // Undo only increments made by this component in the game's UI thread.
    while (visibility_balance > 0) { ShowCursor(FALSE); --visibility_balance; }
}

static void poll_log(void) {
    HANDLE file = CreateFileW(log_path, GENERIC_READ,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL,
        OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (file == INVALID_HANDLE_VALUE) return;
    BY_HANDLE_FILE_INFORMATION info;
    if (!GetFileInformationByHandle(file, &info)) { CloseHandle(file); return; }
    ULONGLONG size = ((ULONGLONG)info.nFileSizeHigh << 32) | info.nFileSizeLow;
    if (size < log_offset || info.nFileIndexHigh != log_index_high || info.nFileIndexLow != log_index_low) {
        hc_reset(&state);
        log_offset = 0;
        log_index_high = info.nFileIndexHigh;
        log_index_low = info.nFileIndexLow;
    }
    LARGE_INTEGER position;
    position.QuadPart = (LONGLONG)log_offset;
    if (SetFilePointerEx(file, position, NULL, FILE_BEGIN)) {
        char bytes[4096];
        DWORD n;
        while (ReadFile(file, bytes, sizeof(bytes), &n, NULL) && n) {
            hc_feed(&state, bytes, n);
            log_offset += n;
        }
    }
    CloseHandle(file);
}

static BOOL owns_pointer(void) {
    if (GetForegroundWindow() != game_window || IsIconic(game_window)) return FALSE;
    POINT point;
    RECT client;
    if (!GetCursorPos(&point)) return FALSE;
    HWND under = WindowFromPoint(point);
    if (!under || GetAncestor(under, GA_ROOT) != game_window) return FALSE;
    if (!ScreenToClient(game_window, &point) || !GetClientRect(game_window, &client)) return FALSE;
    return PtInRect(&client, point);
}

static void apply_cursor(void) {
    if (owns_pointer()) {
        if (hc_show_system_cursor(&state)) {
            SetCursor(LoadCursorW(NULL, IDC_ARROW));
            CURSORINFO info = {0};
            info.cbSize = sizeof(info);
            if (GetCursorInfo(&info) && !(info.flags & CURSOR_SHOWING)) {
                for (int i = 0; i < 64; ++i) {
                    int count = ShowCursor(TRUE);
                    ++visibility_balance;
                    if (count >= 0) break;
                }
            }
        } else {
            restore_visibility();
            SetCursor(NULL);
        }
    } else restore_visibility();
}

static void CALLBACK tick(HWND window, UINT message, UINT_PTR id, DWORD time) {
    (void)window; (void)message; (void)id; (void)time;
    poll_log();
    apply_cursor();
}

static LRESULT CALLBACK cursor_proc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
    WNDPROC previous = original_proc;
    if (message == WM_SETCURSOR && LOWORD(lparam) == HTCLIENT && owns_pointer()) {
        // Let GLFW update its bookkeeping, then choose our cursor in its UI thread.
        CallWindowProcW(previous, window, message, wparam, lparam);
        apply_cursor();
        return TRUE;
    }
    if (message == WM_NCDESTROY) {
        restore_visibility();
        KillTimer(window, timer);
        SetWindowLongPtrW(window, GWLP_WNDPROC, (LONG_PTR)previous);
        game_window = NULL;
        original_proc = NULL;
    }
    if (message == WM_KILLFOCUS || (message == WM_ACTIVATEAPP && !wparam)) restore_visibility();
    return CallWindowProcW(previous, window, message, wparam, lparam);
}

// A thread-specific Windows hook loads this DLL into only the selected game.
// Initialize the subclass and timer on that window's own message thread.
__declspec(dllexport) LRESULT CALLBACK HideCursorHook(int code, WPARAM wparam, LPARAM lparam) {
    if (code >= 0 && !game_window) {
        WCHAR name[64];
        hc_mapping_name(name, GetCurrentProcessId());
        HANDLE mapping = OpenFileMappingW(FILE_MAP_ALL_ACCESS, FALSE, name);
        if (mapping) {
            HCWindowsSession *session = MapViewOfFile(mapping, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(*session));
            if (session) {
                HWND target = session->window;
                DWORD pid = 0;
                DWORD thread = GetWindowThreadProcessId(target, &pid);
                if (pid == GetCurrentProcessId() && thread == GetCurrentThreadId()) {
                    lstrcpynW(log_path, session->log_path, 32768);
                    // The subclass must remain mapped even if the launcher closes.
                    HMODULE pinned;
                    GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_PIN |
                        GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, (LPCWSTR)module, &pinned);
                    SetLastError(0);
                    LONG_PTR previous = SetWindowLongPtrW(target, GWLP_WNDPROC, (LONG_PTR)cursor_proc);
                    if (previous) {
                        original_proc = (WNDPROC)previous;
                        game_window = target;
                        poll_log();
                        timer = SetTimer(target, 0, 100, tick);
                        if (timer) {
                            InterlockedExchange(&session->loaded, 1);
                            OutputDebugStringW(L"Hide Cursor: native hook loaded\n");
                        } else {
                            session->error = GetLastError();
                            SetWindowLongPtrW(target, GWLP_WNDPROC, (LONG_PTR)original_proc);
                            original_proc = NULL;
                            game_window = NULL;
                            InterlockedExchange(&session->loaded, -1);
                        }
                    } else {
                        session->error = GetLastError();
                        InterlockedExchange(&session->loaded, -1);
                    }
                }
                UnmapViewOfFile(session);
            }
            CloseHandle(mapping);
        }
    }
    return CallNextHookEx(NULL, code, wparam, lparam);
}

BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID reserved) {
    (void)reserved;
    if (reason == DLL_PROCESS_ATTACH) {
        module = instance;
        DisableThreadLibraryCalls(instance);
    }
    return TRUE;
}
