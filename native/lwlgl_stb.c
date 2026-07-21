/* Minimal C shim that keeps stb_image's ABI stable for CFFI. */
#define STB_IMAGE_IMPLEMENTATION
#define STBI_FAILURE_USERMSG
#include "vendor/stb_image.h"

#if defined(_WIN32)
#  define LWLGL_EXPORT __declspec(dllexport)
#else
#  define LWLGL_EXPORT __attribute__((visibility("default")))
#endif

LWLGL_EXPORT unsigned char *lwlgl_stbi_load(const char *filename,
                                             int *x, int *y,
                                             int *channels_in_file,
                                             int desired_channels) {
    return stbi_load(filename, x, y, channels_in_file, desired_channels);
}

LWLGL_EXPORT unsigned char *lwlgl_stbi_load_from_memory(const unsigned char *buffer,
                                                         int length,
                                                         int *x, int *y,
                                                         int *channels_in_file,
                                                         int desired_channels) {
    return stbi_load_from_memory(buffer, length, x, y, channels_in_file, desired_channels);
}

LWLGL_EXPORT float *lwlgl_stbi_loadf(const char *filename,
                                      int *x, int *y,
                                      int *channels_in_file,
                                      int desired_channels) {
    return stbi_loadf(filename, x, y, channels_in_file, desired_channels);
}

LWLGL_EXPORT int lwlgl_stbi_info(const char *filename, int *x, int *y, int *channels) {
    return stbi_info(filename, x, y, channels);
}

LWLGL_EXPORT int lwlgl_stbi_is_hdr(const char *filename) {
    return stbi_is_hdr(filename);
}

LWLGL_EXPORT void lwlgl_stbi_free(void *data) {
    stbi_image_free(data);
}

LWLGL_EXPORT const char *lwlgl_stbi_failure_reason(void) {
    return stbi_failure_reason();
}

LWLGL_EXPORT void lwlgl_stbi_set_flip_vertically_on_load(int flag) {
    stbi_set_flip_vertically_on_load(flag);
}
