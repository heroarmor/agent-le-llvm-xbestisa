; RUN: llc -mtriple=riscv64-unknown-elf -mattr=+m,+a,+c,+xbestisa -O2 < %s | FileCheck %s
;
; Pattern test for bestisa.xor3

; 6-way XOR; combiner should reduce to 2 bestisa.xor3 instances.
define i64 @xor6(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
  %t1 = xor i64 %a, %b
  %t2 = xor i64 %t1, %c
  %t3 = xor i64 %t2, %d
  %t4 = xor i64 %t3, %e
  %r  = xor i64 %t4, %f
  ret i64 %r
}

; CHECK-LABEL: xor6:
; CHECK:       bestisa.xor3
