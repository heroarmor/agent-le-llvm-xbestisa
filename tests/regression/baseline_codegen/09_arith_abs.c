/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int64_t myabs(int64_t x) { return x < 0 ? -x : x; }
