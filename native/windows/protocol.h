#ifndef HC_WINDOWS_PROTOCOL_H
#define HC_WINDOWS_PROTOCOL_H
#include <windows.h>
typedef struct {
    HWND window;
    volatile LONG loaded;
    DWORD error;
    WCHAR log_path[32768];
} HCWindowsSession;
static inline void hc_mapping_name(WCHAR *name, DWORD pid) {
    wsprintfW(name, L"Local\\HideCursor-%lu", (unsigned long)pid);
}
#endif
