/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int callfp(int (*fp)(int), int x) { return fp(x) + fp(x+1); }
