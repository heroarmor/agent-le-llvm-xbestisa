/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

void to_hex(unsigned x, char *out) {
    static const char *digits = "0123456789abcdef";
    for (int i = 7; i >= 0; --i) { out[i] = digits[x & 0xF]; x >>= 4; }
    out[8] = 0;
}
