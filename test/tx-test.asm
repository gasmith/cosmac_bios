#include inc/header.asm

  mov   R_RA, main
  br   init_stack
main:
  ; Source address
  ldi   2
  phi   r8
  ldi   0
  plo   r8

  ; Delay constant
  ldi   13
  phi   r9

  ; Number of bytes to send.
  ldi   4
  plo   r9

  call  tx8

#include inc/stack.asm
#include inc/tx.asm
