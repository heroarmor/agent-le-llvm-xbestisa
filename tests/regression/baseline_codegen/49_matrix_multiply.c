/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

void matmul(int n, int *A, int *B, int *C) {
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j) {
            int s = 0;
            for (int k = 0; k < n; ++k) s += A[i*n+k] * B[k*n+j];
            C[i*n+j] = s;
        }
}
