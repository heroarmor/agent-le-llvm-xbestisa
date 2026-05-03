/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

uint64_t mul_const(uint64_t x) { return x * 17u + (x * 257u) - (x * 65535u); }
