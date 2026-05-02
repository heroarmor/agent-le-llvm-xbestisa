# `XBestISA` — RISC-V Vendor Extension Specification

**Version:** 1.1 (matches the verified reference implementation at `reference-solution/solution.patch`)
**Status:** Frozen for Agent-LE benchmark
**Base ISA:** RV64IMAC
**Encoding space:** `custom-0` (`0001011`) for both R-type (2-source) and R4-type (3-source)
**`-march` token:** `xbestisa`
**Pipeline:** non-faulting, no exceptions, no CSR side-effects
**Provenance:** Derived from the user's pre-existing `Best_ISA` accelerator project (see `reference-solution/walkthrough.md` §1).

---

## 1. Overview

`XBestISA` is a small fixed-function vendor extension consisting of **7 instructions** that fuse common 3-source bit-manipulation, 3-source addition, multiply-accumulate, crypto compression primitives (SHA-256 `Ch` / `Maj`), and a register+register memory load into single ops. All instructions write a single GPR result.

| # | Mnemonic | Format | Funct | Semantics (one-line) |
|---|---|---|---|---|
| 1 | `bestisa.add3 rd, rs1, rs2, rs3`         | R4 | f3=`000` f2=`10`     | `rd = sext_xlen(rs1 + rs2 + rs3)` |
| 2 | `bestisa.xor3 rd, rs1, rs2, rs3`         | R4 | f3=`010` f2=`00`     | `rd = rs1 ^ rs2 ^ rs3` |
| 3 | `bestisa.or3  rd, rs1, rs2, rs3`         | R4 | f3=`011` f2=`00`     | `rd = rs1 \| rs2 \| rs3` |
| 4 | `bestisa.sha256ch rd, rs1, rs2, rs3`     | R4 | f3=`000` f2=`00`     | `rd = (rs1 & rs2) ^ (~rs1 & rs3)` |
| 5 | `bestisa.sha256maj rd, rs1, rs2, rs3`    | R4 | f3=`000` f2=`01`     | `rd = (rs1 & rs2) ^ (rs1 & rs3) ^ (rs2 & rs3)` |
| 6 | `bestisa.mac rd, rs1, rs2, rs3`          | R4 | f3=`001` f2=`00`     | `rd = sext_xlen(rs1 * rs2 + rs3)` |
| 7 | `bestisa.lw  rd, rs1, rs2`               | R  | f3=`010` f7=`0000000`| `rd = MMU.load_int32(rs1 + rs2)` (sign-extended) |

---

## 2. Encoding

Both formats live in the `custom-0` opcode space (`0001011`). The decoder distinguishes R-type from R4-type by `funct3`: `010` with `funct7=0000000` is the R-type `bestisa.lw`; all other observed `funct3` values are R4-type. (This means a hypothetical R4 instruction with `rs3=0` and `funct2=00` and `funct3=010` would be ambiguous with `bestisa.lw`; the implementation orders the decoder's MATCH/MASK table such that `bestisa.lw`'s R-type pattern wins for that specific encoding.)

### 2.1 R-type (instruction 7)

```
 31      25 24    20 19    15 14   12 11     7 6      0
+----------+--------+--------+-------+--------+--------+
|  funct7  |  rs2   |  rs1   | funct3|   rd   | opcode |
+----------+--------+--------+-------+--------+--------+
   7         5         5        3       5         7
```

### 2.2 R4-type (instructions 1–6)

```
 31    27 26 25 24    20 19    15 14   12 11     7 6      0
+--------+-----+--------+--------+-------+--------+--------+
|  rs3   | f2  |  rs2   |  rs1   | funct3|   rd   | opcode |
+--------+-----+--------+--------+-------+--------+--------+
   5       2     5         5        3       5         7
```

### 2.3 Per-instruction MATCH / MASK (used by Spike's decoder)

| Mnemonic        | bits[31:25] (encoding pattern; `r` = register field) | MATCH      | MASK       |
|-----------------|------------------------------------------------------|------------|------------|
| `bestisa.lw`        | `0000000` r r `010` r `0001011`                  | `0x0000200b` | `0xfe00707f` |
| `bestisa.sha256ch`  | rs3 `00` r r `000` r `0001011`                   | `0x0000000b` | `0x0600707f` |
| `bestisa.mac`       | rs3 `00` r r `001` r `0001011`                   | `0x0000100b` | `0x0600707f` |
| `bestisa.xor3`      | rs3 `00` r r `010` r `0001011`                   | `0x0000200b` | `0x0600707f` |
| `bestisa.or3`       | rs3 `00` r r `011` r `0001011`                   | `0x0000300b` | `0x0600707f` |
| `bestisa.sha256maj` | rs3 `01` r r `000` r `0001011`                   | `0x0200000b` | `0x0600707f` |
| `bestisa.add3`      | rs3 `10` r r `000` r `0001011`                   | `0x0400000b` | `0x0600707f` |

### 2.4 Worked encoding examples (verified by `llvm-mc -show-encoding`)

| Asm                                              | Hex (little-endian) |
|--------------------------------------------------|---------------------|
| `bestisa.add3 a0, a1, a2, a3`                    | `0x0b 0x85 0xc5 0x6c` |
| `bestisa.xor3 t0, t1, t2, t3`                    | `0x8b 0x22 0x73 0xe0` |
| `bestisa.or3  s0, s1, s2, s3`                    | `0x0b 0xb4 0x24 0x99` |
| `bestisa.sha256ch a0, a1, a2, a3`                | `0x0b 0x85 0xc5 0x68` |
| `bestisa.sha256maj a0, a1, a2, a3`               | `0x0b 0x85 0xc5 0x6a` |
| `bestisa.mac a0, a1, a2, a3`                     | `0x0b 0x95 0xc5 0x68` |
| `bestisa.lw  a0, a1, a2`                         | `0x0b 0xa5 0xc5 0x00` |

These hex values are reproducible: see `tests/mc/valid/` and run `llvm-mc -triple=riscv64 -mattr=+xbestisa -show-encoding`.

---

## 3. Semantics (executable pseudocode)

`XLEN = 64`. All operations write `rd ≠ x0`; writes to `x0` are silently discarded (RISC-V convention). All operations are non-faulting (no traps).

### 3.1 `bestisa.add3 rd, rs1, rs2, rs3`
```
X[rd] = sext_xlen(X[rs1] + X[rs2] + X[rs3])
```

### 3.2 `bestisa.xor3 rd, rs1, rs2, rs3`
```
X[rd] = X[rs1] ^ X[rs2] ^ X[rs3]
```

### 3.3 `bestisa.or3 rd, rs1, rs2, rs3`
```
X[rd] = X[rs1] | X[rs2] | X[rs3]
```

### 3.4 `bestisa.sha256ch rd, rs1, rs2, rs3`
```
X[rd] = (X[rs1] & X[rs2]) ^ (~X[rs1] & X[rs3])     # SHA-256 Ch on full 64-bit operands
```

### 3.5 `bestisa.sha256maj rd, rs1, rs2, rs3`
```
X[rd] = (X[rs1] & X[rs2]) ^ (X[rs1] & X[rs3]) ^ (X[rs2] & X[rs3])    # SHA-256 Maj
```

### 3.6 `bestisa.mac rd, rs1, rs2, rs3`
```
X[rd] = sext_xlen((sreg_t)X[rs1] * (sreg_t)X[rs2] + (sreg_t)X[rs3])
```
(Signed 64-bit fused multiply-add; result truncated and sign-extended back to XLEN.)

### 3.7 `bestisa.lw rd, rs1, rs2`
```
X[rd] = sext32_to_64(MMU.load_int32(X[rs1] + X[rs2]))
```
Standard 32-bit signed load with register+register addressing; sign-extends to XLEN.

---

## 4. Subtarget feature

| Property                    | Value                        |
|-----------------------------|------------------------------|
| Internal feature name       | `FeatureVendorBestISA`       |
| `-mattr=` / `-march=` token | `xbestisa`                   |
| Predicate                   | `HasVendorBestISA`           |
| AssemblerPredicate          | `AssemblerPredicate<(all_of FeatureVendorBestISA), "'XBestISA' (Best_ISA Custom Compound Instructions)">` |
| Implies                     | none                         |
| ELF attribute               | `Tag_RISCV_arch` substring `_xbestisa1p0` |

---

## 5. ISel pattern guidance (proven to fire in the reference solution)

The reference solution's `Pat<>` records select these instructions from idiomatic IR:

| Instruction       | IR pattern (canonical after combiner) | Verified |
|-------------------|---------------------------------------|----------|
| `add3`            | `(add (add a, b), c)` and commutations | ✓ |
| `xor3`            | `(xor (xor a, b), c)` and commutations | ✓ |
| `or3`             | `(or (or a, b), c)` and commutations   | ✓ |
| `sha256ch`        | 8 commutative variants of `(x & y) ^ (~x & z)` (covers `xor`, `or` after disjoint-or fold, and the alternate `z ^ (x & (y ^ z))` form) | ✓ |
| `sha256maj`       | 4 variants of `(x & y) | (z & (x ^ y))` (canonical for SHA-256 Maj) | ✓ |
| `lw`              | `(i32 (load (add rs1, rs2)))` | ✓ |
| `mac`             | not pattern-matched (DISABLED in the reference; would need multiplier pipeline scheduling) — only reachable via assembler / future intrinsic | n/a |

The `sha256ch` and `sha256maj` patterns require **multiple commuted variants** because LLVM's Combine pass canonicalizes the IR in ways that depend on operand value-tracking. The reference solution ships 8+4 variants (see `reference-solution/walkthrough.md` §3 for why each is needed).

---

## 6. Out of scope

- 32-bit (RV32) variants — RV64-only.
- Compressed encodings (`C` extension prefix) — none.
- Vector (`V` / RVV) interaction — none.
- FP / privileged / CSR effects — none.
- Memory ordering — `bestisa.lw` is a plain load with the same memory model semantics as `lw`.

---

## 7. Versioning history

- **v1.0** (initial draft, sealed in agent-le-llvm-xbestisa@8260233): 6 instructions — `andn3`, `xor3`, `maddw`, `clmulacc`, `bfly`, `sha256ch`. Spec-only; no working implementation.
- **v1.1** (this version, sealed in `reference-solution/solution.patch`): 7 instructions — `add3`, `xor3`, `or3`, `sha256ch`, `sha256maj`, `mac`, `lw_rr`. Verified working: solution.patch + spike-patch produce byte-exact identical stdout to baseline on the e2e test (see `reference-solution/E2E_LOG.txt`).

The v1.1 instruction set was chosen to match a real, working accelerator the user has in development. The selection is representative of the kind of instructions silicon vendors actually upstream (compare to T-Head `XTHeadMac` / `XTHeadBb` and OpenHW `XCVbitmanip`).
