/* Standalone baseline codegen unit for Tier 3b. License: Apache-2.0. */
#include <stdint.h>

struct T { long lo, hi; };
struct T make_t(long x) { struct T t = { x, ~x }; return t; }
