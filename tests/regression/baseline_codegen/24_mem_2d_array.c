/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int sum2d(int (*a)[16], int n) {
    int s = 0;
    for (int i = 0; i < n; ++i) for (int j = 0; j < 16; ++j) s += a[i][j];
    return s;
}
