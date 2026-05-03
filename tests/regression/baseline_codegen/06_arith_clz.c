/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int clz(uint64_t x) { int n = 0; while (x) { x >>= 1; n++; } return 64 - n; }
