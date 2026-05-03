#include <stdint.h>

uint64_t maj(uint64_t a, uint64_t b, uint64_t c) {
    return (a & b) | (c & (a ^ b));
}
