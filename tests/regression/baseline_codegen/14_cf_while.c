/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

int gcd(int a, int b) { while (b) { int t = b; b = a % b; a = t; } return a; }
