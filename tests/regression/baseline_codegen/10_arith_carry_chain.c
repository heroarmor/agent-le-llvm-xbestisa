/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

uint64_t carry(uint64_t a, uint64_t b, uint64_t c) {
    uint64_t s1 = a + b; uint64_t c1 = s1 < a;
    uint64_t s2 = s1 + c; uint64_t c2 = s2 < s1;
    return s2 + c1 + c2;
}
