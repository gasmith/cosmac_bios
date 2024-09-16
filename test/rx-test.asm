#include inc/header.asm

  mov   R_RA, main
  br   init_stack
main:
  ; Destination address
  ldi   2
  phi   r8
  ldi   0
  plo   r8

  ; Number of bytes to receive.
  ldi   4
  plo   r9

  ; Delay constant
  ldi   13
  phi   r9

  call  rx

  ldi   0
  plo   r8
  sex   r8
  out   4
  out   4
  out   4
  out   4
  idl

#include inc/rx.asm
#include inc/stack.asm
