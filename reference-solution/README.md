# `reference-solution/` — Gold-standard expert solution

> **Status:** As of commit on 2026-05-01, this directory contains a **real, verified, end-to-end working** reference solution — not a placeholder. The 216-line LLVM patch (`solution.patch`) and 138-line Spike patch (`../spike-patch/0001-add-xbestisa-extension.patch`) together apply cleanly, build green, and pass byte-exact differential execution on Spike. Full evidence is in `BUILD_LOG.txt`, `E2E_LOG.txt`, and `scorecard.json`.

**In the released benchmark this directory is sealed** — the agent under test does NOT see these files. The harness ships them in a separate Drive bundle that the grader uses to compare against.

## Contents

- **`solution.patch`** (216 lines, **verified working**) — unified diff against `llvmorg-18.1.3` adding the 7-instruction XBestISA extension. Touches: `RISCVISAInfo.cpp`, `RISCVFeatures.td`, `RISCVInstrInfo.td`, plus a new `RISCVInstrInfoBestISA.td` with format classes, instruction defs, and ISel patterns.
- **`BUILD_LOG.txt`** — ninja output proving the patch builds clean (clang/llc/llvm-mc/llvm-objdump all link green).
- **`E2E_LOG.txt`** — verified end-to-end run showing: idiomatic C → ISel emits `bestisa.xor3`/`bestisa.add3`/`bestisa.sha256ch` → patched Spike executes them → output is byte-exact identical to baseline.
- **`scorecard.json`** — partial-real-corpus run showing Tier 0 (build, 5/5) + Tier 2 (Spike differential, 1/1 e2e) + Tier 3a (xor3, sha256ch select correctly) all PASS. Other tiers deferred pending corpus build-out.
- **`walkthrough.md`** — file-by-file commentary on both patches: what each change does, why, what the alternatives were, and the 5 specific time-burn pitfalls an unaware agent will hit.

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
git checkout llvmorg-18.1.3
git apply ../reference-solution/solution.patch
ninja -C build clang llc llvm-mc -j$(nproc)
bash ../grader/grade.sh
diff ../scorecard.json ../reference-solution/scorecard.json   # should be empty
```
