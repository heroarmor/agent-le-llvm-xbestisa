/* 08_sha256ch_simple.c — Tier 3a probe for bestisa.sha256ch.
 * The SHA-256 Ch function: (e & f) ^ (~e & g).
 */
#include <stdint.h>

uint64_t sha256_ch(uint64_t e, uint64_t f, uint64_t g) {
    return (e & f) ^ (~e & g);
}
