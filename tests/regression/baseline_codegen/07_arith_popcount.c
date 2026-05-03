/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int popc(uint64_t x) { int n=0; while(x) { n += x&1; x >>= 1; } return n; }
