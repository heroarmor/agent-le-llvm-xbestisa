/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

uint64_t mul_chain(uint64_t a, uint64_t b, uint64_t c, uint64_t d) {
    return ((a * b) + c) * d;
}
