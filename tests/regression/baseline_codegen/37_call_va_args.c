/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

#include <stdarg.h>
int sum_va(int n, ...) {
    va_list ap; va_start(ap, n);
    int s = 0;
    for (int i = 0; i < n; ++i) s += va_arg(ap, int);
    va_end(ap);
    return s;
}
