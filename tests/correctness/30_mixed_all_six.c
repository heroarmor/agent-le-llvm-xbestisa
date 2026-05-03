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
    uint64_t a = 0xAAAA1111ULL, b = 0xBBBB2222ULL, c = 0xCCCC3333ULL;
    uint64_t s = bestisa_add3(a, b, c);
    s ^= bestisa_xor3(a, b, c);
    s |= bestisa_or3(s & 0xFFFF, 0x10000ULL, 0x20000ULL);
    s = bestisa_sha256ch(s, a, b);
    s = bestisa_sha256maj(s, c, 0x42ULL);
    int32_t m = bestisa_mac((int32_t)(s & 0xFF), 7, (int32_t)((s >> 8) & 0xFF));
    printf("mixed6 = %016lx %d\n", (unsigned long)s, m);
    return 0;
}
