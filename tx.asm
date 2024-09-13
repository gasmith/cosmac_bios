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

; tx:
;
; Big-banged 8n1 transmit. Writes r9.0 bytes from the buffer at r8 to Q. The
; baud rate is specifed with a delay constant specified in r9.1:
;
;   baud  r9.1
;   ----  ----
;   9600    13
;   4800    26
;   2400    52
;   1200   105
;
; The delay constant can be derived for arbitrary baud rates as 1e6/(8 * rate).
;
; This subroutine modifies both r8 and r9.
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

  ; Adjust the delay constant for 12 instructions in the PLL.
  ghi   r9
  smi   6
  phi   r9

tx_loop:
  ; Load the next byte into ra.0.
  ldxa
  plo   ra

  ; Setup ra.1 as a bit counter. There are 8 bits, but we intend to using df=1
  ; to detect completion.
  ldi   7
  phi   ra

  ; Start bit. Since we're only using six instructions here (between req and the
  ; next req/seq), bump the delay constant by 3.
  req
  ghi   r9        ; 1
  adi   3         ; 2

  ; Hold bit.
tx_delay:
  smi   1
  bnz   tx_delay

  ; Load the saved byte from ra.0, and shift the least significant bit into DF.
  glo   ra        ; 3
  shrc            ; 4
  plo   ra        ; 5

  ; Either set or reset Q, based on DF.
  bnf   tx_zero   ; 6
  seq             ; 7
  br    tx_bit    ; 8
tx_zero:
  req             ; 7
  req             ; 8 (padding for br tx_bit above)

  ; Decrement the ra.1 bit counter, and reload the delay constant from r9.1 for
  ; the next iteration of the loop. When the bit counter wraps (and df=1), we're
  ; done.
tx_bit:
  ghi   ra        ; 9
  smi   1         ; 10
  phi   ra        ; 11
  ghi   r9        ; 12
  sex   r8        ; 1  (padding for 12-instr PLL)
  bnf   tx_delay  ; 2

  ; Stop bit. Since we're only using two instructions, bump the delay constant
  ; by 5.
  seq
  ghi   r9        ; 1
  adi   5         ; 2
tx_stop:
  smi   1
  bnz   tx_stop
  
  ; If there's more to do, send the next byte.
  dec   r9
  glo   r9
  bnz   tx_loop
  br    done

done:
  idl
