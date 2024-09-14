; The call macro uses R_PC to read the address of the function to call.
.op "CALL","W","D4 H1 L1"
.op "RETF","","D5"

#define R_SP      r2

#define EEPROM_PAGE_SIZE  64
#define EEPROM_PAGE_MASK  63

; write_eeprom: Writes data to an AT28C EEPROM.
;
; Arguments:
;   r8    rw  Source address.
;   r9    rw  Destination address.
;   ra    rw  Length
;
write_eeprom:
  ; If there's more than 256, try to write a full page.
  ghi   ra
  bnz   write_eeprom_max

  ; If there's more than 64, try to write a full page.
  glo   ra
  smi   EEPROM_PAGE_SIZE
  bnf   write_eeprom_max

  ; If there's more than 0, write a partial page.
  glo   ra
  bnz   write_eeprom_align

  ; Nothing to write.
  retf

write_eeprom_max:
  ldi   EEPROM_PAGE_SIZE

write_eeprom_align:
  ; Copy the ideal number of bytes into rb.0.
  plo   rb

  ; Figure out whether the destination address is page-aligned.
  glo   r9
  ani   EEPROM_PAGE_MASK
  bz    write_eeprom_aligned

  ; If it is not, figure out the maximum number of bytes we can write without
  ; crossing a page boundary. Store this value on the stack.
  sdi   EEPROM_PAGE_SIZE
  sex   R_SP
  stxd

  ; Now take min(rb.0, *sp), to figure out how many bytes we can write. If rb.0
  ; is the lesser or equal, df=0 and we can proceed. Otherwise, we need to clamp
  ; rb.0 down to *sp.
  glo   rb
  sd        ; max - rb.0
  ldxa
  bnf   write_eeprom_aligned
  plo   rb

write_eeprom_aligned:
  ; Subtract the number of bytes we're writing (rb.0) from the number of bytes
  ; remaining in the buffer (ra). This is a 16-bit subtraction. Store ra.0 on
  ; the stack, subtract sb.0, store the result in ra.0, and pop the stack.
  sex   R_SP
  glo   ra
  stxd
  glo   rb
  sd        ; ra.0 - rb.0
  plo   ra
  irx

  ; If df=1, then also decrement ra.1.
  bnf   write_eeprom_call
  ghi   ra
  smi   1
  phi   ra

  ; Everything's ready to go, let's write!
write_eeprom_call:
  call  write_eeprom_page
  br    write_eeprom

; write_eeprom_page: Writes a single page to an AT28C EEPROM.
;
; Arguments:
;   r8    rw  Source address.
;   r9    rw  Destination address.
;   rb.0  rw  Length (>0, <=64)
;
; The device supports a page write of up to 64 bytes in sequence. Each
; successive byte must be written within 150us. Clocked at 4MHz, this gives
; us ~37 instructions, which is far more than we need.
;
; Writes MUST NOT span 64-byte page boundaries, which means that r9 & 0xffc0
; must equal (r9 + rb.0) & 0xffc0. The caller is responsible for making this
; guarantee.
;
; This call blocks until the write is complete. The nominal write cycle time 
; for this device is 10ms.
;
; At the end of the routine, r8 and r9 point at the next byte to be copied.
write_eeprom_page:
  ; Main loop. Read *(r8++) and write *(r9++), for rb.0 iterations.
  lda   r8
  str   r9
  inc   r9
  glo   rb
  smi   1
  plo   rb
  bnz   write_eeprom_page

  ; Seek back to the last byte in the sequence.
  dec   r8
  dec   r9

  ; Wait for the write to complete, by testing the last byte in EEPROM. It will
  ; read as the complement of the written data until the write is complete.
  sex   r9
write_eeprom_page_wait:
  ldn   r8
  xor
  bnz   write_eeprom_page_wait

  ; Restore r8 and r9 to the position of the next byte to be copied.
  inc   r8
  inc   r9
  retf
