#pragma once

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <dlfcn.h>
#include <pthread.h>

#include <search.h>

#if defined(__ANDROID__) && __ANDROID_API__ < 28

#include <android/api-level.h>

#ifdef __cplusplus
extern "C" {
#endif

static inline int use_system_hsearch(void) {
    static int cached_api_level = -1;
    if (cached_api_level == -1) {
        cached_api_level = android_get_device_api_level();
    }
    return cached_api_level >= 28;
}

struct internal_bucket {
    char *key;
    void *data;
    struct internal_bucket *next;
};

struct internal_hashtable {
    size_t size;
    struct internal_bucket **buckets;
};

static inline unsigned long internal_hash(const char *str) {
    unsigned long h = 5381;
    int c;
    while ((c = *str++)) h = ((h << 5) + h) + c;
    return h;
}

static inline struct internal_hashtable *internal_create(size_t nel) {
    struct internal_hashtable *ht = calloc(1, sizeof(*ht));
    if (!ht) return NULL;
    ht->size = nel;
    ht->buckets = calloc(nel, sizeof(struct internal_bucket*));
    if (!ht->buckets) {
        free(ht);
        return NULL;
    }
    return ht;
}

static inline void internal_destroy(struct internal_hashtable *ht) {
    if (!ht) return;
    for (size_t i = 0; i < ht->size; ++i) {
        struct internal_bucket *b = ht->buckets[i];
        while (b) {
            struct internal_bucket *next = b->next;
            free(b->key);
            free(b);
            b = next;
        }
    }
    free(ht->buckets);
    free(ht);
}

static inline ENTRY *internal_find(struct internal_hashtable *ht, const char *key) {
    unsigned long h = internal_hash(key) % ht->size;
    struct internal_bucket *b = ht->buckets[h];
    while (b && strcmp(b->key, key) != 0) b = b->next;
    return b ? (ENTRY*)b : NULL;
}

static inline ENTRY *internal_insert(struct internal_hashtable *ht, const char *key, void *data) {
    ENTRY *existing = internal_find(ht, key);
    if (existing) return existing;

    unsigned long h = internal_hash(key) % ht->size;
    struct internal_bucket *b = malloc(sizeof(*b));
    if (!b) return NULL;
    b->key = strdup(key);
    if (!b->key) { free(b); return NULL; }
    b->data = data;
    b->next = ht->buckets[h];
    ht->buckets[h] = b;
    return (ENTRY*)b;
}

static inline int hcreate_r(size_t nel, struct hsearch_data *htab) {
    if (!htab) {
        errno = EINVAL;
        return 0;
    }
    if (use_system_hsearch()) {
        static int (*sys_hcreate_r)(size_t, struct hsearch_data*) = NULL;
        static pthread_once_t once = PTHREAD_ONCE_INIT;
        static void load_sym(void) {
            void *handle = dlopen(NULL, RTLD_LAZY);
            if (handle) {
                sys_hcreate_r = (int(*)(size_t, struct hsearch_data*))dlsym(handle, "hcreate_r");
            }
        }
        pthread_once(&once, load_sym);
        if (sys_hcreate_r) {
            return sys_hcreate_r(nel, htab);
        }
    }

    if (htab->__private != NULL) {
        errno = EINVAL;
        return 0;
    }
    struct internal_hashtable *ht = internal_create(nel);
    if (!ht) {
        errno = ENOMEM;
        return 0;
    }
    htab->__private = ht;
    return 1;
}

static inline void hdestroy_r(struct hsearch_data *htab) {
    if (!htab) return;
    if (use_system_hsearch()) {
        static void (*sys_hdestroy_r)(struct hsearch_data*) = NULL;
        static pthread_once_t once = PTHREAD_ONCE_INIT;
        static void load_sym(void) {
            void *handle = dlopen(NULL, RTLD_LAZY);
            if (handle) {
                sys_hdestroy_r = (void(*)(struct hsearch_data*))dlsym(handle, "hdestroy_r");
            }
        }
        pthread_once(&once, load_sym);
        if (sys_hdestroy_r) {
            sys_hdestroy_r(htab);
            return;
        }
    }
    if (htab->__private) {
        internal_destroy((struct internal_hashtable*)htab->__private);
        htab->__private = NULL;
    }
}

static inline int hsearch_r(ENTRY item, ACTION action, ENTRY **retval, struct hsearch_data *htab) {
    if (!htab || !retval) {
        errno = EINVAL;
        return 0;
    }
    if (action != FIND && action != ENTER) {
        errno = EINVAL;
        return 0;
    }
    if (action == ENTER && !item.key) {
        errno = EINVAL;
        return 0;
    }

    if (use_system_hsearch()) {
        static int (*sys_hsearch_r)(ENTRY, ACTION, ENTRY**, struct hsearch_data*) = NULL;
        static pthread_once_t once = PTHREAD_ONCE_INIT;
        static void load_sym(void) {
            void *handle = dlopen(NULL, RTLD_LAZY);
            if (handle) {
                sys_hsearch_r = (int(*)(ENTRY, ACTION, ENTRY**, struct hsearch_data*))dlsym(handle, "hsearch_r");
            }
        }
        pthread_once(&once, load_sym);
        if (sys_hsearch_r) {
            return sys_hsearch_r(item, action, retval, htab);
        }
    }

    struct internal_hashtable *ht = (struct internal_hashtable*)htab->__private;
    if (!ht) {
        errno = EINVAL;
        return 0;
    }

    ENTRY *e = internal_find(ht, item.key);
    if (e) {
        *retval = e;
        return 1;
    }
    if (action == ENTER) {
        e = internal_insert(ht, item.key, item.data);
        if (e) {
            *retval = e;
            return 1;
        } else {
            errno = ENOMEM;
            return 0;
        }
    }
    *retval = NULL;
    errno = ESRCH;
    return 0;
}

#ifdef __cplusplus
}
#endif

#else

#endif
