/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

extern int helper(int x);
int wrap(int a, int b) { return helper(a) + helper(b); }
