/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int bsearch_int(int *a, int n, int v) {
    int lo = 0, hi = n - 1;
    while (lo <= hi) {
        int mid = (lo + hi) / 2;
        if (a[mid] == v) return mid;
        if (a[mid] < v) lo = mid + 1; else hi = mid - 1;
    }
    return -1;
}
