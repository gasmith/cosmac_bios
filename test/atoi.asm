
#include inc/header.asm

  mov   R_RA, main
  lbr   init_stack
main:
  mov   rf, 0
  mov   r8, a
  call  test
  mov   r8, b
  call  test
  mov   r8, c
  call  test
  mov   r8, d
  call  test
  mov   r8, e
  call  test
  mov   r8, f
  call  test
  mov   r8, g
  call  test
  mov   r8, h
  call  test

  ; Output rf.
  glo   rf
  str   R_SP
  out   4
  dec   R_SP
  idl

test:
  call  atoi

  ; Shift DF into rf.
  glo   rf
  shlc
  plo   rf

  ; Output the parsed integer, high byte first
  glo   r9
  stxd
  ghi   r9
  str   R_SP
  out   4
  out   4
  dec   R_SP

  retf

a:
  db  "0",0
b:
  db  "9",0
c:
  db  "000023foo"
d:
  db  "-456",0
e:
  db  "32767",0
f:
  db  "-32768",0
g:
  db  "65535",0
h:
  db  "foo"

  org  0100h
#include inc/int.asm
#include inc/stack.asm
