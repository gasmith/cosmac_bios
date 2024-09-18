; tx16_str: Bit-banged transmit of a null-terminated string.
;
; Arguments:
;   r8    rw  Buffer address
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
tx16_str:
  push  r8
  call  strlen
  pop   r8
  mov   ra, rf
  call  tx16
