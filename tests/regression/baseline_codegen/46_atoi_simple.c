/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int my_atoi(const char *s) {
    int sign = 1, n = 0;
    if (*s == '-') { sign = -1; s++; }
    while (*s >= '0' && *s <= '9') { n = n*10 + (*s - '0'); s++; }
    return n * sign;
}
