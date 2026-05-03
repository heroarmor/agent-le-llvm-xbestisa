/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int64_t mm(int64_t a, int64_t b, int64_t c) {
    int64_t lo = a<b ? a : b;
    int64_t hi = b>c ? b : c;
    return hi - lo;
}
