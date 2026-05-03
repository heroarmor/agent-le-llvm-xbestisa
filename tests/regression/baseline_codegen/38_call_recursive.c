/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int factorial(int n) { return n <= 1 ? 1 : n * factorial(n-1); }
