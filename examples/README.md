# `examples/` — Read-only pointers to upstream LLVM vendor extensions

This directory does NOT contain copies of upstream code. It contains pointers and excerpt summaries of the most useful **real-world** LLVM RISC-V vendor extensions the agent should study as exemplars.

These are merged into LLVM mainline and live under `llvm/lib/Target/RISCV/` in any LLVM checkout. The Docker image's `llvm-project/` provides the full source.

> ⚠️ The agent may **read** these files freely as reference. The agent must NOT copy them verbatim — `XBestISA` semantics differ from each. Pattern recognition / structural mimicry is fine; line-by-line copying produces an obviously-wrong solution that fails Tier 2.

## Recommended reading order (closest-shape-first)

### 1. T-Head `XTHead*` family (most directly analogous)
- `llvm/lib/Target/RISCV/RISCVInstrInfoXTHead.td` (911 LOC)
  - Defines the entire T-Head vendor extension: `XTHeadBa`, `XTHeadBb`, `XTHeadBs`, `XTHeadCondMov`, `XTHeadFMemIdx`, `XTHeadMac`, `XTHeadMemIdx`, `XTHeadMemPair`, `XTHeadSync`, `XTHeadVdot`.
  - **Closest analogue for `XBestISA`**: `XTHeadMac` — 4 fused multiply-accumulate instructions, same R/R4 split, same scheduling shape.
- Tests: `llvm/test/CodeGen/RISCV/rv64xtheadba.ll`, `rv64xtheadbb.ll`, `xtheadmac.ll`.
- Real merged PRs:
  - https://reviews.llvm.org/D143029  (`XTHeadBa`)
  - https://reviews.llvm.org/D143439  (`XTHeadBb`)
  - https://reviews.llvm.org/D143440  (`XTHeadBs`)

### 2. SiFive `XSf*` family (intrinsic/builtin patterns)
- `llvm/lib/Target/RISCV/RISCVInstrInfoXSf.td` (675 LOC)
- Best to study for: how to wire up `__builtin_riscv_sf_*` builtins → `llvm.riscv.sf.*` intrinsics → `Pat<>` records. Template for §6 of `docs/XBestISA_spec.md`.

### 3. Andes `XAndes*` (smallest scope — start here for sizing intuition)
- `llvm/lib/Target/RISCV/RISCVInstrInfoXAndes.td`
- PR #138827 (XAndesVPackFPH): 93 LOC across 10 files. Smallest realistic precedent.
- PR #139849 (XAndesVDot): 105 LOC, similar shape.

### 4. OpenHW CORE-V `XCV*` (good multi-format example)
- `llvm/lib/Target/RISCV/RISCVInstrInfoXCV.td` (706 LOC)
- Spans bitmanip, MAC, SIMD — useful for seeing how to multiplex one extension across several formats.

### 5. Ventana `XVentanaCondOps` (smallest in-tree example)
- `llvm/lib/Target/RISCV/RISCVInstrInfoXVentana.td` (45 LOC)
- Good for understanding the absolute minimum boilerplate: feature flag + 1 instruction + 1 pattern.

## Cross-cutting files the agent will need to edit

These are NOT vendor-specific but the agent will need to modify them. Skim how the existing extensions touch them:

| File | What it does | Existing extension touches it via... |
|---|---|---|
| `RISCVFeatures.td` | Defines `FeatureVendorX*` and `Predicate` records | grep `FeatureVendorX` |
| `RISCVInstrFormats.td` | Bit-layout classes (`RVInstR`, `RVInstR4`, etc.) | grep `RVInstR4` to find the R4 base class |
| `RISCVISelLowering.cpp` | `LowerINTRINSIC_*` for non-pattern lowering | grep `Intrinsic::riscv_sf_` |
| `RISCVISelDAGToDAG.cpp` | Custom node matching when `Pat<>` insufficient | rare; check for `selectImm` / `selectShiftMask` |
| `IntrinsicsRISCV.td` (in `include/llvm/IR/`) | LLVM IR intrinsic declarations | grep `int_riscv_sf_` for SiFive examples |
| `BuiltinsRISCV.def` (in `clang/include/clang/Basic/`) | Clang builtin declarations | grep `BUILTIN(__builtin_riscv_sf_` |
| `CGBuiltin.cpp` (in `clang/lib/CodeGen/`) | Builtin → IR lowering | grep `Builtin::BI__builtin_riscv_` |
| `RISCVISAInfo.cpp` (in `lib/TargetParser/`) | `-march=` token parser | grep `xtheadba` |
| `RISCVTargetParser.def` | Extension version table | grep `XTHeadBa` |
| `RISCVUsage.rst` (in `docs/`) | User-facing extension docs | grep `XTHeadBa` |

## Real-world build / test scripts

The CMake invocation, lit invocation, and `llvm-test-suite` setup the upstream RISC-V vendors use are exactly the same as in `docs/environment.md`. Notable LLVM build references:

- https://llvm.org/docs/CMake.html
- https://llvm.org/docs/CommandGuide/lit.html
- https://llvm.org/docs/RISCVUsage.html

## What this directory does NOT contain

To stay within the GitHub repo size budget and to avoid duplicating the upstream LLVM tree, this directory does NOT include local copies. The Docker image and Drive-shipped tarball ship the full `llvm-project/` source tree at the pinned tag — read those files there.
