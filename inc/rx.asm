; rx8: Bit-banged 8n1 receive.
;
; Arguments:
;   r8    rw  Buffer address
;   r9.0  rw  Buffer length
;   r9.1  rw  Delay constant
;
; Reads data from EF3 into the buffer. The baud rate is specified with a delay
; constant, which is defined as 1e6/(8 * baud):
;
;   baud  r9.1
;   ----  ----
;   9600    13
;   4800    26
;   2400    52
;   1200   105
;
rx8:
  ; Return immediately if there's nothing to do.
  glo   r9
  bz    rx8_done

  ; Adjust the delay constant for 8 instructions in the PLL.
  ghi   r9
  smi   4
  phi   r9

rx8_loop:
  ; Initialize the target byte as 0xff. We'll shift the start bit (0), and each
  ; data bit, through the byte. When the start bit is shifted off, DF will be 0,
  ; and the byte will be complete.
  ldi   0ffh
  str   r8

  ; On the first iteration, use half of the delay constant, so we sample each
  ; bit in the middle of its hold time.
  ghi   r9
  shr

  ; Wait for EF3 to go low, signalling the edge of the start bit.
rx8_start:
  bn3   rx8_start

  ; Load delay constant. Skip this step on the first iteration, where we only
  ; want to wait for half of the usual delay (see above).
  skp
rx8_next_bit:
  ghi   r9            ; 1

  ; Delay loop. Sets df=1 (indicating "no borrow").
rx8_delay:
  smi   1
  bnz   rx8_delay

  ; Test EF3. If it's high, leave df=1. Otherwise, add to set df=0. Use
  ; `skp`, to keep the loop timing the same on either side of the branch.
  b3   rx8_zero       ; 2
  skp                 ; 3
rx8_zero:
  add                 ; 3

  ; Load the in-progress byte from memory, shift right with DF, and write it
  ; back to memory. If DF is zero after the shift, that's the start bit, which
  ; means the byte is complete.
  ldn   r8            ; 4
  shrc                ; 5
  str   r8            ; 6
  sex   r8            ; 7 (no-op)
  bdf   rx8_next_bit  ; 8

  ; Increment X, decrement byte count.
  irx
  dec   r9
  glo   r9
  bz    rx8_done

  ; If there are more bytes to receive, wait for EF3 to go high, signalling the
  ; stop bit. Then receive the next byte.
rx8_stop:
  b3    rx8_stop 
  br    rx8_loop

rx8_done:
  retf

; rx16: Bit-banged 8n1 receive for more than 255 bytes.
;
; Arguments:
;   r8    rw  Buffer address
;   r9.1  rw  Delay constant
;   ra    rw  Buffer length
;
; See rx for more details.
;
rx16:
  ; If there's more than 255, send 255.
  ldi   0ffh
  plo   r9
  ghi   ra
  bnz   rx16_adjust_ra

  ; If there's less than 256, send that.
  glo   ra
  plo   r9
  bnz   rx16_adjust_ra
  retf

rx16_adjust_ra:
  ; Store length on the stack.
  sex   R_SP
  str   R_SP
  glo   ra
  sm        ; ra.0 - r9.0
  plo   ra

  ; If df=0, there was a borrow, so also decrement ra.1.
  bdf   rx16_rx 
  ghi   ra
  smi   1
  phi   ra

rx16_rx:
  ; Send this chunk, and loop for the next.
  call  rx8
  br    rx16
