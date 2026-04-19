#pragma once

#include <search.h>

#if defined(__ANDROID__) && __ANDROID_API__ < 28

#include <stdlib.h>
#include <string.h>
#include <errno.h>

#ifdef __cplusplus
extern "C" {
#endif

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

static inline int simple_hcreate_r(size_t nel, struct hsearch_data *htab) {
    if (!htab) {
        errno = EINVAL;
        return 0;
    }
    void **priv = (void**)htab;
    if (*priv != NULL) {
        errno = EINVAL;
        return 0;
    }
    struct internal_hashtable *ht = internal_create(nel);
    if (!ht) {
        errno = ENOMEM;
        return 0;
    }
    *priv = ht;
    return 1;
}

static inline void simple_hdestroy_r(struct hsearch_data *htab) {
    if (!htab) return;
    void **priv = (void**)htab;
    if (*priv) {
        internal_destroy((struct internal_hashtable*)*priv);
        *priv = NULL;
    }
}

static inline int simple_hsearch_r(ENTRY item, ACTION action, ENTRY **retval, struct hsearch_data *htab) {
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

    void **priv = (void**)htab;
    struct internal_hashtable *ht = (struct internal_hashtable*)*priv;
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

#endif /* __ANDROID_API__ < 28 */
