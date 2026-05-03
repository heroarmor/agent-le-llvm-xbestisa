/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int countdown(int n) { int i = 0; do { i++; n--; } while (n); return i; }
