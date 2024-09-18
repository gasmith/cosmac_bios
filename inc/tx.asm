; tx8: Big-banged 8n1 transmit.
;
; Arguments:
;   r8    rw  Buffer address
;   r9.0  rw  Buffer length
;   r9.1  rw  Delay constant
;
; Writes buffer data to Q. The baud rate is specifed with a delay constant,
; which is defined as 1e6/(8 * baud):
;
;   baud  r9.1
;   ----  ----
;   9600    13
;   4800    26
;   2400    52
;   1200   105
;
tx8:
  ; Return immediately if there's nothing to do.
  glo   r9
  bz    tx8_done

  ; Point X to the buffer.
  sex   r8

  ; If Q is not already low, bring it low and wait.
  bnq   tx8_adjust_delay
  req
  ghi   r9
tx8_setup_q:
  smi   1
  bnz   tx8_setup_q

tx8_adjust_delay:
  ; Adjust the delay constant for 10 instructions in the PLL.
  ghi   r9
  smi   5
  phi   r9

tx8_loop:
  ; Load the next byte into ra.1.
  ldxa                ; 5
  phi   ra            ; 6

  ; Setup ra.0 to count bits.
  ldi   8             ; 7
  plo   ra            ; 8

  ; Start bit.
  ghi   r9            ; 9
  sex   r8            ; 10 (padding)
  req                 ; 1
  br    tx8_delay     ; 2

  ; Decrement ra.0. Load the saved byte from ra.1, and shift the least
  ; significant bit into DF. Load the delay constant from r9.1.
tx8_next_bit:
  dec   ra            ; 5
  ghi   ra            ; 6
  shr                 ; 7
  phi   ra            ; 8
  ghi   r9            ; 9

  ; Either set or reset Q, based on DF.
  bnf   tx8_zero      ; 10
  req                 ; 1
  br    tx8_delay     ; 2
tx8_zero:
  seq                 ; 1
  sex   r8            ; 2 (padding)

  ; Hold bit.
tx8_delay:
  smi   1
  bnz   tx8_delay

  glo   ra            ; 3
  bnz   tx8_next_bit  ; 4

  ; Load delay constant
  ghi   r9            ; 5
  sex   r8            ; 6 (padding)
  sex   r8            ; 7 (padding)
  sex   r8            ; 8 (padding)
  sex   r8            ; 9 (padding)
  sex   r8            ; 10 (padding)

  ; Stop bit.
  req                 ; 1
tx8_stop:
  smi   1
  bnz   tx8_stop
  
  ; If there's more to do, send the next byte.
  dec   r9            ; 2
  glo   r9            ; 3
  bnz   tx8_loop      ; 4

tx8_done:
  retf

; tx16: Bit-banged 8n1 transmit for more than 255 bytes.
;
; Arguments:
;   r8    rw  Buffer address
;   r9.1  rw  Delay constant
;   ra    rw  Buffer length
;
; See tx for more details.
;
tx16:
  ; If there's more than 255, send 255.
  ldi   0ffh
  plo   r9
  ghi   ra
  bnz   tx16_adjust_ra

  ; If there's less than 256, send that.
  glo   ra
  plo   r9
  bnz   tx16_adjust_ra
  retf

tx16_adjust_ra:
  ; Store length on the stack.
  sex   R_SP
  str   R_SP
  glo   ra
  sm        ; ra.0 - r9.0
  plo   ra

  ; If df=0, there was a borrow, so also decrement ra.1.
  bdf   tx16_tx 
  ghi   ra
  smi   1
  phi   ra

tx16_tx:
  ; Send this chunk, and loop for the next.
  call  tx8
  br    tx16
