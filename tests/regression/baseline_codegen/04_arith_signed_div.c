/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int64_t sdiv(int64_t a, int64_t b) { return a / (b|1); }
