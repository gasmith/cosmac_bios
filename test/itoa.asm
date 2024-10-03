#include inc/header.asm

  mov   R_RA, main
  lbr   init_stack
main:
  mov   r9, 0
  mov   ra, 0
  mov   re, t0
  mov   rf, 0
  call  test

  mov   r9, 100
  mov   ra, 0
  mov   re, t1
  mov   rf, 1
  call  test

  mov   r9, 0fed4h
  mov   ra, 1
  mov   re, t2
  mov   rf, 2
  call  test

  mov   r9, 0ffffh
  mov   ra, 0
  mov   re, t3
  mov   rf, 3
  call  test

  mov   r9, 07fffh
  mov   ra, 1
  mov   re, t4
  mov   rf, 4
  call  test

  mov   r9, 08000h
  mov   ra, 1
  mov   re, t5
  mov   rf, 5
  call  test

  mov   r9, 0ffffh
  mov   ra, 1
  mov   re, t6
  mov   rf, 6
  call  test

  mov   r9, 0
  mov   ra, 1
  mov   re, t7
  mov   rf, 7
  call  test

  idl

  org 0100h
test:
  mov   r8, buf
  call  itoa

  ; Use rd=0 to signal a successful comparison. (TODO replace this with strcmp).
  ldi   0
  plo   rd

  ; Compare the output buffer (r8) against the expectation (re), until we reach
  ; the null terminator in re.
  mov   r8, buf
  sex   r8
cmp:
  ldn   re
  xor
  bz    cmp_ok
  inc   rd
cmp_ok:
  irx
  ldn   re
  inc   re
  bnz   cmp

  glo   rd
  bnz   output
  retf

output:
  ; Output the test case number.
  glo   rf
  sex   R_SP
  str   R_SP
  out   4
  dec   R_SP

  ; Output the buffer.
  sex   r8
  mov   r8, buf
output_loop:
  ldn   r8
  out   4
  bnz   output_loop
  retf

buf: db 0,0,0,0,0,0,0
t0: db "0",0
t1: db "100",0
t2: db "-300",0
t3: db "65535",0
t4: db "32767",0
t5: db "-32768",0
t6: db "-1", 0
t7: db "0",0

  org  0200h
#include inc/int.asm
#include inc/div.asm

  org  0300h
#include inc/stack.asm
