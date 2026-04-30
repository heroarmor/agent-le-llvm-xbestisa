# Task: Add LLVM Backend Support for the `XBestISA` RISC-V Vendor Extension

## Objective

Add **complete LLVM backend support** for a 6-instruction RISC-V vendor extension named `XBestISA`. After your changes, the following must hold:

1. **Compilation**: `clang --target=riscv64-unknown-elf -march=rv64gc_xbestisa -O2 prog.c -o prog.elf` succeeds for any valid C program and emits the new instructions for idiomatic patterns.
2. **Execution**: The resulting `prog.elf` runs **bit-exactly on the provided Spike simulator** (the correctness oracle) versus the same program compiled with `-march=rv64gc` and run on baseline Spike.
3. **MC layer round-trip**: All 6 instructions assemble, disassemble, and re-assemble to identical bytes.
4. **No regression**: Every pre-existing `llvm/test/CodeGen/RISCV/` and `llvm/test/MC/RISCV/` lit test continues to pass.

## Starting state (provided in `/work/`)

- **`llvm-project/`** — pinned to `llvmorg-22.1.0`, pre-built into `build/` with warm `ccache` (~60 s incremental builds for the RISCV target).
- **`spike/`** — pre-built `riscv-isa-sim` binary that **already implements** the six `XBestISA` instructions in `riscv/insns/bestisa_*.h` and `riscv/encoding.h`. **This is the correctness oracle. You MUST NOT modify it.** A SHA-256 of the oracle binary is verified at the start of each `grade.sh` run.
- **`docs/XBestISA_spec.md`** — the ISA specification: mnemonics, R/R4 encoding bit-layouts, pseudocode semantics, pipeline latency. **This is your only requirements document.**
- **`llvm-test-suite/`** — checked out at the matching tag, configured for `riscv64-unknown-elf` cross-compilation.
- **`tests/agent_le/`** — task harness (see [`docs/grading_rubric.md`](docs/grading_rubric.md) for full breakdown):
  - `correctness/` — 30 hand-written `.c` programs with reference outputs.
  - `codegen/` — 10 `.c` snippets each annotated with the exact mnemonic and minimum count expected in `llc -O2` output.
  - `mc/{valid,invalid}/` — 20 `.s` files with golden encoded hex.
  - `regression/baseline_lit.txt` — full list of pre-existing lit tests that must keep passing.
- **`grader/grade.sh`** — automated grader; emits `scorecard.json`.
- **`examples/`** — **read-only** pointers to upstream `XTHead`, `XSf`, and `XAndes` extension files for reference. Study them as exemplars; do NOT copy them blindly (semantics differ).

## What you must add

End-to-end LLVM support, touching every layer:

1. **Subtarget feature**
   - `def FeatureVendorXBestISA : SubtargetFeature<"xbestisa", ...>` in `llvm/lib/Target/RISCV/RISCVFeatures.td`.
   - Matching `Predicate` and `AssemblerPredicate`.
   - Update `llvm/lib/TargetParser/RISCVISAInfo.cpp` and `llvm/include/llvm/TargetParser/RISCVTargetParser.def`.

2. **Instruction definitions** (new file)
   - `llvm/lib/Target/RISCV/RISCVInstrInfoXBestISA.td` defining all 6 instructions with correct bit-layout, register classes, and assembler syntax.
   - Add a new instruction format if needed in `llvm/lib/Target/RISCV/RISCVInstrFormats.td` (R4-with-funct2 is the format you'll likely need for the 4 R4 instructions).

3. **ISel patterns**
   - `Pat<>` records (or `RISCVISelLowering.cpp` lowering hooks) sufficient to select these instructions from idiomatic IR for at least the 10 codegen snippets in `tests/codegen/`.
   - For pattern-only selection: write commutative variants where appropriate.

4. **Clang builtins + LLVM IR intrinsics**
   - `__builtin_riscv_bestisa_*` declared in `clang/include/clang/Basic/BuiltinsRISCV.def`.
   - Lowered via `clang/lib/CodeGen/CGBuiltin.cpp` to intrinsics declared in `llvm/include/llvm/IR/IntrinsicsRISCV.td`.

5. **Scheduling itinerary**
   - SchedRW classes / itinerary entries in `RISCVSchedRocket.td` and `RISCVSchedSiFive7.td` matching the spec (3-cycle latency, single issue port `M`).
   - No `MISched` warnings on full-build.

6. **MC layer**
   - Assembler accepts all valid forms (parser in `RISCVAsmParser.cpp`), rejects invalid forms with sensible diagnostics.
   - Disassembler in `RISCVDisassembler.cpp` decodes the new opcodes.

7. **Tests**
   - Author your own MC `-valid.s`/`-invalid.s` files in `llvm/test/MC/RISCV/xbestisa-*.s`.
   - Author your own CodeGen `.ll` files in `llvm/test/CodeGen/RISCV/xbestisa-*.ll` with `CHECK:` lines.
   - Update `llvm/test/CodeGen/RISCV/attributes.ll` and `features-info.ll`.
   - Update `llvm/unittests/TargetParser/RISCVISAInfoTest.cpp`.

8. **Documentation**
   - Add a section to `llvm/docs/RISCVUsage.rst` describing the extension.
   - Add a release notes entry to `llvm/docs/ReleaseNotes.md`.

## Hard rules

- **Spike binary, ISA spec PDF, harness scripts, and all files under `tests/`, `examples/`, `regression/`, `docs/`, and `spike-patch/` are READ-ONLY.** Tampering causes immediate Tier 0 failure.
- The 6 instructions must be selected **from natural C** (Tier 3a), not only reachable via the intrinsic.
- No regression in any pre-existing lit test (Tier 1 + Tier 3b).
- Total wall-clock budget: **24 hours**.
- Final deliverable: a clean `git diff` against `llvmorg-22.1.0` plus a passing `scorecard.json` produced by `grade.sh`.

## Iteration loop

```bash
# Edit
$EDITOR llvm-project/llvm/lib/Target/RISCV/RISCVInstrInfoXBestISA.td

# Rebuild (warm incremental, ~60 s)
ninja -C llvm-project/build clang llc llvm-mc

# Test a single tier first for fast feedback
bash grader/tier1_lit.sh

# Full grade when ready
bash grader/grade.sh
cat scorecard.json
```

## Success thresholds

| Score | Status |
|---|---|
| ≥ 95 / 100 | **Strong pass** |
| ≥ 80 / 100 | **Pass** |
| < 80 / 100 | Fail |

See [`docs/grading_rubric.md`](docs/grading_rubric.md) for the full deterministic rubric.

## References

- [`docs/XBestISA_spec.md`](docs/XBestISA_spec.md) — the ISA spec
- [`docs/environment.md`](docs/environment.md) — build env, hardware reqs, Docker
- [`docs/reproducibility.md`](docs/reproducibility.md) — version pins, oracle integrity
- [`examples/README.md`](examples/README.md) — pointers to upstream vendor extensions
- LLVM upstream: [Writing an LLVM Backend](https://llvm.org/docs/WritingAnLLVMBackend.html), [User Guide for RISC-V Target](https://llvm.org/docs/RISCVUsage.html)
- Real-world reference PR (smaller scope): [Andes `XAndesVPackFPH` — PR #138827](https://github.com/llvm/llvm-project/pull/138827)
