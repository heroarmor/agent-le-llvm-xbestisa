/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

uint64_t div_mod(uint64_t a, uint64_t b) { return (a / (b|1)) ^ (a % (b|1)); }
