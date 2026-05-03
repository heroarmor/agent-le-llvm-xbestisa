#include <stdint.h>

uint64_t xor8(uint64_t a, uint64_t b, uint64_t c, uint64_t d,
                          uint64_t e, uint64_t f, uint64_t g, uint64_t h) {
    return a ^ b ^ c ^ d ^ e ^ f ^ g ^ h;
}
