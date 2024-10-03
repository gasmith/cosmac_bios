#include inc/header.asm

  mov   R_RA, main
  lbr   init_stack
main:
  ; 20 * 5 = 100
  mov   r8, 20
  mov   r9, 5
  mov   rb, 100
  mov   rc, 0
  mov   rf, 0
  call  test

  ; 30 * 100 = 3000
  mov   r8, 30
  mov   r9, 100
  mov   rb, 3000
  mov   rc, 0
  mov   rf, 0100h
  call  test

  ; 0xffff * 2 = 0xfffe (overflow)
  mov   r8, 0ffffh
  mov   r9, 2
  mov   rb, 0fffeh
  mov   rc, 1
  mov   rf, 0200h
  call  test

  ; 0x1234 * 9 = 0xa3d4
  mov   r8, 01234h
  mov   r9, 9
  mov   rb, 0a3d4h
  mov   rc, 0
  mov   rf, 0300h
  call  test

  ; 100 * 0 = 0
  mov   r8, 100
  mov   r9, 0
  mov   rb, 0
  mov   rc, 0
  mov   rf, 0400h
  call  test

  ; 0 * 100 = 0
  mov   r8, 0
  mov   r9, 100
  mov   rb, 0
  mov   rc, 0
  mov   rf, 0500h
  call  test

  idl


  org 0100h
; Arguments:
;   r8    Multiplicand
;   r9    Multiplier
;   rb    Expected result
;   rc    Expected DF value
;   rf.1  Testcase number
test:
  push  rb
  call  mul16

  ; Save DF in re.
  shlc
  ani   1
  plo   re
  ldi   0
  phi   re

  pop   rb

  call  assert_eq ; check result
  inc   rf
  mov   ra, re
  mov   rb, rc
  call  assert_eq ; check df
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

  org  0200h
#include inc/mul.asm
#include inc/stack.asm
