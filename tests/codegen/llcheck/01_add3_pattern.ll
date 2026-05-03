; RUN: llc -mtriple=riscv64-unknown-elf -mattr=+m,+a,+c,+xbestisa -O2 < %s | FileCheck %s
;
; Pattern test for bestisa.add3

define i64 @add3(i64 %a, i64 %b, i64 %c) {
  %ab = add i64 %a, %b
  %r  = add i64 %ab, %c
  ret i64 %r
}

; CHECK-LABEL: add3:
; CHECK:       bestisa.add3
