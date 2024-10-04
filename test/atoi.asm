
#include inc/header.asm

  mov   R_RA, main
  lbr   init_stack
main:
  ; rc.0 is testcase number
  ldi   0
  plo   rc
  mov   r8, a
  mov   rd, 0
  mov   re, 0
  call  test

  inc   rc
  mov   r8, b
  mov   rd, 0
  mov   re, 9
  call  test

  inc   rc
  mov   r8, c
  mov   rd, 3
  mov   re, 23
  call  test

  inc   rc
  mov   r8, d
  mov   rd, 0
  mov   re, 0fe38h
  call  test

  inc   rc
  mov   r8, e
  mov   rd, 0
  mov   re, 07fffh
  call  test

  inc   rc
  mov   r8, f
  mov   rd, 0
  mov   re, 08000h
  call  test

  inc   rc
  mov   r8, g
  mov   rd, 0
  mov   re, 0ffffh
  call  test

  inc   rc
  mov   r8, h
  mov   rd, 3
  mov   re, 0
  call  test

  inc   rc
  mov   r8, i
  mov   rd, 0
  mov   re, 0
  call  test

  idl

test:
  push  rc
  push  r8
  call  strlen
  pop   r8
  mov   r9, rf
  call  atoi
  pop   rc

  ; Compare unconsumed length.
  glo   rd
  str   R_SP
  glo   r9
  xor
  bnz   output

  ; Compare parsed integer.
  glo   re
  str   R_SP
  glo   ra
  xor
  ghi   re
  str   R_SP
  ghi   ra
  xor
  bnz   output

  retf

output:
  ; Output the test case number.
  glo   rc
  sex   R_SP
  str   R_SP
  out   4
  dec   R_SP

  ; Output the unconsumed length, followed by the parsed integer, high byte
  ; first.
  glo   ra
  stxd
  ghi   ra
  stxd
  glo   r9
  str   R_SP
  out   4
  out   4
  out   4
  dec   R_SP

  retf

a:
  db  "0",0
b:
  db  "9",0
c:
  db  "000023foo",0
d:
  db  "-456",0
e:
  db  "32767",0
f:
  db  "-32768",0
g:
  db  "65535",0
h:
  db  "foo",0
i:
  db  "-",0

  org  0200h
#include inc/div.asm
#include inc/int.asm
  org  0300h
#include inc/str.asm
#include inc/stack.asm
