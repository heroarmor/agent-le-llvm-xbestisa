/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int fib(int n) { return n < 2 ? n : fib(n-1) + fib(n-2); }
