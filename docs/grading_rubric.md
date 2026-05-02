# Grading Rubric

`grader/grade.sh` runs the four tiers below and emits `scorecard.json`. **All comparisons are deterministic** (byte-exact, opcode-set-exact, or test-pass-counts). Two runs of `grade.sh` on the same submission produce identical scores.

| Tier | What | Points |
|------|------|--------|
| 0    | Build sanity | 5 |
| 1    | `llvm-lit` regression + new MC + new CodeGen `CHECK:` | 30 |
| 2    | Differential execution on Spike (oracle) | 35 |
| 3a   | Instruction selection from natural C | 15 |
| 3b   | No opcode-set regression on 50 baselines | 5 |
| 4    | End-to-end `llvm-test-suite` SingleSource subset on Spike | 10 |
|      | **Total** | **100** |

| Score | Status |
|---|---|
| ≥ 95 / 100 | **Strong pass** |
| ≥ 80 / 100 | **Pass** |
| < 80 / 100 | Fail |

---

## Tier 0 — Build sanity (5 pts)

Binary pass/fail. **5 if all green, else 0.**

```bash
cmake --build llvm-project/build --target clang llc llvm-mc llvm-tblgen
# all four exit 0
llvm-tblgen ...all modified .td files...   # exit 0
```

Also checks oracle integrity: `sha256sum spike/build/spike` must match the value pinned in `scripts/verify_oracle.sh`. Tampering with the oracle = automatic Tier 0 = 0 = whole-task fail (the rubric rejects the submission).

---

## Tier 1 — `llvm-lit` regression + new MC + CodeGen (30 pts)

Three sub-checks, each contributing proportionally.

### 1a. Pre-existing lit tests (15 pts)
- Run `llvm-lit -v` on every test listed in `tests/regression/baseline_lit.txt` (the full pre-existing `test/CodeGen/RISCV/` and `test/MC/RISCV/` set).
- Score = `15 × passing / total`, rounded down.

### 1b. New MC tests (10 pts)
For each `.s` file under `tests/mc/valid/` (10 files):
- Run `llvm-mc -triple=riscv64 -mattr=+xbestisa -show-encoding <file>.s`.
- Output must match `<file>.expected` **byte-for-byte**, including encoding hex in the comments.

For each `.s` file under `tests/mc/invalid/` (10 files):
- `llvm-mc -triple=riscv64 -mattr=+xbestisa <file>.s` must exit non-zero.
- Stderr must contain the substring listed in `<file>.expected_err`.

Disassembler round-trip check: for each valid encoded blob, `llvm-objdump -d` produces assembly that, when re-assembled, yields identical bytes.

Score = `10 × passing / 20`.

### 1c. New CodeGen `.ll` tests (5 pts)
For each `.ll` file under `tests/codegen/llcheck/` (10 files):
- Run `llc -mtriple=riscv64 -mattr=+xbestisa -O2 <file>.ll | FileCheck <file>.ll`.
- Must pass.
- Score = `5 × passing / 10`.

---

## Tier 2 — Differential execution on Spike (35 pts)

The load-bearing tier. Spike with the pre-installed `XBestISA` semantics is the oracle.

For each of the 30 programs in `tests/correctness/`:
1. Compile twice:
   - **Agent build**: `clang --target=riscv64-unknown-elf -march=rv64gc_xbestisa -O2 prog.c -o prog.xbestisa.elf`
   - **Reference build**: `clang --target=riscv64-unknown-elf -march=rv64gc -O2 prog.c -o prog.baseline.elf` (using the unmodified upstream LLVM 18.1.3 toolchain at `reference-toolchain/`)
2. Run both under appropriate Spike:
   - `spike --isa=rv64gc_xbestisa pk prog.xbestisa.elf > out.xbestisa.txt`
   - `spike --isa=rv64gc pk prog.baseline.elf > out.baseline.txt`
3. **Compare**: `diff -q out.xbestisa.txt out.baseline.txt` must report no differences.
4. Each program: 1 pt if byte-exact match, 0 otherwise.
5. **Bonus**: +5 pts if all 30 pass.

**Score = `min(35, programs_passing + 5*(programs_passing == 30))`.**

(Note: programs use the builtins where appropriate, so even if ISel is buggy, at least the intrinsic path can pass Tier 2. Tier 3a is what enforces ISel from natural C.)

---

## Tier 3a — Instruction selection from natural C (15 pts)

For each of the 10 `.c` snippets in `tests/codegen/`:
1. Compile: `clang -O2 -S --target=riscv64-unknown-elf -march=rv64gc_xbestisa snippet.c -o snippet.s`.
2. Read `<snippet>.expected_count` (one line: `<mnemonic> <min_count>`).
3. `grep -c '<mnemonic>' snippet.s` must be `≥ <min_count>`.
4. Each snippet: **1.5 pts** if mnemonic count meets threshold, 0 otherwise.

Score = `1.5 × snippets_passing`, max 15.

---

## Tier 3b — No opcode-set regression (5 pts)

- 50 baseline `.c` files in `tests/regression/baseline_codegen/`.
- Compile each twice: once with the agent's clang, once with `reference-toolchain/clang` (unmodified `llvmorg-18.1.3`).
- Both compilations use `-O2 --target=riscv64-unknown-elf -march=rv64gc` (NO `xbestisa` — pure baseline check).
- For each file, `llvm-objdump -d` opcode-mnemonic histograms must be **identical**.
- Score = `5 × matching / 50`.

---

## Tier 4 — End-to-end `llvm-test-suite` subset (10 pts)

- Configure `llvm-test-suite` with:
  ```
  -DCMAKE_C_COMPILER=<agent's clang>
  -DCMAKE_CXX_COMPILER=<agent's clang++>
  -DCMAKE_C_FLAGS='-O2 -march=rv64gc_xbestisa'
  ```
  for `SingleSource/Benchmarks/{Misc,Stanford,Shootout}` only.
- All binaries must compile (no errors).
- Each binary executed under `spike --isa=rv64gc_xbestisa`; stdout must be **byte-exact** equal to the same suite compiled with `-march=rv64gc` (baseline) and run on `spike --isa=rv64gc`.
- Threshold: ≥ 95 % of binaries match → full 10 pts. Otherwise pro-rated: `10 × (matching / total)`.

(SingleSource subset = ~70 small benchmarks. Total run time on Spike ≈ 20–30 minutes.)

---

## Scorecard JSON schema

`grader/grade.sh` writes to `scorecard.json`:

```json
{
  "schema_version": "1.0",
  "task": "llvm_riscv_custom_ext_instance_1",
  "timestamp_utc": "2026-04-29T12:34:56Z",
  "oracle_sha256_ok": true,
  "tier0_build": {"score": 5, "max": 5, "details": {...}},
  "tier1_lit":   {"score": 30, "max": 30, "details": {...}},
  "tier2_spike": {"score": 35, "max": 35, "details": {"programs_passing": 30, "bonus": 5}},
  "tier3a_isel": {"score": 15, "max": 15, "details": {"snippets_passing": 10}},
  "tier3b_noregress": {"score": 5, "max": 5, "details": {"matching": 50}},
  "tier4_e2e":   {"score": 10, "max": 10, "details": {"matching": 70, "total": 70}},
  "total":       100,
  "pass":        true,
  "strong_pass": true
}
```

---

## Failure modes the rubric explicitly catches

- **Encoding off-by-one** → Tier 1b hex check.
- **Selected wrong instruction silently** → Tier 3a `grep` + Tier 2 bit-exact diff.
- **Scheduling hazard (RAW under-specified)** → Tier 4 (subtle: only emerges on real workloads).
- **Type-legalization gap on i8/i16/i64 width** → Tier 1c `.ll` tests.
- **ABI/calling-convention break** → Tier 2 + Tier 4 stdout mismatch.
- **`xbestisa` accidentally enabled with `-march=rv64gc`** → Tier 3b opcode-histogram diff.
- **Oracle tampering** → SHA-256 check at start of `grade.sh`.

---

## Reproducibility guarantee

Given the same agent submission (same `git diff` against `llvmorg-18.1.3`) and the same starting Docker image, two independent `grade.sh` runs produce **bit-identical** `scorecard.json` files (modulo the `timestamp_utc` field).
