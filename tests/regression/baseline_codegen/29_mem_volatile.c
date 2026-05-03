/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

volatile int *VOLPTR;
int read_vol(void) { return *VOLPTR; }
