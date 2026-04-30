# `tests/correctness/` — Tier 2 oracle programs

**30 hand-written C programs** that exercise the 6 `XBestISA` instructions. Each program calls a mix of:
- direct `__builtin_riscv_bestisa_*` builtins (so the path works even if the agent's ISel patterns are weak)
- idiomatic C that **should** be selected to the new instruction (also exercises ISel)

Each program prints its result via `printf` and exits 0 on success.

## Grading (Tier 2 — 35 pts)

For each `prog.c`:
1. Compile with the agent's clang at `-march=rv64gc_xbestisa -O2`.
2. Compile with the unmodified reference clang at `-march=rv64gc -O2`.
3. Run both under matching Spike (`--isa=rv64gc_xbestisa` and `--isa=rv64gc` respectively).
4. `diff -q` stdout — must be byte-exact.

1 pt each, +5 bonus if all 30 pass. Max 35.

## Test inventory (30 total)

| # | Program | Instructions exercised | Edge cases |
|---|---|---|---|
| 01 | `andn3_basic.c` | `andn3` | basic 3-source AND-NOT |
| 02 | `andn3_zero_dest.c` | `andn3` | rd == x0 (write discarded) |
| 03 | `andn3_same_src.c` | `andn3` | rs1 == rs2, rs2 == rs3 |
| 04 | `andn3_full_mask.c` | `andn3` | all-ones / all-zeros operands |
| 05 | `xor3_basic.c` | `xor3` | basic 3-way XOR |
| 06 | `xor3_associativity.c` | `xor3` | (a^b)^c == a^(b^c) — both must select |
| 07 | `xor3_chain.c` | `xor3` | 5-way XOR → 2 instances |
| 08 | `maddw_basic.c` | `maddw` | basic 32-bit fused MAC |
| 09 | `maddw_overflow.c` | `maddw` | wrap-around at 32-bit boundary |
| 10 | `maddw_negative.c` | `maddw` | signed mul + sext to 64 |
| 11 | `maddw_loop.c` | `maddw` | accumulate-in-loop pattern |
| 12 | `sha256ch_basic.c` | `sha256ch` | bit-pattern correctness |
| 13 | `sha256ch_compress_round.c` | `sha256ch`, `xor3` | one round of SHA-256 compression |
| 14 | `clmulacc_basic.c` | `clmulacc` | builtin path (no idiomatic IR equivalent) |
| 15 | `clmulacc_crc32.c` | `clmulacc` | CRC32 via Barrett reduction |
| 16 | `clmulacc_gcm.c` | `clmulacc` | GHASH-style accumulation |
| 17 | `bfly_basic.c` | `bfly` | each of 6 stage masks |
| 18 | `bfly_bitreverse.c` | `bfly` | full bit-reversal via 6-stage chain |
| 19 | `bfly_invalid_k.c` | `bfly` | k>5 must produce no-op (per spec) |
| 20 | `mixed_andn3_xor3.c` | `andn3`, `xor3` | both in same function |
| 21 | `mixed_all_six.c` | all 6 | smoke test: every instruction emitted |
| 22 | `abi_args.c` | `andn3`, `xor3` | extension instructions across calls |
| 23 | `abi_struct_return.c` | `maddw`, `sha256ch` | calling convention |
| 24 | `volatile_load_then_op.c` | `xor3`, `maddw` | volatile loads not reordered past instr |
| 25 | `inline_asm_mix.c` | `clmulacc` | builtin alongside `asm volatile` |
| 26 | `loop_unroll_xor3.c` | `xor3` | 8x unroll → ≥8 instances |
| 27 | `cond_select_andn3.c` | `andn3` | inside `if/else` branches |
| 28 | `large_input.c` | `xor3`, `maddw` | 1000-iter input array, hash-like |
| 29 | `pkcs_pad_check.c` | `andn3`, `xor3` | constant-time PKCS#7 padding |
| 30 | `aes_invsbox_partial.c` | `andn3`, `xor3`, `bfly` | partial AES round (without sbox table) |

Each program ships with a `<prog>.expected_out` file (the byte-exact stdout the reference build produces). The grader recomputes the reference each run rather than trusting stale `.expected_out` files; the bundled files are for debugging.

See `01_andn3_basic.c` for the canonical structure.
