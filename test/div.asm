#include inc/header.asm

  mov   R_RA, main
  lbr   init_stack
main:
  ; 20 / 5 = 4 r 0
  mov   r8, 20
  mov   r9, 5
  mov   rb, 4
  mov   rc, 0
  mov   rf, 0
  call  test

  ; 20 / 6 = 3 r 2
  mov   r8, 20
  mov   r9, 6
  mov   rb, 3
  mov   rc, 2
  mov   rf, 0100h
  call  test

  ; 65244 / 4660 = 14 r 4
  mov   r8, 0fedch
  mov   r9, 01234h
  mov   rb, 14
  mov   rc, 4
  mov   rf, 0200h
  call  test

  ; 65535 / 1 = 65535
  mov   r8, 0ffffh
  mov   r9, 1
  mov   rb, 0ffffh
  mov   rc, 0
  mov   rf, 0300h
  call  test

  ; 100 / 0 = 65535 (divide by zero is invalid)
  mov   r8, 100
  mov   r9, 0
  mov   rb, 0ffffh
  mov   rc, 100
  mov   rf, 0400h
  call  test

  idl


; Arguments:
;   r8    Dividend
;   r9    Divisor
;   rb    Expected quotient
;   rc    Expected remainder
;   rf.1  Testcase number
test:
  call  div16
  call  assert_eq ; check quotient
  inc   rf
  mov   ra, r8
  mov   rb, rc
  call  assert_eq ; check remainder
  retf

; Asserts that the top two values on the stack are equal. If they are not,
; outputs the testcase number, followed by the second value on the stack.
assert_eq:
  sub16 rb, ra
  ghi   rb
  bnz   assert_fail
  glo   rb
  bnz   assert_fail
  retf

  ; Output four bytes: testcase number, assert number, unexpected value.
assert_fail:
  push  ra
  push  rf
  irx
  out   4
  out   4
  out   4
  out   4
  dec   R_SP
  retf

  org  0100h
#include inc/div.asm
#include inc/stack.asm
