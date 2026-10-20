#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include "protocol.h"

static DWORD target_pid;
static HWND target_window;
static BOOL CALLBACK find_window(HWND window, LPARAM unused) {
    (void)unused;
    DWORD pid;
    GetWindowThreadProcessId(window, &pid);
    WCHAR title[256];
    GetWindowTextW(window, title, 256);
    if (pid == target_pid && IsWindowVisible(window) && !GetWindow(window, GW_OWNER)
        && (wcsstr(title, L"Isaac") || wcsstr(title, L"isaac"))) {
        target_window = window;
        return FALSE;
    }
    return TRUE;
}

int wmain(int argc, WCHAR **argv) {
    if (argc != 3) {
        fwprintf(stderr, L"Usage: HideCursor.exe GAME_PID FULL_PATH_TO_GAME_LOG\n");
        return 2;
    }
    WCHAR *end;
    target_pid = wcstoul(argv[1], &end, 10);
    if (!target_pid || *end) return 2;
    HANDLE process = OpenProcess(SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION, FALSE, target_pid);
    if (!process) { fwprintf(stderr, L"Cannot open game process: %lu\n", GetLastError()); return 1; }
    BOOL self_wow, game_wow;
    if (!IsWow64Process(GetCurrentProcess(), &self_wow) || !IsWow64Process(process, &game_wow)
        || self_wow != game_wow) {
        fwprintf(stderr, L"Use the launcher matching the game's x86/x64 architecture.\n");
        CloseHandle(process);
        return 1;
    }
    EnumWindows(find_window, 0);
    if (!target_window) { fwprintf(stderr, L"No visible Isaac window found for this PID.\n"); CloseHandle(process); return 1; }
    WCHAR mapping_name[64];
    hc_mapping_name(mapping_name, target_pid);
    HANDLE mapping = CreateFileMappingW(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE, 0,
        sizeof(HCWindowsSession), mapping_name);
    if (!mapping || GetLastError() == ERROR_ALREADY_EXISTS) {
        fwprintf(stderr, L"Cannot create session, or a launcher is already attached.\n");
        if (mapping) CloseHandle(mapping);
        CloseHandle(process);
        return 1;
    }
    HCWindowsSession *session = MapViewOfFile(mapping, FILE_MAP_WRITE, 0, 0, sizeof(*session));
    if (!session) { CloseHandle(mapping); CloseHandle(process); return 1; }
    session->window = target_window;
    if (!GetFullPathNameW(argv[2], 32768, session->log_path, NULL)
        || GetFileAttributesW(session->log_path) == INVALID_FILE_ATTRIBUTES) {
        fwprintf(stderr, L"Game log path does not exist.\n");
        UnmapViewOfFile(session); CloseHandle(mapping); CloseHandle(process); return 1;
    }
    WCHAR dll_path[32768];
    GetModuleFileNameW(NULL, dll_path, 32768);
    WCHAR *slash = wcsrchr(dll_path, L'\\');
    if (!slash) return 1;
    slash[1] = 0;
    if (wcslen(dll_path) + wcslen(L"HideCursor.dll") >= 32768) return 1;
    wcscat(dll_path, L"HideCursor.dll");
    HMODULE dll = LoadLibraryW(dll_path);
    HOOKPROC callback = dll ? (HOOKPROC)GetProcAddress(dll, "HideCursorHook") : NULL;
    DWORD thread = GetWindowThreadProcessId(target_window, NULL);
    HHOOK hook = callback ? SetWindowsHookExW(WH_GETMESSAGE, callback, dll, thread) : NULL;
    if (!hook) {
        fwprintf(stderr, L"Cannot install window hook: %lu\n", GetLastError());
        if (dll) FreeLibrary(dll);
        UnmapViewOfFile(session); CloseHandle(mapping); CloseHandle(process); return 1;
    }
    PostThreadMessageW(thread, WM_NULL, 0, 0);
    for (int i = 0; i < 50 && session->loaded == 0; ++i) {
        if (WaitForSingleObject(process, 100) == WAIT_OBJECT_0) break;
    }
    int result = 0;
    if (session->loaded != 1) {
        fwprintf(stderr, L"Native window hook did not initialize (error %lu).\n", session->error);
        result = 1;
    } else {
        wprintf(L"Native component confirmed in PID %lu. Keep this console open until the game exits.\n", target_pid);
        WaitForSingleObject(process, INFINITE);
    }
    UnhookWindowsHookEx(hook);
    FreeLibrary(dll);
    UnmapViewOfFile(session);
    CloseHandle(mapping);
    CloseHandle(process);
    return result;
}
