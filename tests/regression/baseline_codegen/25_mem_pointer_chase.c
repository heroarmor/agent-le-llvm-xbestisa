/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

struct N { struct N *next; int v; };
int chase(struct N *p) { int s = 0; while (p) { s += p->v; p = p->next; } return s; }
