#include inc/header.asm

#define IMAGE_BASE  00100h
#define IMAGE_SIZE  00060h

#define EEPROM_DEST 08030h

  ; Entrypoint
  mov   R_RA, main
  lbr   init_stack

; Sample program to write to eeprom.
main:
  mov   r8, IMAGE_BASE
  mov   r9, EEPROM_DEST 
  mov   ra, IMAGE_SIZE
  call  write_eeprom

  mov   r8, IMAGE_BASE
  mov   r9, IMAGE_SIZE
  call  checksum
  glo   rf
  str   R_SP
  sex   R_SP
  out   4
  dec   R_SP

  ; wait for input button
wait1:
  bn4   wait1

  mov   r8, EEPROM_DEST
  mov   r9, IMAGE_SIZE
  call  checksum
  glo   rf
  str   R_SP
  sex   R_SP
  out   4
  dec   R_SP

  ; wait for input button
wait2:
  bn4   wait2

  call  EEPROM_DEST 

#include inc/checksum.asm
#include inc/eeprom.asm
#include inc/stack.asm

; --------------------------------------
  org   IMAGE_BASE

; Blinkenlights demo.
demo:
  ldi   0
  plo   r9
  phi   r9
demo_out:
  ghi   r9
  str   R_SP
  out   4
  dec   R_SP
demo_wait:
  inc   r9
  glo   r9
  sex   R_SP
  sex   R_SP
  sex   R_SP
  sex   R_SP
  bz    demo_out
  br    demo_wait
