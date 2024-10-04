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

; strcmp: Compare two null-terminated strings.
;
; Arguments:
;   r8, r9  String buffers.
; Returns:
;   r8, r9  Point to byte after null terminator, or first mismatch.
;   df=0    Strings are equal.
strcmp:
  sex   r8
strcmp_loop:
  ldn   r9
  xor
  bz    strcmp_next
  smi   0
  retf
strcmp_next:
  ldn   r9
  inc   r8
  inc   r9
  bnz   strcmp_loop
  adi   0
  retf

; memcmp: Compare two sized buffers.
;
; Arguments:
;   r8, r9  Buffers.
;   ra      Buffer length.
; Returns:
;   r8, r9  Point to the first unmatched byte.
;   ra      Unmatched characters.
;   df=0    Memory is equal.
memcmp:
  sex   r8
memcmp_loop:
  ldn   r9
  xor
  bz    strcmp_next
  smi   0
  retf
memcmp_next:
  inc   r8
  inc   r9
  dec   ra
  glo   ra
  bnz   strcmp_loop
  ghi   ra
  bnz   strcmp_loop
  adi   0
  retf
