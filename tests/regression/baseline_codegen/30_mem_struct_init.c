/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

struct R { int a, b, c, d; };
struct R make_r(int x) { struct R r = { x, x*2, x*3, x*4 }; return r; }
