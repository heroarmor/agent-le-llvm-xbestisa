; RUN: llc -mtriple=riscv64-unknown-elf -mattr=+m,+a,+c,+xbestisa -O2 < %s | FileCheck %s
;
; Pattern test for bestisa.add3

define i64 @add3_chain(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e) {
  %s1 = add i64 %a, %b
  %s2 = add i64 %s1, %c
  %s3 = add i64 %s2, %d
  %r  = add i64 %s3, %e
  ret i64 %r
}

; CHECK-LABEL: add3_chain:
; CHECK:       bestisa.add3
