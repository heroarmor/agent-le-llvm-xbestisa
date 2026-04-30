# `tests/regression/` — no-regression baselines

Two artifacts:

## `baseline_lit.txt`
Newline-separated list of paths (relative to `llvm-project/`) to pre-existing lit tests that **must keep passing** after the agent's changes. The grader runs `llvm-lit -j1 --order=lexical` on each.

The shipped file lists every test under:
- `llvm/test/CodeGen/RISCV/`
- `llvm/test/MC/RISCV/`
- `llvm/test/Transforms/SLPVectorizer/RISCV/` (some patterns affected by RISCV cost model)
- `clang/test/Driver/riscv-*.c`
- `clang/test/Preprocessor/riscv-target-features.c`

…that exist in `llvmorg-22.1.0`. Total: ~1,850 tests.

If the agent **modifies** any test in this list, Tier 0 fails (forbidden-paths check). The agent may **add** new test files alongside them.

## `baseline_codegen/`
50 standalone C compilation units used as input to Tier 3b's opcode-histogram regression check. These are short, self-contained C functions that span common patterns (arithmetic, control flow, memory ops, function calls, struct access). Each must, when compiled with `clang -O2 -march=rv64gc -c`, produce identical opcode-mnemonic histograms between the agent's clang and the reference clang.

Files are named `0XX_<short-description>.c`. Source: hand-curated from a mix of CompCert benchmarks, llvm-test-suite SingleSource, and original snippets — all redistributed under their original Apache-2.0 / MIT licenses.

See `baseline_codegen/_TODO.md` for the full inventory and licensing notes.
