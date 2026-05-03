; RUN: llc -mtriple=riscv64-unknown-elf -mattr=+m,+a,+c,+xbestisa -O2 < %s | FileCheck %s
;
; Pattern test for bestisa.sha256ch

define i64 @ch(i64 %e, i64 %f, i64 %g) {
  %ne = xor i64 %e, -1
  %t1 = and i64 %e, %f
  %t2 = and i64 %ne, %g
  %r  = xor i64 %t1, %t2
  ret i64 %r
}

; CHECK-LABEL: ch:
; CHECK:       bestisa.sha256ch
