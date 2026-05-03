; RUN: llc -mtriple=riscv64-unknown-elf -mattr=+m,+a,+c,+xbestisa -O2 < %s | FileCheck %s
;
; Pattern test for bestisa.sha256maj

define i64 @maj(i64 %a, i64 %b, i64 %c) {
  %xab = xor i64 %a, %b
  %t1  = and i64 %a, %b
  %t2  = and i64 %c, %xab
  %r   = or i64 %t1, %t2
  ret i64 %r
}

; CHECK-LABEL: maj:
; CHECK:       bestisa.sha256maj
