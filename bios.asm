#include inc/header.asm

  org EEPROM_BASE+07d00h
#include inc/cksum.asm
#include inc/eeprom.asm

  org EEPROM_BASE+07e00h
#include inc/stack.asm
#include inc/str.asm
#include inc/rx.asm
#include inc/tx.asm
#include inc/tx_str.asm

  org EEPROM_BASE+07f00h
f_init_stack:    lbr  init_stack
f_cksum8:        lbr  cksum8
f_cksum16:       lbr  cksum16
f_write_eeprom:  lbr  write_eeprom
f_rx8:           lbr  rx8
f_rx16:          lbr  rx16
f_tx8:           lbr  tx8
f_tx16:          lbr  tx16
f_tx16_str:      lbr  tx16_str
f_strlen:        lbr  strlen

  org EEPROM_BASE+07ffch
bios_version:    db   0, 1
bios_cksum16:    db   0, 0

