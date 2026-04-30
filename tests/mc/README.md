# `tests/mc/` — Tier 1b assembler/disassembler tests

20 MC-layer tests: 10 valid + 10 invalid. Total: 10 pts.

## Format

### `valid/<name>.s` + `valid/<name>.expected`
- The `.s` file contains one or more assembler statements.
- The `.expected` file contains the byte-exact stdout of:
  ```
  llvm-mc -triple=riscv64 -mattr=+xbestisa -show-encoding <name>.s
  ```
- Note: the encoding hex bytes in the bundled `.expected` files are **illustrative**. The grader regenerates the expected output by running `llvm-mc` against a reference toolchain build with the gold-standard solution applied (located at `reference-solution/`), so any small whitespace/format differences in the bundled samples are fine — the grader compares against freshly-regenerated golden output.

### `invalid/<name>.s` + `invalid/<name>.expected_err`
- The `.s` file contains a single intentionally-invalid statement.
- The `.expected_err` file contains a substring that must appear in the assembler's stderr.

## Inventory

### `valid/` (10 files)
| File | What it tests |
|---|---|
| `andn3.s` | basic `bestisa.andn3` with various register classes |
| `xor3.s` | basic `bestisa.xor3` |
| `maddw.s` | basic `bestisa.maddw` |
| `sha256ch.s` | basic `bestisa.sha256ch` |
| `clmulacc.s` | basic `bestisa.clmulacc` (R-type) |
| `bfly.s` | basic `bestisa.bfly` (R-type) |
| `all_register_classes.s` | each instruction with `x0`/`x31`/named ABI |
| `comments_whitespace.s` | tolerant of comments and odd whitespace |
| `mixed_with_base.s` | new instructions interleaved with `add`/`xor`/etc. |
| `pseudo_aliases.s` | aliases (if any defined) round-trip correctly |

### `invalid/` (10 files)
| File | What it tests |
|---|---|
| `wrong_arity_andn3.s` | `bestisa.andn3` with only 2 operands |
| `wrong_arity_clmulacc.s` | `bestisa.clmulacc` with 4 operands (it's R-type, takes 3) |
| `bad_register.s` | `bestisa.xor3 x32, ...` |
| `immediate_operand.s` | `bestisa.maddw a0, a1, a2, 5` (no immediates) |
| `feature_disabled.s` | source at `-mattr=-xbestisa` (grader runs with `+xbestisa`, so this file uses `.attribute` directive) |
| `typo_mnemonic.s` | `bestisa.andn4` (not a valid mnemonic) |
| `wrong_funct_disasm.s` | encoded blob with reserved funct2; disassembler must reject |
| `fp_register.s` | `bestisa.xor3 fa0, fa1, fa2, fa3` |
| `csr_register.s` | `bestisa.xor3 mstatus, ...` |
| `missing_operand.s` | `bestisa.maddw a0, a1, a2` |
