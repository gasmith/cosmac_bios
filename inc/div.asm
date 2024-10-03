; div16: 16-bit unsigned division.
;
; Arguments:
;   r8    Dividend
;   r9    Divisor
; Returns:
;   r8    Remainder
;   ra    Quotient, or 0ffffh for divide by zero.
div16:
  ; Set ra=0
  ldi   0
  plo   ra
  phi   ra

  ; Check for divide by zero.
  glo   r9
  bnz   div16_loop
  ghi   r9
  bnz   div16_loop
  ldi   0ffh
  plo   ra
  phi   ra
  retf

div16_loop:
  ; Subtract the divisor from the dividend, incrementing ra as we go, until we
  ; overflow or reach r8=0.
  sub16 r8, r9
  bnf   div16_remain
  inc   ra
  ghi   r8
  bnz   div16_loop
  glo   r8
  bnz   div16_loop
  retf

  ; Add the divisor back to r8 to obtain the remainder.
div16_remain:
  add16 r8, r9
  retf
