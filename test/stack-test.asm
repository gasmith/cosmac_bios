#include inc/header.asm

  ; Entrypoint
  mov   R_RA, main
  br    init_stack

; A little test program to output a random byte on lines 1, 2, 3, 4, and 5, in
; that order, and then enter the idle loop.
main:
  sex   r8
  out   1
  call  foo
  sex   r8
  out   5
  idl

foo:
  sex   r8
  out   2
  call  bar
  sex   r8
  out   4
  retf

bar:
  sex   r8
  out   3
  retf

#include inc/stack.asm
