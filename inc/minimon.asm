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
;   04: Peek registers
;     - Transmit register values for r0-rf.
;
minimon:
  call  minimon_once
  br    minimon

minimon_once:
  ; Create some buffer space on the stack. 3 bytes is sufficient.
  ; Stash the pointer in rf.
  dec   R_SP
  dec   R_SP
  mov   r8, R_SP
  dec   R_SP
  push  r8

  ; Receive the command byte.
  ldi   1
  plo   r9
  ldi   DELAY_2400
  phi   r9
  call  rx8

  ; Restore r8, but keep it on the stack.
  pop   r8
  dec   R_SP
  dec   R_SP

  ; Identify the command.
  ldn   r8
  smi   1
  bz    minimon_peek
  smi   1
  bz    minimon_poke
  smi   1
  bz    minimon_exec
  smi   1
  bz    minimon_peek_reg
  retf

minimon_peek:
  ; Get address and length
  ldi   3
  plo   r9
  ldi   DELAY_2400
  phi   r9
  call  rx8

  ; Restore buffer address from the stack.
  pop   ra

  ; Transmit.
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
  ldi   3
  plo   r9
  ldi   DELAY_2400
  phi   r9
  call  rx8
  
  ; Restore buffer address from the stack.
  pop   ra

  ; Receive.
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
  ; Read callee address from serial.
  ldi   2
  plo   r9
  ldi   DELAY_2400
  phi   r9
  call  rx8

  ; Restore buffer address from stack and boing!
  pop   r8
  mov   r9, minimon_call
  sep   r9
  retf

; Special call trampoline for jumping to a dynamic address.
minimon_call:
  ; Save previous return address to the stack.
  sex   R_SP
  push  R_RA

  ; Copy R_PC to R_RA.
  mov   R_RA, R_PC

  ; Load the target address from r8, instead of R_PC.
  lda   r8
  phi   R_PC
  lda   r8
  plo   R_PC

  ; Jump to new PC.
  sep   R_PC

minimon_peek_reg:
  ; Push registers.
  push  rf
  push  re
  push  rd
  push  rc
  push  rb
  push  ra
  push  r9
  push  r8
  push  r7
  push  r6
  push  r5
  push  r4
  push  r3
  push  r2
  push  r1
  push  r0

  ; Transmit.
  mov   r8, R_SP
  inc   r8
  ldi   32
  plo   r9
  ldi   DELAY_2400
  phi   r9
  call  tx8

  ; Drop the registers (and the saved r8 from minimon_once) from the stack.
  add16 R_SP, 34
  retf
