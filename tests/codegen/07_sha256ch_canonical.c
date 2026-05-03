#include <stdint.h>

uint64_t ch(uint64_t e, uint64_t f, uint64_t g) {
    return (e & f) ^ (~e & g);
}
