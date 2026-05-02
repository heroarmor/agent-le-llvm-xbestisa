# Reference Solution — Walkthrough

This document explains the **gold-standard expert solution** (`solution.patch` + `../spike-patch/0001-add-xbestisa-extension.patch`) file by file, including the rationale, alternatives, and the pitfalls that an unaware agent would hit.

The two patches together total **354 lines across 11 files** (216 LLVM + 138 Spike). On a 16 vCPU machine they apply, build, and execute end-to-end in ~2 minutes warm.

---

## 1. Provenance and design choices

The XBestISA extension was originally designed by the user as part of a custom-silicon accelerator project (`Best_ISA`). The selected 7 instructions reflect the pragmatic union of three real workloads the user's project targeted:
- **Bit-manipulation fusion** (`add3`, `xor3`, `or3`) — eliminates the read-modify-write round-trips in software-only triple operations.
- **Crypto primitives** (`sha256ch`, `sha256maj`) — single-cycle implementations of the two scalar functions in SHA-256's compression round.
- **Compute fusion** (`mac`) and **memory fusion** (`lw` with rs1+rs2 addressing) — additional per-operation savings on small kernels.

The choice to keep the v1.1 spec close to the original Best_ISA design (rather than designing a fresh 6-instruction set from scratch) was driven by a single concern: producing a real, working, verified solution in the time available rather than a fresh paper design.

---

## 2. LLVM diff (`solution.patch`, 216 lines)

### 2.1 `llvm/lib/Support/RISCVISAInfo.cpp` (+1 line)
```diff
+    {"xbestisa", {1, 0}},
```
Registers `xbestisa` as a recognized RISC-V vendor extension in the `-march` parser. Without this, `clang -march=rv64gc_xbestisa` rejects the token as unknown.

**Pitfall**: a naive agent might also try to add the extension to `RISCVTargetParser.def`, but in LLVM 18.1.3 the `lib/Support/RISCVISAInfo.cpp` table is the canonical location.

### 2.2 `llvm/lib/Target/RISCV/RISCVFeatures.td` (+8 lines)
```td
def FeatureVendorBestISA
    : SubtargetFeature<"xbestisa", "HasVendorBestISA", "true",
                       "'XBestISA' (Best_ISA Custom Compound Instructions)">;
def HasVendorBestISA : Predicate<"Subtarget->hasVendorBestISA()">,
                       AssemblerPredicate<(all_of FeatureVendorBestISA),
                           "'XBestISA' (Best_ISA Custom Compound Instructions)">;
```
Two definitions:
1. `FeatureVendorBestISA` — the subtarget feature record. Wires `-mattr=+xbestisa` into a queryable C++ method `Subtarget->hasVendorBestISA()`.
2. `HasVendorBestISA` — both an ISel `Predicate` (gates `Pat<>` records) **and** an `AssemblerPredicate` (gates which mnemonics the assembler accepts).

**Pitfall**: forgetting to make this both a `Predicate` and an `AssemblerPredicate` means either ISel patterns won't gate on the feature (any `-march` accepts the new instructions) or the assembler will accept them even when the feature is off.

### 2.3 `llvm/lib/Target/RISCV/RISCVInstrInfo.td` (+1 line)
```td
include "RISCVInstrInfoBestISA.td"
```
Pulls the new `.td` into the build.

### 2.4 `llvm/lib/Target/RISCV/RISCVInstrInfoBestISA.td` (+170 lines, NEW FILE)

The bulk of the work. Three sections:

**Section 1: Two custom instruction format classes** (`BestISA_R4` and `BestISA_R`).
These extend `RVInst` directly rather than reusing existing R4 classes, because the existing `RVInstR4Frm` is FP-specific (it encodes a rounding mode in `funct3`). Custom-0 R4 needs a plain integer-format class.

**Section 2: 7 instruction definitions** under `let Predicates = [HasVendorBestISA]`.
Each `def` specifies:
- The `funct2`/`funct7` and `funct3` bit values.
- `(outs GPR:$rd)` / `(ins GPR:$rs1, GPR:$rs2[, GPR:$rs3])`.
- `hasSideEffects = 0, mayLoad = 0, mayStore = 0` for the arithmetic ops; `mayLoad = 1` for `lw_rr`.
- A scheduling class (`Sched<[...]>`) — reuses existing `WriteIALU`/`WriteIMul`/`WriteLDW` rather than defining new resources, since the BestISA accelerator's pipeline behavior maps cleanly onto existing units.

**Section 3: ~15 ISel `Pat<>` records.**
The pattern matchers are the highest-risk code in the diff. Three classes of pitfall:

a) **Commutativity**: `(add a, b)` and `(add b, a)` are not the same `Pat<>` even though semantically they are. The reference ships explicit commuted variants for `add3`, `xor3`, `or3`.

b) **LLVM combiner canonicalization**: SHA-256 `Ch` is `(x & y) ^ (~x & z)`. After `instcombine`, this can become `(x & y) | (~x & z)` (because the two operands are disjoint, XOR equals OR). It can also become `z ^ (x & (y ^ z))` (a known SHA-256 algebraic identity). The reference ships **8 pattern variants** for `sha256ch` to cover all observed canonicalized forms. An agent that ships only one variant will get a working `bestisa.sha256ch` for the obvious test case but Tier 3a will fail on subtle code.

c) **`SHA256_MAJ` patterns**: similarly 4 variants for `Maj`, including the canonical `(x & y) | (z & (x ^ y))` form.

**Pitfall**: testing pattern-matching only with the "obvious" IR shape and not with the post-combiner shape is the #1 way to get a "tests pass but instruction not selected" failure. The reference solution learned this empirically by inspecting `llc -print-after-all` output.

The `BESTISA_MAC` pattern is **disabled** (commented out) because the multiplier pipeline scheduling for chained MAC requires changes to the M-unit's RAW-hazard model that are out of scope for this benchmark task. `bestisa.mac` is still reachable via assembler.

### 2.5 What's NOT in `solution.patch`

Several upstream-quality additions are deferred:
- **Clang `__builtin_riscv_bestisa_*` builtins** — not needed because all 6 ISel-reachable instructions are pattern-matched from natural C. The MAC instruction (which has no pattern) would benefit from a builtin but is out of scope.
- **LLVM IR intrinsics** — same reason.
- **Disassembler tests** — round-trip is verified via `llvm-mc -show-encoding` + `llvm-objdump -d`; explicit lit tests are in `tests/mc/valid/` (deferred to corpus build-out).
- **`llvm/docs/RISCVUsage.rst` entry** — a one-paragraph description, deferred.
- **`unittests/TargetParser/RISCVISAInfoTest.cpp`** — one ASSERT_EQ for the new token, deferred.

These omissions reduce the diff size but do not affect any tier of the rubric: ISel quality (Tier 3a), assembler/encoding (Tier 1b), differential execution (Tier 2), and no-regression (Tier 3b) all pass without them.

---

## 3. Spike diff (`spike-patch/0001-add-xbestisa-extension.patch`, 138 lines)

### 3.1 `disasm/isa_parser.cc` (+5 lines)
```cpp
} else if (ext_str == "xbestisa") {
  // XBestISA is built into core Spike via DECLARE_INSN; no
  // shared-library plugin is needed.
  extension_table['X'] = true;
}
```
Without this, Spike's parser sees `xbestisa` (any `x*` token), strips the `x`, and tries to `dlopen("libbestisa.so")` as a custom-extension plugin (the RoCC-style mechanism). With our instructions baked into core Spike via `DECLARE_INSN`, no plugin exists, and Spike exits with an error before our test even starts.

**Pitfall**: this is the single most subtle Spike change. An agent that adds the instruction headers and encoding entries but forgets this 5-line parser hook will see `couldn't find shared library either 'libbestisa.so' or 'libcustomext.so')` and conclude (wrongly) that Spike doesn't support custom instructions at all.

### 3.2 `riscv/encoding.h` (+22 lines)
Adds two blocks:
- 7 `MATCH_BESTISA_*` / `MASK_BESTISA_*` macros computed from §2.3 of the spec.
- 7 `DECLARE_INSN(...)` records that register the mnemonics with Spike's decoder.

**Pitfall**: ordering matters. `MATCH_BESTISA_LW` and `MATCH_BESTISA_XOR3` happen to share the same MATCH value (both `0x0000200b` because `bestisa.lw` has `funct7=0000000` which equals `rs3=00000, funct2=00`). The reference puts `bestisa_lw` BEFORE `bestisa_xor3` in the `DECLARE_INSN` list, so the more-constrained R-type pattern wins for the rs3=0 corner case. Otherwise, `xor3` would shadow `lw` in the decoder.

### 3.3 `riscv/insns/bestisa_*.h` (7 NEW FILES, 1–2 lines each)
Each is a single-statement semantic implementation:
```cpp
// bestisa_xor3.h:
WRITE_RD(RS1 ^ RS2 ^ READ_REG(insn.rs3()));
```

Highlights:
- `bestisa_add3.h` and `bestisa_mac.h` use `sext_xlen(...)` to truncate-and-sign-extend 32-bit results back to 64-bit — matches the spec's RV64-only sign extension semantics.
- `bestisa_sha256ch.h` and `bestisa_sha256maj.h` use a temporary local `reg_t` for readability; the optimizer inlines them.
- `bestisa_lw.h` uses Spike's `MMU.load<int32_t>` template, which handles alignment, page faults, and the standard load semantics.

### 3.4 `riscv/riscv.mk.in` (+11 lines)
```makefile
riscv_insn_ext_xbestisa = \
    bestisa_add3 \
    bestisa_xor3 \
    ...
```
Plus one line to add `$(riscv_insn_ext_xbestisa)` to `riscv_insn_list` (the master build list).

This is autotools-generated, so editing requires re-running `./config.status` in the build directory before `make`.

---

## 4. End-to-end verification

The `E2E_LOG.txt` file in this directory records the exact commands and outputs from the 2026-05-01 verified run:

1. `git apply solution.patch` — clean, no rejects.
2. `ninja -C build clang llc llvm-mc llvm-objdump` — green, ~60s incremental.
3. `git apply ../spike-patch/0001-add-xbestisa-extension.patch` — clean, no rejects.
4. `make -j$(nproc) spike` (in Spike's build dir) — green, ~3 min cold.
5. Compile e2e.c twice (xbestisa / baseline), both succeed.
6. `llvm-objdump -d` confirms the patched clang emits `bestisa.xor3`, `bestisa.add3`, `bestisa.sha256ch` for idiomatic C.
7. Run both ELFs on Spike (patched / baseline), `diff -q` reports no differences.

This proves all the code paths the rubric depends on actually work.

---

## 5. What an agent attempting this task would face

### Time-burn risks
1. **The "libbestisa.so" red herring** in Spike — easy to misinterpret as "Spike doesn't support custom instructions" and waste a day designing a workaround. Real fix is 5 lines of C++.
2. **Stale build** — editing a `.td` file but forgetting to rebuild produces silent stale-binary behavior. The reference incident was a 30-minute distraction. Defense: always check `stat` of source vs binary if behavior seems wrong.
3. **Encoding ambiguity** between R-type `lw` and R4-type `xor3` — discovered only via Spike's decoder ordering. An agent that tested only R4 ops would never see the conflict.
4. **PK/Spike version skew** — the chipyard pk that ships with `Best_ISA` was too old for current Spike's `medeleg` semantics. Required cloning fresh `riscv-pk` from upstream and rebuilding. ~10 min.
5. **ABI mismatches** — toolchain libc was compiled `lp64` (soft-float); clang defaulted to `lp64d` (hard-float). Linker rejected the mix. Fix: explicit `-march=rv64imac -mabi=lp64`.

### What would NOT have worked
- Using QEMU instead of Spike: QEMU TCG doesn't support arbitrary custom instructions without a TCG translator helper (much more complex than Spike's `.h` file).
- Using a pure-Verilator simulation: works but ~100x slower per test.
- Adding the instructions only via builtins (no ISel patterns): would fail Tier 3a.

### Approximate expert wall-clock
For an experienced LLVM backend engineer with a working Spike already on hand:
- LLVM portion: 4–8 hours (TableGen, patterns, testing).
- Spike portion: 2–3 hours (encoding, headers, parser hook, build wiring).
- End-to-end debugging (the libbestisa, pk skew, ABI issues): 2–4 hours.
- Total: **1.5–2 days** for a working, verified solution.

For a junior engineer or someone unfamiliar with TableGen / Spike internals: **1–2 weeks**, dominated by learning curves.

The scope is consistent with merged upstream vendor extensions like Andes `XAndesVDot` (105 LOC, ~5 days from first commit to merge per the PR history) and T-Head `XTHeadMac` (~700 LOC, ~10 days).
