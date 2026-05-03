/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int sumA(int *a, int n) { int s = 0; for (int i = 0; i < n; ++i) s += a[i]; return s; }
