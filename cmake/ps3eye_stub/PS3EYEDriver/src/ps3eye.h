// Stub header for PS3EYEDriver – used when the git submodule is not initialized.
// Replaces ps3eye.h and ps3eye_capi.h so the project compiles without the driver.

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle type
typedef struct ps3eye_t ps3eye_t;

// Camera parameters
struct ps3eye_param {
    int width;
    int height;
    int fps;
};

// Stub functions
static inline int ps3eye_init(void) {
    return -1;  // no camera available
}

static inline ps3eye_t* ps3eye_open(int vendor_id, int product_id, int index) {
    (void)vendor_id; (void)product_id; (void)index;
    return NULL;
}

static inline int ps3eye_start(ps3eye_t* eye) {
    (void)eye;
    return -1;
}

static inline int ps3eye_grab_frame(ps3eye_t* eye, unsigned char* frame) {
    (void)eye; (void)frame;
    return -1;
}

static inline void ps3eye_close(ps3eye_t* eye) {
    (void)eye;
}

static inline void ps3eye_set_parameter(ps3eye_t* eye, unsigned int param, int value) {
    (void)eye; (void)param; (void)value;
}

static inline int ps3eye_get_parameter(ps3eye_t* eye, unsigned int param) {
    (void)eye; (void)param;
    return 0;
}

static inline void ps3eye_get_device_list(struct ps3eye_param** list, int* count) {
    (void)list;
    *count = 0;
}

static inline void ps3eye_free_device_list(struct ps3eye_param* list) {
    (void)list;
}

#ifdef __cplusplus
}
#endif