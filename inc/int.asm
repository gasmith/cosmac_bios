; isnum: Checks whether a character is a number.
;
; Arguments:
;   rc.0  Character
;
; Returns:
;   df=1  Numeric
isnum:
  glo rc
  smi '0'
  bnf isnum_nope
  smi 10
  bdf isnum_nope
  smi 0
  lskp
isnum_nope:
  adi 0
  retf

; atoi: Parses a base-10 integer from an ASCII string.
;
; TODO: Base-16
; TODO: Overflow
;
; Arguments:
;   r8    Buffer address
;   r9    Buffer length
;
; Returns:
;   r8    Address of first non-numeric character
;   r9    Unconsumed length
;   ra    Parsed integer
;   rb.0  1 if the integer is negative, else 0.
;   df=1  if first character is non-numeric
atoi:
  ldi   0
  plo   ra
  phi   ra
  plo   rb

  ; Zero-length buffer.
  glo   r9
  bnz   atoi_check_minus
  ghi   r9
  bnz   atoi_check_minus
  smi   0
  retf

atoi_check_minus:
  ; If there's a leading minus sign, set rb.0=1.
  ldn   r8
  xri   '-'
  bnz   atoi_check_numeric
  inc   rb
  inc   r8
  dec   r9
  glo   r9
  bnz   atoi_check_minus
  ghi   r9
  bnz   atoi_check_minus
  smi   0
  retf

  ; Check if first character is numeric.
atoi_check_numeric:
  ldn   r8
  plo   rc
  call  isnum
  bdf   atoi_loop
  smi   0
  retf

atoi_loop:
  ; Load character and advance r8.
  lda   r8

  ; Convert to binary and add to ra.
  smi   '0'
  str   R_SP
  glo   ra
  add
  plo   ra
  ghi   ra
  adci  0
  phi   ra

  ; Check whether we've consumed the whole buffer.
  dec   r9
  glo   r9
  bnz   atoi_check_next
  ghi   r9
  bz    atoi_negate

  ; Check whether the next character is numeric.
atoi_check_next:
  ldn   r8
  plo   rc
  call  isnum
  bnf   atoi_negate

  ; Multiply ra by 10: Save a copy (in little-endian order), shift left twice
  ; (x4), add the saved copy (x5), shift left again (x10).
  ghi   ra
  stxd
  glo   ra
  str   R_SP
  shl16 ra
  shl16 ra
  glo   ra
  add
  plo   ra
  irx
  ghi   ra
  adc
  phi   ra
  shl16 ra
  br    atoi_loop

atoi_negate:
  ; Check whether we need to negate the result.
  glo   rb
  bz    atoi_done

  ; Set DF=1, then subtract 0 from ra.
  smi   0
  glo   ra
  sdbi  0
  plo   ra
  ghi   ra
  sdbi  0
  phi   ra

atoi_done:
  ; Set DF=0 and return.
  adi   0
  retf

; itoa: Formats an integer into a null-terminated base-10 ASCII string.
;
; TODO: Base-16
;
; Arguments:
;   r8    Buffer address (at least 7 characters long)
;   r9    Word
;   ra.0  1 if the integer is signed, else 0.
;
; Returns:
;   r8    First address after the null terminator.
itoa:
  ; We need r8, r9, and ra for div16, so we need to shuffle a bit. Start by
  ; determining whether this is a negative value. Store a 1 in rc.0 if it is
  ; negative.
  glo   ra
  bz    itoa_sign
  ghi   r9
  ani   080h
  bz    itoa_sign

  ; It's negative. Time for two's complement.
  ghi   r9
  xri   0ffh
  phi   r9
  glo   r9
  xri   0ffh
  plo   r9
  inc   r9
  ldi   1
itoa_sign:
  plo   rc

  ; Push a null terminator to the stack.
  ldi   0
  stxd

  ; Make rb point to the buffer address, and move the word to r8 for div16.
  mov   rb, r8
  mov   r8, r9

itoa_format:
  ; Divide by 10, to get the remainder in r8, and the quotient in ra.
  mov   r9, 10
  call  div16

  ; Get the character value, and push it to the stack.
  glo   r8
  adi   '0'
  stxd

  ; Move the quotient into r8, and check whether we're done.
  mov   r8, ra
  ghi   r8
  bnz   itoa_format
  glo   r8
  bnz   itoa_format

  ; If this is a negative number, push a '-' too.
  glo   rc
  bz    itoa_pop
  ldi   '-'
  stxd

  ; Pop characters off the stack until we get to the null terminator.
itoa_pop:
  irx
  ldn   R_SP
  str   rb
  inc   rb
  bnz   itoa_pop

  retf
