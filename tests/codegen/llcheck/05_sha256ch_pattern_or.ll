; RUN: llc -mtriple=riscv64-unknown-elf -mattr=+m,+a,+c,+xbestisa -O2 < %s | FileCheck %s
;
; Pattern test for bestisa.sha256ch

; LLVM canonicalizes xor to or for disjoint operands; this is the
; or-form that the agent's ISel must also catch.
define i64 @ch_or(i64 %e, i64 %f, i64 %g) {
  %ne = xor i64 %e, -1
  %t1 = and i64 %e, %f
  %t2 = and i64 %ne, %g
  %r  = or i64 %t1, %t2
  ret i64 %r
}

; CHECK-LABEL: ch_or:
; CHECK:       bestisa.sha256ch
