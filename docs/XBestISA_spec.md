# `XBestISA` — RISC-V Vendor Extension Specification

**Version:** 1.0
**Status:** Frozen for Agent-LE benchmark
**Base ISA:** RV64GC
**Encoding space:** `custom-0` (`0001011`) for R-type, `custom-1` (`0101011`) for R4-type
**`-march` token:** `xbestisa`
**Pipeline:** 3-cycle latency, single issue port `M`, no exceptions

---

## 1. Overview

`XBestISA` is a small fixed-function vendor extension consisting of **6 instructions** that fuse common 3-source bit-manipulation, multiply-accumulate, and crypto primitives into single ops. All instructions are register-only (no immediates), produce a single GPR result, and are non-faulting.

| # | Mnemonic | Format | Funct | Semantics (one-line) |
|---|---|---|---|---|
| 1 | `bestisa.clmulacc rd, rs1, rs2`           | R  | f3=`000` f7=`0000000` | `rd = rd ^ clmul(rs1, rs2)` (rd is also source) |
| 2 | `bestisa.bfly rd, rs1, rs2`               | R  | f3=`000` f7=`0000001` | bit-butterfly permutation of `rs1` controlled by `rs2` |
| 3 | `bestisa.andn3 rd, rs1, rs2, rs3`         | R4 | f3=`000` f2=`00`      | `rd = rs1 & ~rs2 & ~rs3` |
| 4 | `bestisa.xor3 rd, rs1, rs2, rs3`          | R4 | f3=`000` f2=`01`      | `rd = rs1 ^ rs2 ^ rs3` |
| 5 | `bestisa.maddw rd, rs1, rs2, rs3`         | R4 | f3=`000` f2=`10`      | `rd = sext32(rs1[31:0] + rs2[31:0] * rs3[31:0])` |
| 6 | `bestisa.sha256ch rd, rs1, rs2, rs3`      | R4 | f3=`000` f2=`11`      | `rd = (rs1 & rs2) ^ (~rs1 & rs3)` |

---

## 2. Encoding

### 2.1 R-type (instructions 1–2): opcode `custom-0` = `0001011`

```
 31      25 24    20 19    15 14   12 11     7 6      0
+----------+--------+--------+-------+--------+--------+
|  funct7  |  rs2   |  rs1   | funct3|   rd   | opcode |
+----------+--------+--------+-------+--------+--------+
   7         5         5        3       5         7
```

### 2.2 R4-type (instructions 3–6): opcode `custom-1` = `0101011`

```
 31    27 26 25 24    20 19    15 14   12 11     7 6      0
+--------+-----+--------+--------+-------+--------+--------+
|  rs3   | f2  |  rs2   |  rs1   | funct3|   rd   | opcode |
+--------+-----+--------+--------+-------+--------+--------+
   5       2     5         5        3       5         7
```

### 2.3 Per-instruction encoding table

| Mnemonic        | bits[31:25] | bits[24:20] | bits[19:15] | bits[14:12] | bits[11:7] | bits[6:0] |
|-----------------|-------------|-------------|-------------|-------------|------------|-----------|
| `clmulacc`      | `0000000`   | rs2         | rs1         | `000`       | rd         | `0001011` |
| `bfly`          | `0000001`   | rs2         | rs1         | `000`       | rd         | `0001011` |
| `andn3`         | rs3‖`00`    | rs2         | rs1         | `000`       | rd         | `0101011` |
| `xor3`          | rs3‖`01`    | rs2         | rs1         | `000`       | rd         | `0101011` |
| `maddw`         | rs3‖`10`    | rs2         | rs1         | `000`       | rd         | `0101011` |
| `sha256ch`      | rs3‖`11`    | rs2         | rs1         | `000`       | rd         | `0101011` |

(For R4 rows, `bits[31:27]=rs3`, `bits[26:25]=funct2`.)

### 2.4 Worked encoding examples (for MC-test golden hex)

| Asm                                        | Hex (little-endian) | Binary (MSB→LSB) |
|--------------------------------------------|---------------------|------------------|
| `bestisa.clmulacc x10, x11, x12`           | `0x00c5850b`        | `0000000 01100 01011 000 01010 0001011` |
| `bestisa.bfly x5, x6, x7`                  | `0x0273028b`        | `0000001 00111 00110 000 00101 0001011` |
| `bestisa.andn3 x1, x2, x3, x4`             | `0x2031010b` ... see harness | `00100 00 00011 00010 000 00001 0101011` |
| `bestisa.xor3 x1, x2, x3, x4`              | (computed in harness) | `00100 01 00011 00010 000 00001 0101011` |
| `bestisa.maddw x1, x2, x3, x4`             | (computed in harness) | `00100 10 00011 00010 000 00001 0101011` |
| `bestisa.sha256ch x1, x2, x3, x4`          | (computed in harness) | `00100 11 00011 00010 000 00001 0101011` |

> Authoritative encodings for the full register cross-product are computed by `tests/mc/valid/*.expected` files at grade time.

---

## 3. Semantics (executable pseudocode)

Let `XLEN = 64`. All operations write `rd ≠ x0`; writes to `x0` are silently discarded (RISC-V convention).

### 3.1 `bestisa.clmulacc rd, rs1, rs2`
```
clmul(a, b):
    result = 0
    for i in 0..XLEN-1:
        if (b >> i) & 1: result ^= (a << i) & ((1 << XLEN) - 1)
    return result

X[rd] = X[rd] ^ clmul(X[rs1], X[rs2])
```
Note: `rd` is **both source and destination** (accumulator). Latency 3, throughput 1.

### 3.2 `bestisa.bfly rd, rs1, rs2`
```
# Butterfly stage; rs2[5:0] selects stage k (0..5), rs2[63:6] ignored.
k = X[rs2] & 0x3F
if k > 5: X[rd] = X[rs1]; return       # no-op for k>=6
mask = stage_masks[k]                   # see table below
shift = 1 << k
a = X[rs1]
hi = (a >> shift) & mask
lo = a & mask
X[rd] = (hi | (lo << shift)) | (a & ~(mask | (mask << shift)))
```
where:
| k | `stage_masks[k]` (hex)              |
|---|--------------------------------------|
| 0 | `0x5555555555555555`                 |
| 1 | `0x3333333333333333`                 |
| 2 | `0x0F0F0F0F0F0F0F0F`                 |
| 3 | `0x00FF00FF00FF00FF`                 |
| 4 | `0x0000FFFF0000FFFF`                 |
| 5 | `0x00000000FFFFFFFF`                 |

### 3.3 `bestisa.andn3 rd, rs1, rs2, rs3`
```
X[rd] = X[rs1] & ~X[rs2] & ~X[rs3]
```

### 3.4 `bestisa.xor3 rd, rs1, rs2, rs3`
```
X[rd] = X[rs1] ^ X[rs2] ^ X[rs3]
```

### 3.5 `bestisa.maddw rd, rs1, rs2, rs3`
```
lo32(x): return x & 0xFFFFFFFF
sext32_to_64(x): return ((int64_t)((int32_t)(x & 0xFFFFFFFF)))

prod32 = lo32(lo32(X[rs2]) * lo32(X[rs3]))    # truncate to 32b
sum32  = lo32(lo32(X[rs1]) + prod32)
X[rd]  = sext32_to_64(sum32)
```

### 3.6 `bestisa.sha256ch rd, rs1, rs2, rs3`
```
X[rd] = (X[rs1] & X[rs2]) ^ (~X[rs1] & X[rs3])
```
(Standard SHA-256 `Ch` function, applied to full 64-bit operands.)

---

## 4. Pipeline / scheduling

| Property         | Value           |
|------------------|-----------------|
| Latency          | **3 cycles**    |
| Throughput       | 1 per cycle     |
| Issue port       | `M` (single)    |
| Pipeline class   | `IIC_BestISA`   |
| In-order on `MISched` | yes        |
| WAW / RAW hazards | standard       |

LLVM scheduling itinerary entries must be added to:
- `llvm/lib/Target/RISCV/RISCVSchedRocket.td` — class `IIC_BestISA`, mapped to `RocketUnitsItinM`, latency 3.
- `llvm/lib/Target/RISCV/RISCVSchedSiFive7.td` — class `IIC_BestISA`, mapped to `SiFive7M`, latency 3.

---

## 5. Subtarget feature

| Property                  | Value                        |
|---------------------------|------------------------------|
| Internal feature name     | `FeatureVendorXBestISA`      |
| `-mattr=` / `-march=` token | `xbestisa`                 |
| Predicate                 | `HasVendorXBestISA`          |
| AssemblerPredicate        | `AssemblerPredicate<(all_of FeatureVendorXBestISA), "'xbestisa' (XBestISA Vendor Extension)">` |
| Implies                   | none                         |
| ELF attribute             | `Tag_RISCV_arch` substring `_xbestisa1p0` |

---

## 6. Clang builtins

| Builtin                                              | Signature                                              | Maps to intrinsic                  |
|------------------------------------------------------|--------------------------------------------------------|------------------------------------|
| `__builtin_riscv_bestisa_clmulacc(acc, a, b)`        | `(uint64_t, uint64_t, uint64_t) -> uint64_t`           | `llvm.riscv.bestisa.clmulacc`      |
| `__builtin_riscv_bestisa_bfly(a, sel)`               | `(uint64_t, uint64_t) -> uint64_t`                     | `llvm.riscv.bestisa.bfly`          |
| `__builtin_riscv_bestisa_andn3(a, b, c)`             | `(uint64_t, uint64_t, uint64_t) -> uint64_t`           | `llvm.riscv.bestisa.andn3`         |
| `__builtin_riscv_bestisa_xor3(a, b, c)`              | `(uint64_t, uint64_t, uint64_t) -> uint64_t`           | `llvm.riscv.bestisa.xor3`          |
| `__builtin_riscv_bestisa_maddw(a, b, c)`             | `(int32_t, int32_t, int32_t) -> int32_t` (sext to i64) | `llvm.riscv.bestisa.maddw`         |
| `__builtin_riscv_bestisa_sha256ch(e, f, g)`          | `(uint64_t, uint64_t, uint64_t) -> uint64_t`           | `llvm.riscv.bestisa.sha256ch`      |

All builtins are gated by `TargetGuard<"xbestisa">`.

---

## 7. ISel pattern guidance

The agent must select these instructions from idiomatic IR. Suggested matchers (non-exhaustive):

| Instruction   | IR pattern (canonical after combiner) |
|---------------|---------------------------------------|
| `andn3`       | `(and (and a, (xor b, -1)), (xor c, -1))` and commutative equivalents; also via the explicit builtin |
| `xor3`        | `(xor (xor a, b), c)` and all associativity equivalents |
| `maddw`       | `(sext_inreg (add a, (mul b, c)), i32)` over i64; or `(add a32, (mul b32, c32))` returning i32 sext'd |
| `sha256ch`    | `(xor (and e, f), (and (xor e, -1), g))` |
| `clmulacc`    | only via builtin/intrinsic (no canonical scalar IR pattern) |
| `bfly`        | only via builtin/intrinsic |

The 10 codegen snippets in `tests/codegen/` are the load-bearing oracle for ISel quality.

---

## 8. Out of scope

- 32-bit (RV32) variants — RV64-only.
- Compressed encodings (`C` extension) — none.
- Vector (`V` / RVV) interaction — none.
- FP / privileged / CSR effects — none.
- Memory ordering — none (all 6 are register-only).

---

## 9. Versioning

This is `XBestISA` v1.0. Any future extension version (`xbestisa1p1`, etc.) is out of scope for this benchmark task.
