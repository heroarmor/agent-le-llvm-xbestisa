/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int strided(int *a, int n, int stride) { int s = 0; for (int i = 0; i < n; i += stride) s += a[i]; return s; }
