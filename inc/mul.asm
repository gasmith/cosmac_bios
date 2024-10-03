; mul16: 16-bit unsigned multiplication
;
; Arguments:
;   r8    Multiplicand
;   r9    Multiplier
; Returns:
;   r9    Zero
;   ra    Result
;   rb.0  (temp)
;   df=1  Overflow
mul16:
  ; Set ra=0, rb.0=0, df=0
  ldi   0
  plo   ra
  phi   ra
  plo   rb
  adi   0

  ; Check for multiplication by zero
  glo   r8
  bnz   mul16_loop
  ghi   r8
  bnz   mul16_loop
  retf

mul16_loop:
  glo   r9
  bnz   mul16_add
  ghi   r9
  bz    mul16_done

mul16_add:
  dec   r9
  add16 ra, r8
  bnf   mul16_loop
  ldi   1
  plo   rb
  br    mul16_loop

mul16_done:
  ; If rb.0=1, an overflow occurred, so set DF=1.
  glo   rb
  smi   1
  retf
