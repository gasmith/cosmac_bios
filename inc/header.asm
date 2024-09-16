#ifndef _COMMON_ASM_
#define _COMMON_ASM_

; The call macro uses R_PC to read the address of the function to call.
.op "CALL","W","D4 H1 L1"
.op "RETF","","D5"

; Convenience macros for moving words around.
.op "MOV","NR","8$2 A$1 9$2 B$1"
.op "MOV","NW","F8 L2 A$1 F8 H2 B$1"

; The push & pop macros presume `X=R_SP`.
.op "PUSH","R","8$1 73 9$1 73"
.op "POP","R","60 72 B$1 F0 A$1"

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

#endif
