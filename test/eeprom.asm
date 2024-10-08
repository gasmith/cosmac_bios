#include inc/header.asm

#define IMAGE_BASE  00130h
#define IMAGE_SIZE  00046h

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
  call  cksum8
  glo   rf
  str   R_SP
  sex   R_SP
  out   4
  dec   R_SP

  mov   r8, EEPROM_DEST
  mov   r9, IMAGE_SIZE
  call  cksum8
  glo   rf
  str   R_SP
  sex   R_SP
  out   4
  dec   R_SP

  call  EEPROM_DEST

#include inc/cksum.asm
#include inc/eeprom.asm
#include inc/stack.asm

; --------------------------------------
  org   IMAGE_BASE

#include inc/blinkenlights.asm

data:
  db    "abcdefghijklmnopqrstuvwxyz"
  db    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
