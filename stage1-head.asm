; A stage1 image for writing the loader & bios to eeprom.
;
#include inc/header.asm

  lbr   stage1_init

  org   0100h
stage1_init:
  mov   R_RA, minimon
  lbr   init_stack

burn:
  push  r9
  push  ra
  call  write_eeprom
  pop   r9
  pop   r8
  call  cksum8
  glo   rf
  str   R_SP
  sex   R_SP
  out   4
  dec   R_SP
  retf

  org   01b0h
burn_bios:
  mov   r8, 00600h
  mov   r9, 0fa00h
  mov   ra, 00600h
  br    burn

  org   01d0h
burn_loader:
  mov   r8, 00500h
  mov   r9, 08000h
  mov   ra, 00025h
  br    burn

  org   01fah
  db    "stage1"

  org   0200h
#include inc/minimon.asm

  org   0300h
#include inc/cksum.asm
#include inc/eeprom.asm

  org   0400h
#include inc/rx.asm
#include inc/tx.asm
#include inc/stack.asm

  org   0500h
#define LOADER_DEST_PAGE 0
#include loader.asm

  org   0600h
