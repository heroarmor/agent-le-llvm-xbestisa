/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

extern int many(int a, int b, int c, int d, int e, int f, int g, int h);
int call_many(int x) { return many(x, x*2, x*3, x*4, x*5, x*6, x*7, x*8); }
