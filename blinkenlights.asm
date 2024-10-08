#include inc/header.asm
#include inc/bios.asm

  mov   R_RA, demo
  lbr   f_init_stack

#include inc/blinkenlights.asm
