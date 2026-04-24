#ifndef PWD_GRP_COMPAT_H
#define PWD_GRP_COMPAT_H

#include <grp.h>
#include <pwd.h>
#include <errno.h>

#if defined(__ANDROID__) && __ANDROID_API__ <= 23

static inline int getgrgid_r(gid_t gid, struct group* grp, char* buf, size_t buflen, struct group** result) {
    (void)grp;
    (void)buf;
    (void)buflen;
    errno = 0;
    struct group* g = getgrgid(gid);
    if (g == NULL) {
        *result = NULL;
        return errno ? errno : ENOENT;
    }
    *result = g;
    return 0;
}

static inline int getgrnam_r(const char* name, struct group* grp, char* buf, size_t buflen, struct group** result) {
    (void)grp;
    (void)buf;
    (void)buflen;
    errno = 0;
    struct group* g = getgrnam(name);
    if (g == NULL) {
        *result = NULL;
        return errno ? errno : ENOENT;
    }
    *result = g;
    return 0;
}

static inline int getpwnam_r(const char* name, struct passwd* pwd, char* buf, size_t buflen, struct passwd** result) {
    (void)pwd;
    (void)buf;
    (void)buflen;
    errno = 0;
    struct passwd* p = getpwnam(name);
    if (p == NULL) {
        *result = NULL;
        return errno ? errno : ENOENT;
    }
    *result = p;
    return 0;
}

static inline int getpwuid_r(uid_t uid, struct passwd* pwd, char* buf, size_t buflen, struct passwd** result) {
    (void)pwd;
    (void)buf;
    (void)buflen;
    errno = 0;
    struct passwd* p = getpwuid(uid);
    if (p == NULL) {
        *result = NULL;
        return errno ? errno : ENOENT;
    }
    *result = p;
    return 0;
}

#endif /* __ANDROID__ && __ANDROID_API__ <= 23 */

#endif /* PWD_GRP_COMPAT_H */
