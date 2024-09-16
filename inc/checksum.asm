; checksum: Performs a simple single-byte XOR checksum.
;
; Arguments:
;   r8    rw  Address.
;   r9    rw  Length.
;
; Returns:
;   rf.0    Checksum.
checksum:
  ldi   0
  plo   rf
  sex   r8
checksum_loop:
  glo   rf
  xor
  plo   rf
  irx
  dec   r9
  ghi   r9
  bnz   checksum_loop
  glo   r9
  bnz   checksum_loop
  retf
