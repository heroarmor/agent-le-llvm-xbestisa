/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

unsigned mystrlen(const char *s) { unsigned n = 0; while (s[n]) n++; return n; }
