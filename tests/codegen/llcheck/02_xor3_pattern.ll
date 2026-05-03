; RUN: llc -mtriple=riscv64-unknown-elf -mattr=+m,+a,+c,+xbestisa -O2 < %s | FileCheck %s
;
; Pattern test for bestisa.xor3

define i64 @xor3(i64 %a, i64 %b, i64 %c) {
  %ab = xor i64 %a, %b
  %r  = xor i64 %ab, %c
  ret i64 %r
}

; CHECK-LABEL: xor3:
; CHECK:       bestisa.xor3
