#include inc/header.asm

  mov   R_RA, minimon
  lbr   init_stack

burn:
  mov   r8, 00400h
  mov   r9, 0fa00h
  mov   ra, 00600h
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

  org 0100h
#include inc/minimon.asm

  org 0200h
#include inc/cksum.asm
#include inc/eeprom.asm

  org 0300h
#include inc/rx.asm
#include inc/tx.asm
#include inc/stack.asm
