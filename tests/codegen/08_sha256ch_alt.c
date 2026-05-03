#include <stdint.h>

uint64_t ch_alt(uint64_t e, uint64_t f, uint64_t g) {
    return g ^ (e & (f ^ g));
}
