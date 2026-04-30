# `tests/codegen/` — Tier 3a ISel quality probes

**10 small C snippets** that pin down the agent's instruction-selection quality.

For each snippet, the grader compiles with `clang -O2 -march=rv64gc_xbestisa` and grep-counts a specific mnemonic in the output `.s`. The count must meet or exceed the threshold in `<snippet>.expected_count`.

## Format

Each snippet is two files:
- `XX_name.c` — pure C source, no inline asm, no builtins (the point is to test that idiomatic C selects the new instruction).
- `XX_name.expected_count` — single line: `<mnemonic> <min_count>`, e.g. `bestisa.andn3 1`.

## Inventory

| # | Snippet | Mnemonic | Min count | Idiomatic pattern |
|---|---|---|---|---|
| 01 | `andn3_simple.c`   | `bestisa.andn3` | 1 | `a & ~b & ~c` |
| 02 | `andn3_commuted.c` | `bestisa.andn3` | 1 | `~b & ~c & a` (commuted source order) |
| 03 | `xor3_simple.c`    | `bestisa.xor3`  | 1 | `a ^ b ^ c` |
| 04 | `xor3_assoc.c`     | `bestisa.xor3`  | 1 | `(a ^ b) ^ c` written as `a ^ (b ^ c)` |
| 05 | `xor3_unrolled.c`  | `bestisa.xor3`  | 4 | 8-way XOR fold → at least 4 instances after `-O2` |
| 06 | `maddw_simple.c`   | `bestisa.maddw` | 1 | `int32_t r = a + b * c;` |
| 07 | `maddw_loop.c`     | `bestisa.maddw` | 1 | accumulator loop body, expect MADDW after vectorizer-aware combiner |
| 08 | `sha256ch_simple.c`| `bestisa.sha256ch` | 1 | `(e & f) ^ (~e & g)` |
| 09 | `sha256ch_round.c` | `bestisa.sha256ch` | 1 | one SHA-256 compression round |
| 10 | `mixed_three.c`    | `bestisa.xor3`  | 1 | function uses andn3 + xor3 + maddw — count xor3 only |

> Note: `clmulacc` and `bfly` are intentionally absent — they have no canonical scalar IR pattern, so testing ISel for them via natural C is unreasonable. Their coverage is in Tier 1c (intrinsic-based `.ll` tests) and Tier 2 (builtin-path execution).

## What "natural C" means here

- No inline asm.
- No `__builtin_riscv_bestisa_*` builtins.
- Plain integer expressions a competent C programmer would write without thinking about the target ISA.
- The IR after `O2` should match (or be foldable to) the patterns in §7 of `docs/XBestISA_spec.md`.

If the agent's patterns only match the builtin-emitted intrinsic but not idiomatic C, Tier 3a fails. This catches the **"tests pass but instruction not selected"** silent failure.

See `01_andn3_simple.c` for the canonical structure.
