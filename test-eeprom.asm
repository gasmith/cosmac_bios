#include inc/header.asm

#define STAGE1_BASE 00100h
#define IMAGE_BASE  00200h
#define IMAGE_SIZE  00046h

#define EEPROM_DEST 08000h

  lbr   stage1

; --------------------------------------
  org   STAGE1_BASE

stage1:
  ; Entrypoint
  mov   R_RA, main
  lbr   init_stack

main:
  ; Bounce the program at IMAGE_BASE to EEPROM_DEST.
  mov   r8, IMAGE_BASE
  mov   r9, EEPROM_DEST
  mov   ra, IMAGE_SIZE
  call  write_eeprom

  ; Compute the checksum, write to front panel, and idle.
  mov   r8, EEPROM_DEST
  mov   r9, IMAGE_SIZE
  call  cksum8
  glo   rf
  str   R_SP
  sex   R_SP
  out   4
  dec   R_SP
  idl

#include inc/cksum.asm
#include inc/eeprom.asm
#include inc/stack.asm

; --------------------------------------
  org   IMAGE_BASE

#include inc/blinkenlights.asm

data:
  db    "abcdefghijklmnopqrstuvwxyz"
  db    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
