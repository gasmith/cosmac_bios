; cksum8: Performs an 8-bit XOR checksum.
;
; Arguments:
;   r8    rw  Address.
;   r9    rw  Length.
;
; Returns:
;   rf.0    Checksum.
cksum8:
  ; Do a 16-bit checksum.
  call  cksum16

  ; Fold the result.
  sex   R_SP
  ghi   rf
  str   R_SP
  glo   rf
  xor
  plo   rf
  retf

; cksum16: Performs a 16-bit XOR checksum.
;
; Arguments:
;   r8    rw  Address.
;   r9    rw  Length.
;
; Returns:
;   rf      Checksum.
cksum16:
  ; Initialize rf, and set x=r8.
  ldi   0
  plo   rf
  phi   rf
  sex   r8

  ; XOR into the lower bit.
cksum16_lo:
  glo   rf
  xor
  plo   rf
  irx
  dec   r9
  ghi   r9
  bnz   cksum16_hi
  glo   r9
  bz    cksum16_done

  ; XOR into the upper bit.
cksum16_hi:
  ghi   rf
  xor
  phi   rf
  irx
  dec   r9
  ghi   r9
  bnz   cksum16_lo
  glo   r9
  bnz   cksum16_lo

cksum16_done:
  retf
