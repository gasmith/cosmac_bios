#include inc/header.asm

; rx16 only supports 2400 baud
#define DELAY_CONSTANT 52

  mov   R_RA, main
  br    init_stack
main:
  ; Make room to receive the header on the stack.
  dec   R_SP
  mov   r8, R_SP
  dec   R_SP

  ; Number of bytes to receive.
  ldi   2
  plo   r9

  ; Delay constant
  ldi   DELAY_CONSTANT
  phi   r9

  call  rx8

  ; Now receive N bytes into 0x200. Keep N on the stack.
  pop   ra
  dec   R_SP
  dec   R_SP
  mov   r8, 0200h
  ldi   DELAY_CONSTANT
  phi   r9
  call  rx16

  pop   ra
  mov   r8, 0200h
  sex   r8
rxlong_out:
  out   4
  dec   ra
  ghi   ra
  bnz   rxlong_out
  glo   ra
  bnz   rxlong_out
  idl

#include inc/rx.asm
#include inc/stack.asm
