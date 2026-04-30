# TODO — 9 more `.ll` FileCheck probes

`01_andn3_intrinsic.ll` is the canonical template. Add 9 more `.ll` files following the same pattern, one per (instruction × interesting case) combination:

- `02_xor3_intrinsic.ll`
- `03_maddw_intrinsic.ll`
- `04_sha256ch_intrinsic.ll`
- `05_clmulacc_intrinsic.ll`
- `06_bfly_intrinsic.ll`
- `07_andn3_pattern_match.ll` — IR that matches the `Pat<>` records (no intrinsic)
- `08_xor3_pattern_match.ll`
- `09_maddw_sext_pattern.ll` — exercises the sext_inreg legalization gap
- `10_features_negative.ll` — same IR as 07 but with `-mattr=-xbestisa`; should NOT emit the new instruction (negative test for feature gating)

Each must contain `; RUN:` lines and `; CHECK:` lines following standard LLVM lit conventions. See upstream `llvm/test/CodeGen/RISCV/rv64xtheadbb.ll` for a real-world example of style.
