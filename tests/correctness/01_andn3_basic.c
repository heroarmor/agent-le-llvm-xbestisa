/* 01_andn3_basic.c — Tier 2 oracle program.
 *
 * Exercises bestisa.andn3 via both:
 *   (1) the __builtin_riscv_bestisa_andn3 builtin (always reaches the instr if
 *       the agent wired up the builtin), and
 *   (2) the idiomatic C pattern (a & ~b & ~c) which exercises the agent's ISel.
 *
 * Both call sites are computed against a portable reference and checksummed.
 * Printed output must be byte-exact between -march=rv64gc_xbestisa and -march=rv64gc.
 */

#include <stdio.h>
#include <stdint.h>

#if defined(__riscv) && defined(__riscv_xbestisa)
extern uint64_t __builtin_riscv_bestisa_andn3(uint64_t, uint64_t, uint64_t);
#  define ANDN3_BUILTIN(a, b, c) __builtin_riscv_bestisa_andn3((a), (b), (c))
#else
#  define ANDN3_BUILTIN(a, b, c) ((a) & ~(b) & ~(c))
#endif

static uint64_t andn3_ref(uint64_t a, uint64_t b, uint64_t c) {
    return a & ~b & ~c;
}

static uint64_t andn3_isel(uint64_t a, uint64_t b, uint64_t c) {
    /* Idiomatic pattern — should be selected to bestisa.andn3. */
    return a & ~b & ~c;
}

int main(void) {
    static const struct { uint64_t a, b, c; } v[] = {
        {0x0123456789ABCDEFULL, 0x00000000FFFFFFFFULL, 0xAAAAAAAAAAAAAAAAULL},
        {0xFFFFFFFFFFFFFFFFULL, 0x0000000000000000ULL, 0x0000000000000000ULL},
        {0x0000000000000000ULL, 0xFFFFFFFFFFFFFFFFULL, 0xFFFFFFFFFFFFFFFFULL},
        {0xDEADBEEFCAFEBABEULL, 0x5555555555555555ULL, 0x3333333333333333ULL},
        {0x8000000000000001ULL, 0x8000000000000000ULL, 0x0000000000000001ULL},
        {0x0F0F0F0F0F0F0F0FULL, 0xF0F0F0F0F0F0F0F0ULL, 0x00FF00FF00FF00FFULL},
    };
    const int N = (int)(sizeof(v) / sizeof(v[0]));

    uint64_t sum_builtin = 0, sum_isel = 0, sum_ref = 0;
    for (int i = 0; i < N; ++i) {
        sum_builtin ^= ANDN3_BUILTIN(v[i].a, v[i].b, v[i].c);
        sum_isel    ^= andn3_isel(v[i].a, v[i].b, v[i].c);
        sum_ref     ^= andn3_ref(v[i].a, v[i].b, v[i].c);
    }

    printf("andn3 builtin = 0x%016llx\n", (unsigned long long)sum_builtin);
    printf("andn3 isel    = 0x%016llx\n", (unsigned long long)sum_isel);
    printf("andn3 ref     = 0x%016llx\n", (unsigned long long)sum_ref);
    printf("OK %s\n", (sum_builtin == sum_ref && sum_isel == sum_ref) ? "yes" : "no");
    return 0;
}
