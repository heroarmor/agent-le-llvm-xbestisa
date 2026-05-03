/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

extern int tail_target(int x);
int tail(int x) { return tail_target(x + 1); }
