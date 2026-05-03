/* Common header for all correctness programs. */
#include <stdio.h>
#include <stdint.h>

/* Builtin path: when xbestisa is enabled, force the new instructions
 * via inline assembly to guarantee Tier-2 reaches the actual op.
 * Idiomatic-C path is used everywhere else, exercising ISel.
 */
#if defined(__riscv) && defined(__riscv_xbestisa)
#  define HAS_XBESTISA 1
#else
#  define HAS_XBESTISA 0
#endif

static inline uint64_t bestisa_add3(uint64_t a, uint64_t b, uint64_t c) {
#if HAS_XBESTISA
    uint64_t r;
    __asm__ ("bestisa.add3 %0, %1, %2, %3" : "=r"(r) : "r"(a), "r"(b), "r"(c));
    return r;
#else
    return a + b + c;
#endif
}
static inline uint64_t bestisa_xor3(uint64_t a, uint64_t b, uint64_t c) {
#if HAS_XBESTISA
    uint64_t r;
    __asm__ ("bestisa.xor3 %0, %1, %2, %3" : "=r"(r) : "r"(a), "r"(b), "r"(c));
    return r;
#else
    return a ^ b ^ c;
#endif
}
static inline uint64_t bestisa_or3(uint64_t a, uint64_t b, uint64_t c) {
#if HAS_XBESTISA
    uint64_t r;
    __asm__ ("bestisa.or3 %0, %1, %2, %3" : "=r"(r) : "r"(a), "r"(b), "r"(c));
    return r;
#else
    return a | b | c;
#endif
}
static inline uint64_t bestisa_sha256ch(uint64_t e, uint64_t f, uint64_t g) {
#if HAS_XBESTISA
    uint64_t r;
    __asm__ ("bestisa.sha256ch %0, %1, %2, %3" : "=r"(r) : "r"(e), "r"(f), "r"(g));
    return r;
#else
    return (e & f) ^ (~e & g);
#endif
}
static inline uint64_t bestisa_sha256maj(uint64_t a, uint64_t b, uint64_t c) {
#if HAS_XBESTISA
    uint64_t r;
    __asm__ ("bestisa.sha256maj %0, %1, %2, %3" : "=r"(r) : "r"(a), "r"(b), "r"(c));
    return r;
#else
    return (a & b) ^ (a & c) ^ (b & c);
#endif
}
static inline int32_t bestisa_mac(int32_t a, int32_t b, int32_t c) {
#if HAS_XBESTISA
    int32_t r;
    __asm__ ("bestisa.mac %0, %1, %2, %3" : "=r"(r) : "r"((int64_t)a), "r"((int64_t)b), "r"((int64_t)c));
    return r;
#else
    return a * b + c;
#endif
}

int main(void) {
    /* one SHA-256 round-style chain */
    uint64_t e = 0x510e527fade682d1ULL;
    uint64_t f = 0x9b05688c2b3e6c1fULL;
    uint64_t g = 0x1f83d9abfb41bd6bULL;
    uint64_t r = bestisa_xor3(bestisa_sha256ch(e, f, g),
                                  e, f);
    printf("ch_round = %016lx\n", (unsigned long)r);
    return 0;
}
