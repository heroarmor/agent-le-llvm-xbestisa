#include <stdint.h>

/* Function uses both xor3 and or3 — Tier 3a only counts xor3 occurrences. */
uint64_t mix(uint64_t a, uint64_t b, uint64_t c, uint64_t d) {
    uint64_t x = a ^ b ^ c;
    uint64_t y = a | b | c;
    return x + y + d;
}
