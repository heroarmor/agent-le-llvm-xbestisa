; RUN: llc -mtriple=riscv64 -mattr=+xbestisa -O2 < %s | FileCheck %s
;
; Intrinsic-driven .ll: forces the agent's pattern definitions / lowering for
; the bestisa.andn3 intrinsic to be exercised independently of any C-level ISel.

declare i64 @llvm.riscv.bestisa.andn3.i64(i64, i64, i64)

define i64 @andn3_via_intrinsic(i64 %a, i64 %b, i64 %c) {
  ; CHECK-LABEL: andn3_via_intrinsic:
  ; CHECK:       bestisa.andn3 a0, a0, a1, a2
  ; CHECK:       ret
  %r = call i64 @llvm.riscv.bestisa.andn3.i64(i64 %a, i64 %b, i64 %c)
  ret i64 %r
}
