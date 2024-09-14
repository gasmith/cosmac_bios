; The call macro uses R_PC to read the address of the function to call.
.op "CALL","W","D4 H1 L1"
.op "RETF","","D5"

; Convenience macros for moving words around.
.op "MOV","NR","8$2 A$1 9$2 B$1"
.op "MOV","NW","F8 L2 A$1 F8 H2 B$1"

; The push & pop macros presume `sex R_SP`.
.op "PUSH","N","8$1 73 9$1 73"
.op "POP","N","60 72 B$1 F0 A$1"

; Reserved registers, from the 1802 programming guide, which recommends the use
; of registers 2-6 as part of the "Standard call and return technique" (SCRT).
; The chip is hard-coded to use r0 for DMA, and r1 for the interrupt service
; routine.
#define R_DMA     r0
#define R_ISR     r1
#define R_SP      r2
#define R_PC      r3
#define R_CALL    r4
#define R_RETF    r5
#define R_RA      r6

; RAM code page where stack is located.
#define STACK_PAGE  07fh

; EEPROM constants
#define EEPROM_BASE       08000h
#define EEPROM_PAGE_SIZE  64
#define EEPROM_PAGE_MASK  63

  ; Entrypoint
  mov   R_RA, main
  lbr   init_stack

#define IMAGE_BASE  00100h
#define IMAGE_SIZE  0008ah

; Sample program to write to eeprom.
main:
  mov   r8, IMAGE_BASE
  mov   r9, EEPROM_BASE
  mov   ra, IMAGE_SIZE
  call  write_eeprom

  mov   r8, IMAGE_BASE
  mov   r9, IMAGE_SIZE
  call  checksum
  sex   R_SP
  glo   rf
  stxd
  out   1
  irx

  mov   r8, EEPROM_BASE
  mov   r9, IMAGE_SIZE
  call  checksum
  sex   R_SP
  glo   rf
  stxd
  out   2
  irx

  idl

  org   IMAGE_BASE
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
  str   R_SP
  glo   rb
  sd        ; ra.0 - rb.0
  plo   ra

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

; init_stack: Set up stack registers and make the initial call to `R_RA`.
init_stack:
  ; Set stack pointer.
  ldi   STACK_PAGE
  phi   R_SP
  ldi   0ffh
  plo   R_SP

  ; Poison the last return address on the stack: if the main entrypoint attempts
  ; a retf, jump into an idle loop. Note that words are stored in big-endian
  ; order.
  sex   R_SP
  ldi   idle.0
  stxd
  ldi   idle.1
  stxd

  ; Set PCs for call & ret helpers.
  mov   R_CALL, call
  mov   R_RETF, retf

  ; Do the initial "return" to `start`.
  sep   R_RETF

; idle: An eternal idle loop.
idle:
  idl

; call: Function call trampoline.
;
; Invoked with `sep R_CALL, dw <addr>`, or the `call <addr>` macro. Note the
; wraparound `br call-1` to restore `R_CALL` after each invocation.
  sep   R_PC
call:
  ; Save previous return address to the stack.
  sex   R_SP
  push  R_RA

  ; Copy R_PC to R_RA.
  mov   R_RA, R_PC

  ; Load the big-endian address into R_PC, and incr R_RA as we go.
  lda   R_RA
  phi   R_PC
  lda   R_RA
  plo   R_PC

  ; Jump to new R_PC.
  br    call-1

; retf: Function return trampoline.
;
; Named `retf` to avoid confusion with the 1802 `ret` operation. Invoked with
; `sep R_RETF`, or the `retf` macro. Note the wraparound `br retf-1` to restore
; `R_RETF` after each invocation.
  sep   R_PC
retf:
  ; Copy R_RA to R_PC.
  mov   R_PC, R_RA

  ; Restore previous big-endian R_RA from the stack.
  sex   R_SP
  pop   R_RA

  ; Jump to new R_PC.
  br    retf-1
