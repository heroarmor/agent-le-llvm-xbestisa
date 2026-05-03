/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

void copy_words(int *dst, int *src, int n) {
    for (int i = 0; i < n; ++i) dst[i] = src[i];
}
