  ; Source address
  ldi   2
  phi   r8
  ldi   0
  plo   r8

  ; Delay constant
  ldi   13
  phi   r9

  ; Number of bytes to send.
  ldi   4
  plo   r9

; tx: Big-banged 8n1 transmit.
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
tx:
  ; Return immediately if there's nothing to do.
  glo   r9
  bz    done

  ; Point X to the buffer.
  sex   r8

  ; If Q is not already high, bring it high and wait.
  bq    tx_loop
  seq
  ghi   r9
tx_setup_q:
  smi   1
  bnz   tx_setup_q

  ; Adjust the delay constant for 10 instructions in the PLL.
  ghi   r9
  smi   5
  phi   r9

tx_loop:
  ; Load the next byte into ra.1.
  ldxa              ; 5
  phi   ra          ; 6

  ; Setup ra.0 to count bits.
  ldi   8           ; 7
  plo   ra          ; 8

  ; Start bit.
  ghi   r9          ; 9
  sex   r8          ; 10 (padding)
  req               ; 1
  br    tx_delay    ; 2

  ; Decrement ra.0. Load the saved byte from ra.1, and shift the least
  ; significant bit into DF. Load the delay constant from r9.1.
tx_next_bit:
  dec   ra          ; 5
  ghi   ra          ; 6
  shr               ; 7
  phi   ra          ; 8
  ghi   r9          ; 9

  ; Either set or reset Q, based on DF.
  bnf   tx_zero     ; 10
  seq               ; 1
  br    tx_delay    ; 2
tx_zero:
  req               ; 1
  sex   r8          ; 2 (padding)

  ; Hold bit.
tx_delay:
  smi   1
  bnz   tx_delay

  glo   ra          ; 3
  bnz   tx_next_bit ; 4

  ; Load delay constant
  ghi   r9          ; 5
  sex   r8          ; 6 (padding)
  sex   r8          ; 7 (padding)
  sex   r8          ; 8 (padding)
  sex   r8          ; 9 (padding)
  sex   r8          ; 10 (padding)

  ; Stop bit. Since we're only using two instructions, bump the delay constant
  ; by 5.
  seq               ; 1
tx_stop:
  smi   1
  bnz   tx_stop
  
  ; If there's more to do, send the next byte.
  dec   r9          ; 2
  glo   r9          ; 3
  bnz   tx_loop     ; 4
  br    done

done:
  idl
