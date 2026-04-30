/* Sample baseline_codegen unit. The packaged release ships 50 such files.
 *
 * This file is compiled with `clang -O2 --target=riscv64-unknown-elf
 * -march=rv64gc -c` by both the agent's clang and the reference clang.
 * The two opcode-mnemonic histograms must match exactly (Tier 3b).
 *
 * License: Apache-2.0 with LLVM Exceptions.
 */
#include <stdint.h>

uint64_t mul_chain(uint64_t a, uint64_t b, uint64_t c, uint64_t d) {
    return ((a * b) + c) * d;
}

uint64_t mul_const_strength(uint64_t x) {
    return x * 17u + (x * 257u) - (x * 65535u);
}

uint64_t div_then_mod(uint64_t a, uint64_t b) {
    if (b == 0) return 0;
    return (a / b) ^ (a % b);
}
