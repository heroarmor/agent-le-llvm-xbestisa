; RUN: llc -mtriple=riscv64-unknown-elf -mattr=+m,+a,+c,+xbestisa -O2 < %s | FileCheck %s
;
; Pattern test for bestisa.or3

define i64 @or3_dis(i64 %a, i64 %b, i64 %c) {
  %ab = or i64 %a, %b
  %r  = or i64 %ab, %c
  ret i64 %r
}

; CHECK-LABEL: or3_dis:
; CHECK:       bestisa.or3
