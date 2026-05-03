/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

static int helper2(int x) { return x * x + 1; }
int caller(int a, int b) { return helper2(a) + helper2(b); }
