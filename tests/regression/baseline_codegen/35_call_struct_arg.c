/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

struct S { int a, b; };
extern int handle(struct S s);
int wrap_struct(int x) { struct S s = { x, x*2 }; return handle(s); }
