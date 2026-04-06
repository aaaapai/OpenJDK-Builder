#ifndef SIMPLE_POSIX_SPAWN_H
#define SIMPLE_POSIX_SPAWN_H

#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SIMPLE_POSIX_SPAWN_SETPGROUP   0x0001
#define SIMPLE_POSIX_SPAWN_SETSIGMASK  0x0002
#define SIMPLE_POSIX_SPAWN_SETSIGDEF   0x0004
#define SIMPLE_POSIX_SPAWN_SETSID      0x0008

enum simple_spawn_action_type {
    SIMPLE_SPAWN_OPEN,
    SIMPLE_SPAWN_CLOSE,
    SIMPLE_SPAWN_DUP2
};

struct simple_spawn_file_action {
    struct simple_spawn_file_action *next;
    int type;
    int fd;
    int new_fd;
    char *path;
    int open_flags;
    mode_t open_mode;
};

struct simple_spawn_file_actions {
    struct simple_spawn_file_action *head;
    struct simple_spawn_file_action *tail;
};

struct simple_spawn_attr {
    short flags;
    pid_t pgroup;
    sigset_t sigmask;
    sigset_t sigdefault;
};

typedef struct simple_spawn_file_actions simple_posix_spawn_file_actions_t;
typedef struct simple_spawn_attr simple_posix_spawnattr_t;

static inline int simple_posix_spawnattr_init(simple_posix_spawnattr_t *attr) {
    if (!attr) return EINVAL;
    memset(attr, 0, sizeof(*attr));
    return 0;
}

static inline int simple_posix_spawnattr_destroy(simple_posix_spawnattr_t *attr) {
    (void)attr;
    return 0;
}

static inline int simple_posix_spawnattr_setflags(simple_posix_spawnattr_t *attr, short flags) {
    if (!attr) return EINVAL;
    attr->flags = flags;
    return 0;
}

static inline int simple_posix_spawnattr_getflags(const simple_posix_spawnattr_t *attr, short *flags) {
    if (!attr || !flags) return EINVAL;
    *flags = attr->flags;
    return 0;
}

static inline int simple_posix_spawnattr_setpgroup(simple_posix_spawnattr_t *attr, pid_t pgroup) {
    if (!attr) return EINVAL;
    attr->pgroup = pgroup;
    return 0;
}

static inline int simple_posix_spawnattr_getpgroup(const simple_posix_spawnattr_t *attr, pid_t *pgroup) {
    if (!attr || !pgroup) return EINVAL;
    *pgroup = attr->pgroup;
    return 0;
}

static inline int simple_posix_spawnattr_setsigmask(simple_posix_spawnattr_t *attr, const sigset_t *mask) {
    if (!attr || !mask) return EINVAL;
    attr->sigmask = *mask;
    return 0;
}

static inline int simple_posix_spawnattr_getsigmask(const simple_posix_spawnattr_t *attr, sigset_t *mask) {
    if (!attr || !mask) return EINVAL;
    *mask = attr->sigmask;
    return 0;
}

static inline int simple_posix_spawnattr_setsigdefault(simple_posix_spawnattr_t *attr, const sigset_t *mask) {
    if (!attr || !mask) return EINVAL;
    attr->sigdefault = *mask;
    return 0;
}

static inline int simple_posix_spawnattr_getsigdefault(const simple_posix_spawnattr_t *attr, sigset_t *mask) {
    if (!attr || !mask) return EINVAL;
    *mask = attr->sigdefault;
    return 0;
}

static inline int simple_posix_spawn_file_actions_init(simple_posix_spawn_file_actions_t *actions) {
    if (!actions) return EINVAL;
    memset(actions, 0, sizeof(*actions));
    return 0;
}

static inline int simple_posix_spawn_file_actions_destroy(simple_posix_spawn_file_actions_t *actions) {
    if (!actions) return EINVAL;
    struct simple_spawn_file_action *act = actions->head;
    while (act) {
        struct simple_spawn_file_action *next = act->next;
        free(act->path);
        free(act);
        act = next;
    }
    memset(actions, 0, sizeof(*actions));
    return 0;
}

static inline int simple_posix_spawn_file_actions_addopen(simple_posix_spawn_file_actions_t *actions,
                                                          int fd, const char *path, int flags, mode_t mode) {
    if (!actions || fd < 0 || !path) return EINVAL;
    struct simple_spawn_file_action *act = (struct simple_spawn_file_action*)malloc(sizeof(*act));
    if (!act) return ENOMEM;
    memset(act, 0, sizeof(*act));
    act->type = SIMPLE_SPAWN_OPEN;
    act->fd = -1;
    act->new_fd = fd;
    act->path = strdup(path);
    if (!act->path) {
        free(act);
        return ENOMEM;
    }
    act->open_flags = flags;
    act->open_mode = mode;

    if (!actions->head) {
        actions->head = actions->tail = act;
    } else {
        actions->tail->next = act;
        actions->tail = act;
    }
    return 0;
}

static inline int simple_posix_spawn_file_actions_addclose(simple_posix_spawn_file_actions_t *actions, int fd) {
    if (!actions || fd < 0) return EINVAL;
    struct simple_spawn_file_action *act = (struct simple_spawn_file_action*)malloc(sizeof(*act));
    if (!act) return ENOMEM;
    memset(act, 0, sizeof(*act));
    act->type = SIMPLE_SPAWN_CLOSE;
    act->fd = fd;

    if (!actions->head) {
        actions->head = actions->tail = act;
    } else {
        actions->tail->next = act;
        actions->tail = act;
    }
    return 0;
}

static inline int simple_posix_spawn_file_actions_adddup2(simple_posix_spawn_file_actions_t *actions,
                                                          int fd, int new_fd) {
    if (!actions || fd < 0 || new_fd < 0) return EINVAL;
    struct simple_spawn_file_action *act = (struct simple_spawn_file_action*)malloc(sizeof(*act));
    if (!act) return ENOMEM;
    memset(act, 0, sizeof(*act));
    act->type = SIMPLE_SPAWN_DUP2;
    act->fd = fd;
    act->new_fd = new_fd;

    if (!actions->head) {
        actions->head = actions->tail = act;
    } else {
        actions->tail->next = act;
        actions->tail = act;
    }
    return 0;
}

static inline void simple_do_file_actions(const simple_posix_spawn_file_actions_t *actions) {
    if (!actions) return;
    struct simple_spawn_file_action *act = actions->head;
    while (act) {
        switch (act->type) {
            case SIMPLE_SPAWN_OPEN: {
                int fd = open(act->path, act->open_flags, act->open_mode);
                if (fd == -1) _exit(127);
                if (fd != act->new_fd) {
                    dup2(fd, act->new_fd);
                    close(fd);
                }
                break;
            }
            case SIMPLE_SPAWN_CLOSE:
                close(act->fd);
                break;
            case SIMPLE_SPAWN_DUP2:
                if (act->fd == act->new_fd) {
                    int flags = fcntl(act->fd, F_GETFD);
                    if (flags != -1) fcntl(act->fd, F_SETFD, flags & ~FD_CLOEXEC);
                } else {
                    dup2(act->fd, act->new_fd);
                }
                break;
        }
        act = act->next;
    }
}

static inline void simple_apply_attrs(short flags, const simple_posix_spawnattr_t *attr) {
    if (!attr) return;

    if (flags & SIMPLE_POSIX_SPAWN_SETSIGDEF) {
        struct sigaction sa;
        memset(&sa, 0, sizeof(sa));
        sa.sa_handler = SIG_DFL;
        for (int sig = 1; sig < NSIG; ++sig) {
            if (sigismember(&attr->sigdefault, sig)) {
                sigaction(sig, &sa, NULL);
            }
        }
    } else {
        struct sigaction sa;
        memset(&sa, 0, sizeof(sa));
        sa.sa_handler = SIG_DFL;
        for (int sig = 1; sig < NSIG; ++sig) {
            struct sigaction cur;
            if (sigaction(sig, NULL, &cur) == 0) {
                if (cur.sa_handler != SIG_IGN && cur.sa_handler != SIG_DFL) {
                    sigaction(sig, &sa, NULL);
                }
            }
        }
    }

    if (flags & SIMPLE_POSIX_SPAWN_SETPGROUP) {
        setpgid(0, attr->pgroup);
    }

    if (flags & SIMPLE_POSIX_SPAWN_SETSID) {
        setsid();
    }

    if (flags & SIMPLE_POSIX_SPAWN_SETSIGMASK) {
        pthread_sigmask(SIG_SETMASK, &attr->sigmask, NULL);
    }
}

static inline int simple_posix_spawn(pid_t *pid_ptr,
                                     const char *path,
                                     const simple_posix_spawn_file_actions_t *actions,
                                     const simple_posix_spawnattr_t *attr,
                                     char *const argv[],
                                     char *const envp[]) {
    sigset_t oldmask, allmask;
    sigfillset(&allmask);
    pthread_sigmask(SIG_BLOCK, &allmask, &oldmask);

    pid_t pid = fork();
    if (pid == -1) {
        int saved_errno = errno;
        pthread_sigmask(SIG_SETMASK, &oldmask, NULL);
        return saved_errno;
    }

    if (pid == 0) {
        if (!(attr && (attr->flags & SIMPLE_POSIX_SPAWN_SETSIGMASK))) {
            pthread_sigmask(SIG_SETMASK, &oldmask, NULL);
        }
        if (attr) simple_apply_attrs(attr->flags, attr);
        simple_do_file_actions(actions);
        if (envp) {
            execve(path, argv, envp);
        } else {
            extern char **environ;
            execve(path, argv, environ);
        }
        _exit(127);
    }

    pthread_sigmask(SIG_SETMASK, &oldmask, NULL);

    if (pid_ptr) *pid_ptr = pid;
    return 0;
}

static inline int simple_posix_spawnp(pid_t *pid_ptr,
                                      const char *file,
                                      const simple_posix_spawn_file_actions_t *actions,
                                      const simple_posix_spawnattr_t *attr,
                                      char *const argv[],
                                      char *const envp[]) {
    sigset_t oldmask, allmask;
    sigfillset(&allmask);
    pthread_sigmask(SIG_BLOCK, &allmask, &oldmask);

    pid_t pid = fork();
    if (pid == -1) {
        int saved_errno = errno;
        pthread_sigmask(SIG_SETMASK, &oldmask, NULL);
        return saved_errno;
    }

    if (pid == 0) {
        if (!(attr && (attr->flags & SIMPLE_POSIX_SPAWN_SETSIGMASK))) {
            pthread_sigmask(SIG_SETMASK, &oldmask, NULL);
        }
        if (attr) simple_apply_attrs(attr->flags, attr);
        simple_do_file_actions(actions);
        if (envp) {
            execvpe(file, argv, envp);
        } else {
            extern char **environ;
            execvpe(file, argv, environ);
        }
        _exit(127);
    }

    pthread_sigmask(SIG_SETMASK, &oldmask, NULL);
    if (pid_ptr) *pid_ptr = pid;
    return 0;
}

#ifdef __cplusplus
}
#endif

#endif /* SIMPLE_POSIX_SPAWN_H */
