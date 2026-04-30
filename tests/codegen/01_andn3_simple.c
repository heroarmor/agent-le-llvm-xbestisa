/* 01_andn3_simple.c — Tier 3a probe.
 * After clang -O2 -march=rv64gc_xbestisa, the agent's ISel must select
 * bestisa.andn3 from the idiomatic (a & ~b & ~c) pattern.
 */
#include <stdint.h>

uint64_t andn3(uint64_t a, uint64_t b, uint64_t c) {
    return a & ~b & ~c;
}
