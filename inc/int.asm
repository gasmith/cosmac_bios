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
;
; Returns:
;   r8    Address of first non-numeric character
;   r9    Parsed integer
;   ra.0  1 if the integer is negative, else 0.
;   df=1  if first character is non-numeric
atoi:
  ldi   0
  plo   r9
  phi   r9

  ; If there's a leading minus sign, set ra.0=1.
  plo   ra
  ldn   r8
  xri   '-'
  bnz   atoi_check_numeric
  inc   ra
  inc   r8

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

  ; Convert to binary and add to r9.
  smi   '0'
  str   R_SP
  glo   r9
  add
  plo   r9
  ghi   r9
  adci  0
  phi   r9

  ; Check whether the next character is numeric.
  ldn   r8
  plo   rc
  call  isnum
  bnf   atoi_negate

  ; Multiply r9 by 10: Save a copy (in little-endian order), shift left twice
  ; (x4), add the saved copy (x5), shift left again (x10).
  ghi   r9
  stxd
  glo   r9
  str   R_SP
  shl16 r9
  shl16 r9
  glo   r9
  add
  plo   r9
  irx
  ghi   r9
  adc
  phi   r9
  shl16 r9
  br    atoi_loop

atoi_negate:
  ; Check whether we need to negate the result.
  glo   ra
  bz    atoi_done

  ; Set DF=1, then subtract 0 from r9.
  smi   0
  glo   r9
  sdbi  0
  plo   r9
  ghi   r9
  sdbi  0
  phi   r9

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
