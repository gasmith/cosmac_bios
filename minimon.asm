; A miniature monitor.
;
; Receives commands over the bit-banged serial interface:
;
;   01: Peek
;     - Receive address
;     - Receive length (N<256)
;     - Read N bytes from address
;     - Transmit N bytes
;   02: Poke
;     - Receive address
;     - Receive length (N<256)
;     - Receive N bytes
;     - Write N bytes to address
;   03: Exec
;     - Receive address
;     - Call address

#include inc/header.asm

#define DELAY_2400   52

  mov   R_RA, main
  lbr   init_stack

buf: ds 3

main:
  call  minimon
  br    main

minimon:
  ; Receive the command byte and the address.
  mov   r8, buf
  ldi   1
  plo   r9
  ldi   DELAY_2400
  phi   r9
  call  rx8

  ; Identify the command.
  mov   r8, buf
  ldn   r8
  sex   r8
  out   4
  smi   1
  bz    minimon_peek
  smi   1
  bz    minimon_poke
  smi   1
  bz    minimon_exec
  retf

minimon_peek:
  ; Get address and length
  mov   r8, buf
  ldi   3
  plo   r9
  ldi   DELAY_2400
  phi   r9
  call  rx8

  ; Transmit.
  mov   ra, buf
  lda   ra
  phi   r8
  lda   ra
  plo   r8
  ldn   ra
  plo   r9
  ldi   DELAY_2400
  phi   r9
  call  tx8
  retf

minimon_poke:
  ; Get address and length
  mov   r8, buf
  ldi   3
  plo   r9
  ldi   DELAY_2400
  phi   r9
  call  rx8
  
  ; Receive.
  mov   ra, buf
  lda   ra
  phi   r8
  lda   ra
  plo   r8
  ldn   ra
  plo   r9
  ldi   DELAY_2400
  phi   r9
  call  rx8
  retf

minimon_exec:
  ; Get address.
  mov   r8, minimon_exec_addr
  ldi   2
  plo   r9
  ldi   DELAY_2400
  phi   r9
  call  rx8

  ; Make the call.
  sep   R_CALL
minimon_exec_addr:
  dw    0
  retf

  org   00100h
#include inc/rx.asm
#include inc/tx.asm
#include inc/stack.asm
