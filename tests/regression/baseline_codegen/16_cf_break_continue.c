/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int find_first(int *arr, int n, int v) {
    for (int i = 0; i < n; ++i) {
        if (arr[i] == 0) continue;
        if (arr[i] == v) return i;
    }
    return -1;
}
