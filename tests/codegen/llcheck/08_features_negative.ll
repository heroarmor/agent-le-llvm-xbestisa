; RUN: llc -mtriple=riscv64-unknown-elf -mattr=+m,+a,+c -O2 < %s | FileCheck %s
;
; Negative test: with xbestisa DISABLED, must NOT emit bestisa.xor3.

; Same as 02, but compiled with -mattr=-xbestisa: must NOT emit bestisa.xor3.
define i64 @xor3_neg(i64 %a, i64 %b, i64 %c) {
  %ab = xor i64 %a, %b
  %r  = xor i64 %ab, %c
  ret i64 %r
}

; CHECK-LABEL: xor3_neg:
; CHECK-NOT:   bestisa.
