#ifndef HIDE_CURSOR_LOG_READER_H
#define HIDE_CURSOR_LOG_READER_H
#include "cursor_state.h"
#include <stdio.h>
#include <sys/stat.h>

typedef struct {
    HCState state;
    off_t offset;
    ino_t inode;
} HCLogReader;

static inline void hc_poll_log(HCLogReader *reader, const char *path) {
    struct stat info;
    if (stat(path, &info)) return;
    if (reader->inode != info.st_ino || info.st_size < reader->offset) {
        hc_reset(&reader->state);
        reader->offset = 0;
        reader->inode = info.st_ino;
    }
    if (info.st_size == reader->offset) return;
    FILE *file = fopen(path, "rb");
    if (!file) return;
    if (fseeko(file, reader->offset, SEEK_SET)) { fclose(file); return; }
    char buffer[4096];
    size_t n;
    while ((n = fread(buffer, 1, sizeof(buffer), file)) != 0) {
        hc_feed(&reader->state, buffer, n);
        reader->offset += (off_t)n;
    }
    fclose(file);
}
#endif
