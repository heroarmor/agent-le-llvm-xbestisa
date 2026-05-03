/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int with_goto(int x) {
    int s = 0;
    again: if (x <= 0) goto end; s += x; x--; goto again;
    end: return s;
}
