/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

void zero(char *p, int n) { for (int i = 0; i < n; ++i) p[i] = 0; }
