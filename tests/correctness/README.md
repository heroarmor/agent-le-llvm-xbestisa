# `tests/correctness/` — Tier 2 oracle programs

**30 hand-written C programs** that exercise the 7 `XBestISA` v1.1 instructions. Each program calls a mix of:
- direct inline-asm path (under `__riscv_xbestisa`) — guaranteed to reach the new instruction
- pure-C path (when the extension is not present) — used as the reference oracle

Each program prints its result via `printf` and exits 0.

## Grading (Tier 2 — 35 pts)

For each `prog.c`:
1. Compile with the agent's clang at `-march=rv64imac_xbestisa -O2`.
2. Compile with the unmodified reference clang at `-march=rv64imac -O2`.
3. Run both under matching Spike (`--isa=rv64imac_zicsr_zifencei_xbestisa pk` and `--isa=rv64imac_zicsr_zifencei pk`).
4. `diff -q` stdout — must be byte-exact.

1 pt each, +5 bonus if all 30 pass. Max 35.

**Status: all 30 programs verified byte-exact on 2026-05-02** (see `reference-solution/E2E_LOG.txt` for one of the runs).

## Inventory

| # | Program | Instructions exercised | Edge cases |
|---|---|---|---|
| 01 | `add3_basic.c` | `add3` | small inputs |
| 02 | `add3_overflow_wrap.c` | `add3` | XLEN-wide wrap-around |
| 03 | `add3_zero_inputs.c` | `add3` | x0/zero operands |
| 04 | `add3_chain.c` | `add3` | accumulator loop |
| 05 | `add3_negatives.c` | `add3` | wrap on negatives |
| 06 | `xor3_basic.c` | `xor3` | mixed bit patterns |
| 07 | `xor3_associativity.c` | `xor3` | three commutations of same XOR |
| 08 | `xor3_self_inverse.c` | `xor3` | a^a^c == c |
| 09 | `xor3_array_fold.c` | `xor3` | array reduction |
| 10 | `xor3_high_bits.c` | `xor3` | upper-bit operands |
| 11 | `or3_basic.c` | `or3` | mixed nibbles |
| 12 | `or3_disjoint_bits.c` | `or3` | disjoint masks |
| 13 | `or3_full_mask.c` | `or3` | all bits set |
| 14 | `or3_chain.c` | `or3` | bit-by-bit accumulation |
| 15 | `sha256ch_basic.c` | `sha256ch` | basic Ch correctness |
| 16 | `sha256ch_e_zero.c` | `sha256ch` | e == 0 selects g |
| 17 | `sha256ch_e_ones.c` | `sha256ch` | e == ~0 selects f |
| 18 | `sha256ch_compress_round.c` | `sha256ch`, `xor3` | composed crypto round |
| 19 | `sha256ch_array.c` | `sha256ch` | per-element reduction |
| 20 | `sha256maj_basic.c` | `sha256maj` | basic Maj correctness |
| 21 | `sha256maj_all_equal.c` | `sha256maj` | a==b==c |
| 22 | `sha256maj_two_equal.c` | `sha256maj` | a==b, c different |
| 23 | `sha256maj_chain.c` | `sha256maj` | accumulator |
| 24 | `mac_basic.c` | `mac` | small positive |
| 25 | `mac_negative.c` | `mac` | signed negative operand |
| 26 | `mac_overflow.c` | `mac` | 32-bit wrap |
| 27 | `mac_dot_product.c` | `mac` | dot-product loop |
| 28 | `mac_zero_acc.c` | `mac` | acc=0 |
| 29 | `mixed_xor3_or3.c` | `xor3`, `or3`, `add3` | inter-instruction interaction |
| 30 | `mixed_all_six.c` | all 6 ALU ops | broad smoke test |

(`bestisa.lw` (R-type, register+register load) is exercised by Tier 3a / Tier 3b indirectly via memory-access patterns rather than via correctness/, since it requires a different test setup.)

Each program ships with a `<prog>.expected_out` file (the byte-exact stdout of the reference build, captured with the patched clang+Spike on 2026-05-02). The grader recomputes the reference each run rather than trusting stale `.expected_out` files; the bundled files are for offline debugging.
