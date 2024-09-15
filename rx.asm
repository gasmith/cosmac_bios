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

; rx: Bit-banged 8n1 receive.
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
rx:
  ; Return immediately if there's nothing to do.
  glo   r9
  bz    done

  ; Adjust the delay constant for 8 instructions in the PLL.
  ghi   r9
  smi   4
  phi   r9

rx_loop:
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
rx_start:
  bn3   rx_start

  ; Load delay constant. Skip this step on the first iteration, where we only
  ; want to wait for half of the usual delay (see above).
  skp
rx_next_bit:
  ghi   r9          ; 1

  ; Delay loop. Sets df=1 (indicating "no borrow").
rx_delay:
  smi   1
  bnz   rx_delay

  ; Test EF3. If it's high, leave df=1. Otherwise, add to set df=0. Use
  ; `skp`, to keep the loop timing the same on either side of the branch.
  b3   rx_zero      ; 2
  skp               ; 3
rx_zero:
  add               ; 3

  ; Load the in-progress byte from memory, shift right with DF, and write it
  ; back to memory. If DF is zero after the shift, that's the start bit, which
  ; means the byte is complete.
  ldn   r8          ; 4
  shrc              ; 5
  str   r8          ; 6
  sex   r8          ; 7 (no-op)
  bdf   rx_next_bit ; 8

  ; Increment X, decrement byte count.
  irx
  dec   r9
  glo   r9
  bz    done

  ; If there are more bytes to receive, wait for EF3 to go high, signalling the
  ; stop bit. Then receive the next byte.
rx_stop:
  bn3   rx_stop 
  br    rx_loop

done:
  ldi   0
  plo   r8
  sex   r8
  out   4
  out   4
  out   4
  out   4
  idl
