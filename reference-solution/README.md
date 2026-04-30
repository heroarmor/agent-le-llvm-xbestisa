# `reference-solution/` — Gold-standard expert solution

**This directory is sealed in the released benchmark.** It contains the expert solution that achieves 100/100 on the rubric. The agent does NOT see these files at task time.

## Contents (in the released benchmark, not in this public repo)

- `solution.patch` — unified diff against `llvmorg-22.1.0` containing the full expert implementation. Approximately:
  - ~900 LOC of source across ~14 files
  - ~1,400 LOC of new tests across ~20 files
- `scorecard.json` — output of `grade.sh` against `solution.patch`, showing 100/100.
- `BUILD_LOG.txt`, `TEST_LOG.txt` — full logs of the reference build and test runs.
- `walkthrough.md` — file-by-file commentary on the expert diff: what was changed, why, what the alternatives were, and what the common pitfalls are.

## File-by-file inventory of the expert diff (preview)

| File | LOC ± | Why |
|---|---|---|
| `llvm/lib/Target/RISCV/RISCVFeatures.td` | +12 | Define `FeatureVendorXBestISA`, predicate, assembler predicate |
| `llvm/lib/Target/RISCV/RISCVInstrFormats.td` | +18 | Add R4-with-funct2 format class for the 4 R4 instructions |
| `llvm/lib/Target/RISCV/RISCVInstrInfoXBestISA.td` (new) | +280 | Definitions, ISel patterns, scheduling assignments for all 6 |
| `llvm/lib/Target/RISCV/RISCVInstrInfo.td` | +2 | Include `RISCVInstrInfoXBestISA.td` |
| `llvm/lib/Target/RISCV/RISCVSchedRocket.td` | +6 | Itinerary entry for `IIC_BestISA` |
| `llvm/lib/Target/RISCV/RISCVSchedSiFive7.td` | +6 | Same |
| `llvm/include/llvm/IR/IntrinsicsRISCV.td` | +25 | Declare 6 intrinsics |
| `clang/include/clang/Basic/BuiltinsRISCV.def` | +10 | Declare 6 builtins gated by `xbestisa` |
| `clang/lib/CodeGen/CGBuiltin.cpp` | +35 | Lower builtins to intrinsics |
| `llvm/lib/TargetParser/RISCVISAInfo.cpp` | +3 | Register `xbestisa` token |
| `llvm/include/llvm/TargetParser/RISCVTargetParser.def` | +1 | Version table entry |
| `llvm/unittests/TargetParser/RISCVISAInfoTest.cpp` | +12 | Unit test for the new token |
| `llvm/docs/RISCVUsage.rst` | +18 | User-facing docs |
| `llvm/docs/ReleaseNotes.md` | +3 | Release-notes entry |

Tests authored by the expert (separate from the harness-provided `tests/` corpus):

| New test file | LOC |
|---|---|
| `llvm/test/MC/RISCV/xbestisa-valid.s` | +180 |
| `llvm/test/MC/RISCV/xbestisa-invalid.s` | +60 |
| `llvm/test/CodeGen/RISCV/xbestisa.ll` | +400 |
| `llvm/test/CodeGen/RISCV/xbestisa-intrinsic.ll` | +250 |
| `llvm/test/CodeGen/RISCV/xbestisa-pattern-match.ll` | +180 |
| `llvm/test/CodeGen/RISCV/attributes.ll` | +12 (additions) |
| `llvm/test/CodeGen/RISCV/features-info.ll` | +1 |
| `llvm/test/Driver/riscv-march.c` | +4 |
| Clang tests (`clang/test/CodeGen/RISCV/`) | +320 |

Total: ~900 LOC source + ~1,407 LOC tests = ~2,307 LOC across 23 files.

## What this preview tells the reviewer

- The task IS doable in the stated budget — total diff is well under the 5,000-LOC ceiling that LLVM PR reviewers typically accept in a single review.
- The diff is **horizontal** (touches many small files) rather than **vertical** (huge changes to one file). This is the actual shape of upstream vendor-extension PRs.
- An agent that produces a deeper diff (>1,500 LOC source) is probably over-engineering; one that produces a shallower diff (<400 LOC source) is probably missing intrinsics, scheduling, or proper test coverage.

## How to regenerate the reference solution

```bash
cd llvm-project
git checkout llvmorg-22.1.0
git apply ../reference-solution/solution.patch
ninja -C build clang llc llvm-mc -j$(nproc)
bash ../grader/grade.sh
diff ../scorecard.json ../reference-solution/scorecard.json   # should be empty
```
