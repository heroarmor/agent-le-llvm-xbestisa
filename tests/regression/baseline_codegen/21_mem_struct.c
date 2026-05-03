/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

struct P { int x, y, z; };
int sumP(struct P *p) { return p->x + p->y + p->z; }
