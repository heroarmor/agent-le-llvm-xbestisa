/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int tern(int a, int b, int c, int d) { return (a < b) ? (c + d) : (c - d); }
