; A short bootstrap loader that can be toggled in.
;
; This loader presumes that the serial line is running 8n1 at 9600 baud. Slower
; line rates can be accommodated by modifying the delay constant in r9.1.
 
setup:
  ; Destination
  ldi   1
  phi   r8
  ldi   0
  plo   r8

  ; Delay constant for 9600 baud is 13 2-instr cycles. We'll use 10 instructions
  ; for the PLL, so (13 - 10/2) = 8.
  ldi   8
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
  bn3   rx_zero     ; 2
  skp               ; 3
rx_zero:
  sm                ; 3

  ; Load the in-progress byte from memory, shift right with DF, and write it
  ; back to memory. If DF is zero after the shift, that's the start bit, which
  ; means the byte is complete.
  ldn   r8          ; 4
  shrc              ; 5
  str   r8          ; 6
  sex   r8          ; 7 (no-op)
  bdf   rx_next_bit ; 8

  ; Increment r8.
  inc   r8

  ; Wait for EF3 to go high, signalling the stop bit.
rx_stop:
  bn3   rx_stop
  br    rx_loop
