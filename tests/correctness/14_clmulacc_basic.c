/* 14_clmulacc_basic.c — Tier 2 oracle program for bestisa.clmulacc.
 *
 * clmulacc has no canonical scalar IR pattern; the only path to it is via the
 * builtin / intrinsic. This program verifies that the builtin lowers correctly
 * and produces results bit-exact with a portable software clmul.
 */

#include <stdio.h>
#include <stdint.h>

#if defined(__riscv) && defined(__riscv_xbestisa)
extern uint64_t __builtin_riscv_bestisa_clmulacc(uint64_t acc, uint64_t a, uint64_t b);
#  define CLMULACC(acc, a, b) __builtin_riscv_bestisa_clmulacc((acc), (a), (b))
#else
static inline uint64_t clmul_ref(uint64_t a, uint64_t b) {
    uint64_t r = 0;
    for (int i = 0; i < 64; ++i) {
        if ((b >> i) & 1u) r ^= (a << i);
    }
    return r;
}
#  define CLMULACC(acc, a, b) ((acc) ^ clmul_ref((a), (b)))
#endif

static uint64_t clmul_ref_check(uint64_t a, uint64_t b) {
    uint64_t r = 0;
    for (int i = 0; i < 64; ++i) {
        if ((b >> i) & 1u) r ^= (a << i);
    }
    return r;
}

int main(void) {
    static const struct { uint64_t a, b; } v[] = {
        {0x0000000000000003ULL, 0x0000000000000005ULL},
        {0xFFFFFFFFFFFFFFFFULL, 0x0000000000000001ULL},
        {0x0123456789ABCDEFULL, 0xFEDCBA9876543210ULL},
        {0xDEADBEEFCAFEBABEULL, 0xC001D00DBADF00D5ULL},
        {0x8000000000000000ULL, 0x0000000000000002ULL},
    };
    const int N = (int)(sizeof(v) / sizeof(v[0]));

    uint64_t acc = 0xA5A5A5A5A5A5A5A5ULL;
    uint64_t ref = acc;
    for (int i = 0; i < N; ++i) {
        acc = CLMULACC(acc, v[i].a, v[i].b);
        ref = ref ^ clmul_ref_check(v[i].a, v[i].b);
    }
    printf("clmulacc final = 0x%016llx\n", (unsigned long long)acc);
    printf("ref      final = 0x%016llx\n", (unsigned long long)ref);
    printf("OK %s\n", acc == ref ? "yes" : "no");
    return 0;
}
