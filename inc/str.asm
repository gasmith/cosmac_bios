; strlen: Returns the length of a null-terminated string.
;
; Arguments:
;   r8    rw  String address
; 
; Returns:
;   rf      Length
strlen:
  ldi   0ffh
  plo   rf
  phi   rf
  sex   r8
strlen_loop:
  ldxa
  inc   rf
  bnz   strlen_loop
strlen_done:
  retf
