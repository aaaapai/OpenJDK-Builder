#ifndef COMPAT_FILE_H
#define COMPAT_FILE_H

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>

#if defined(__ANDROID__) && __ANDROID_API__ < 24

#ifdef __cplusplus
extern "C" {
#endif


__attribute__((weak)) static inline off64_t ftello(FILE *stream) {
    int fd = fileno(stream);
    if (fd == -1) {
        return (off64_t)-1;
    }
    return lseek64(fd, 0, SEEK_CUR);
}

__attribute__((weak)) static inline int fseeko(FILE *stream, off64_t offset, int whence) {
    int fd = fileno(stream);
    if (fd == -1) {
        return -1;
    }
    if (lseek64(fd, offset, whence) == (off64_t)-1) {
        return -1;
    }
    fseek(stream, 0, SEEK_CUR);
    return 0;
}

#ifdef __cplusplus
}
#endif


#endif // __ANDROID_API__ < 24

#endif // COMPAT_FILE_H
