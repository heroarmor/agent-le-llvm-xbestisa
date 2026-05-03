/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

static inline int max3(int a, int b, int c) { int m = a>b?a:b; return m>c?m:c; }
int triple_max(int x, int y, int z, int w) { return max3(x,y,z) + max3(y,z,w); }
