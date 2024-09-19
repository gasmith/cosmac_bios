#include inc/header.asm

  mov   R_RA, main
  br   init_stack
main:
  ; Source address
  ldi   0
  phi   r8
  ldi   data
  plo   r8

  ; Delay constant
  ldi   13
  phi   r9

  ; Number of bytes to send.
  ldi   5
  plo   r9

  call  tx8

data:
  db "hello",0

#include inc/stack.asm
#include inc/tx.asm
