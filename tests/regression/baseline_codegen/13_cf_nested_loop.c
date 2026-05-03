/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int nested(int n, int m) {
    int s = 0;
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < m; ++j) s += i * j;
    return s;
}
