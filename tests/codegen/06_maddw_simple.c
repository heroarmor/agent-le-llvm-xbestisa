/* 06_maddw_simple.c — Tier 3a probe for bestisa.maddw. */
#include <stdint.h>

int32_t maddw(int32_t a, int32_t b, int32_t c) {
    return a + b * c;   /* should select bestisa.maddw on RV64 */
}
