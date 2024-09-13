  ; Destination address
  ldi   2
  phi   r8
  ldi   0
  plo   r8

  ; Number of bytes to receive.
  ldi   4
  plo   r9

  ; Delay constant
  ldi   8
  phi   r9

; rx:
;
; Big-banged 8n1 receive. Reads r9.0 bytes from EF3 into the buffer at r8. The
; baud rate is specifed with a delay constant specified in r9.1:
;
;   baud  r9.1
;   ----  ----
;   9600     8
;   4800    21
;   2400    47
;   1200   100
;
; The delay constant is a multiplier for an 8us delay loop, which accommodates
; an additional 10 4us instructions in each iteration of the phase-locked loop.
rx:
  ; Return immediately if there's nothing to do.
  glo   r9
  bz    done

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
  b3    rx_start

  ; Load delay constant. Skip this step on the first iteration, where we only
  ; want to wait for half of the usual delay (see above).
  skp
rx_next_bit:
  ghi   r9          ; 1

  ; Decrement until we wrap to 0xff with df=1. Since we're performing one extra
  ; iteration of the delay loop, we can only have 8 other instructions in the
  ; phase-locked loop. These are numbered to the side.
rx_delay:
  smi   1
  bnf   rx_delay

  ; Test EF3. If it's high, leave df=1. Otherwise, subtract to set df=0. Use
  ; `skp`, to keep the loop timing the same on either side of the branch.
  bn3   rx_is0      ; 2
  skp               ; 3
rx_is0:
  sm                ; 3

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
